package com.warmup.tt;

import java.util.Random;

/**
 * Human viewing model.
 *
 * Watch time is a three-mode mixture (skip / normal / long) rather than a flat window,
 * and every engagement decision is gated on how long the video was actually watched
 * before a probability is rolled - people don't like things they skipped in two
 * seconds.
 *
 * Rates are expressed as "per 100 videos" and set by the user. The published 3.4-4%
 * engagement-by-view figure is an average across all viewers including pure lurkers,
 * so an individual active account can sit well above it; there is no single correct
 * number, which is why these are inputs rather than constants.
 */
public final class Behavior {

    // -- watch-time mixture ------------------------------------------------
    static final double SKIP_BASE   = 0.35;
    static final double SKIP_GROWTH = 0.15;
    static final double LONG_SHARE  = 0.10;

    static final int SKIP_MIN = 1200, SKIP_MAX = 3200;
    static final double LN_MU = 9.05, LN_SIGMA = 0.5;
    static final int NORMAL_MIN = 3000, NORMAL_MAX = 25000;
    static final int LONG_MIN = 18000, LONG_MAX = 45000;
    static final double REWATCH_CHANCE = 0.30;
    static final double DECAY_AT_END = 0.65;

    // -- dwell gates, and the measured share of videos that clear them -----
    // Simulated over 1,000,000 draws; see tools/behavior.js.
    public static final int GATE_LIKE = 5000;    public static final double ELIG_LIKE = 0.455;
    public static final int GATE_SAVE = 12000;   public static final double ELIG_SAVE = 0.172;
    public static final int GATE_COMM = 4000;    public static final double ELIG_COMM = 0.510;
    public static final int GATE_PROF = 8000;    public static final double ELIG_PROF = 0.291;
    public static final int GATE_REPOST = 15000; public static final double ELIG_REPOST = 0.131;

    static final double MICRO_PAUSE_P = 0.040;
    static final int MICRO_PAUSE_MIN = 8000, MICRO_PAUSE_MAX = 70000;

    /** Everything the user can dial, expressed per 100 videos watched. */
    public static final class Rates {
        public int like, save, commentOpen, commentLike, profile, repost, rewatch;

        public Rates(int like, int save, int commentOpen, int commentLike,
                     int profile, int repost, int rewatch) {
            this.like = like; this.save = save; this.commentOpen = commentOpen;
            this.commentLike = commentLike; this.profile = profile;
            this.repost = repost; this.rewatch = rewatch;
        }
    }

    private final Random rnd = new Random();
    private final Rates rates;

    private final double pLike, pSave, pComm, pProf, pRepost, pCommentLike, pRewatch;
    private final int gLike, gSave, gComm, gProf, gRepost;

    private double progress = 0.0;

    public Behavior(Rates r) {
        this.rates = r;

        double[] a = resolve(r.like,   ELIG_LIKE,   GATE_LIKE);
        pLike = a[0];   gLike = (int) a[1];
        a = resolve(r.save,        ELIG_SAVE,   GATE_SAVE);
        pSave = a[0];   gSave = (int) a[1];
        a = resolve(r.commentOpen, ELIG_COMM,   GATE_COMM);
        pComm = a[0];   gComm = (int) a[1];
        a = resolve(r.profile,     ELIG_PROF,   GATE_PROF);
        pProf = a[0];   gProf = (int) a[1];
        a = resolve(r.repost,      ELIG_REPOST, GATE_REPOST);
        pRepost = a[0]; gRepost = (int) a[1];

        pRewatch = clamp(r.rewatch / 100.0);
        // Comment likes are rolled only while the sheet is already open, so the
        // per-100-videos figure has to be divided by how often it opens at all.
        pCommentLike = r.commentOpen <= 0 ? 0
                : clamp(r.commentLike / (double) r.commentOpen);
    }

    /**
     * Turn a per-100 target into a probability. If the target exceeds the share of
     * videos that clear the dwell gate, the gate is dropped rather than silently
     * capping - the user asked for that rate, so they get it, at the cost of some
     * engagement landing on skipped videos.
     */
    private static double[] resolve(int per100, double eligible, int gate) {
        double target = per100 / 100.0;
        if (target <= 0) return new double[]{ 0, gate };
        double p = target / eligible;
        if (p > 1.0) return new double[]{ clamp(target), 0 };
        return new double[]{ p, gate };
    }

    private static double clamp(double v) { return v < 0 ? 0 : (v > 1 ? 1 : v); }

    /** Highest per-100 rate still compatible with a gate, for UI hints. */
    public static int maxWithGate(double eligible) {
        return (int) Math.floor(eligible * 100);
    }

    public void setProgress(double p) { progress = p < 0 ? 0 : (p > 1 ? 1 : p); }

    public Rates rates() { return rates; }

    /** True when a target forced its dwell gate off. */
    public boolean gateDropped(int gate, int original) { return gate == 0 && original > 0; }
    public boolean likeGateDropped()   { return gLike   == 0 && rates.like   > 0; }
    public boolean saveGateDropped()   { return gSave   == 0 && rates.save   > 0; }
    public boolean commGateDropped()   { return gComm   == 0 && rates.commentOpen > 0; }

    // ------------------------------------------------------------ watch time

    public int watchTimeMs() {
        double decay = 1.0 - (1.0 - DECAY_AT_END) * progress;
        double skipP = SKIP_BASE + SKIP_GROWTH * progress;
        double r = rnd.nextDouble();

        if (r < skipP) return SKIP_MIN + rnd.nextInt(SKIP_MAX - SKIP_MIN + 1);
        if (r < skipP + LONG_SHARE) {
            int base = LONG_MIN + rnd.nextInt(LONG_MAX - LONG_MIN + 1);
            if (rnd.nextDouble() < REWATCH_CHANCE) {
                base = (int) (base * (1.5 + rnd.nextDouble()));
            }
            return (int) (base * decay);
        }
        int ms = (int) (Math.exp(LN_MU + LN_SIGMA * rnd.nextGaussian()) * decay);
        if (ms < NORMAL_MIN) ms = NORMAL_MIN;
        if (ms > NORMAL_MAX) ms = NORMAL_MAX;
        return ms;
    }

    public int microPauseMs() {
        if (rnd.nextDouble() >= MICRO_PAUSE_P) return 0;
        return MICRO_PAUSE_MIN + rnd.nextInt(MICRO_PAUSE_MAX - MICRO_PAUSE_MIN + 1);
    }

    public long sessionLengthMs(int requestedMinutes) {
        return (long) (requestedMinutes * 60_000L * (0.75 + rnd.nextDouble() * 0.5));
    }

    // ----------------------------------------------------------- engagement

    public boolean shouldLike(int w)          { return w >= gLike && rnd.nextDouble() < pLike; }
    public boolean shouldSave(int w)          { return w >= gSave && rnd.nextDouble() < pSave; }
    public boolean shouldOpenComments(int w)  { return w >= gComm && rnd.nextDouble() < pComm; }
    public boolean shouldOpenProfile(int w)   { return w >= gProf && rnd.nextDouble() < pProf; }
    public boolean shouldRepost(int w)        { return w >= gRepost && rnd.nextDouble() < pRepost; }
    public boolean shouldSwipeBack()          { return rnd.nextDouble() < pRewatch; }
    public boolean shouldLikeComment()        { return rnd.nextDouble() < pCommentLike; }

    public int commentDwellMs(int commentCount) {
        int perComment = 900 + rnd.nextInt(1400);
        int visible = commentCount <= 0 ? 2 : Math.min(commentCount, 8);
        return Math.min(22000, 1500 + visible * perComment);
    }

    public int profileDwellMs() { return 3500 + rnd.nextInt(9000); }
    public int searchDwellMs()  { return 2500 + rnd.nextInt(4000); }
    public int reactionMs()     { return 220 + rnd.nextInt(520); }
    public int between(int min, int max) { return min + rnd.nextInt(max - min + 1); }
}
