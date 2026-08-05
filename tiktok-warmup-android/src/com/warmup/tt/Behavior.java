package com.warmup.tt;

import java.util.Random;

/**
 * Viewing model, conditioned on whether the video is in the account's niche.
 *
 * Earlier versions drew watch time from one distribution regardless of content, which
 * is both less human and less useful. A real enthusiast skips most of the feed in a
 * second or two and watches the things they care about all the way through, twice.
 * Completion and rewatch are the strongest interest signals TikTok has - far stronger
 * than a like - so concentrating them on niche content is what actually sharpens the
 * interest graph.
 *
 * Rates below are per 100 *matched* videos. Non-matching videos are skipped and never
 * engaged with at all.
 */
public final class Behavior {

    // -- non-matching: skip fast, engage never --------------------------
    static final double NM_INSTANT = 0.85;
    static final int NM_MIN = 900,  NM_MAX = 2400;
    static final int NM_SOFT_MIN = 2800, NM_SOFT_MAX = 5200;

    // -- matching: watch properly ---------------------------------------
    static final double M_BOUNCE = 0.12;                 // didn't grab them after all
    static final int M_BOUNCE_MIN = 3000, M_BOUNCE_MAX = 6000;
    static final double M_FULL = 0.40;                   // watched to the end
    static final int M_FULL_MIN = 20000, M_FULL_MAX = 50000;
    static final double M_REWATCH = 0.45;                // and looped it
    static final double M_LN_MU = 9.55, M_LN_SIGMA = 0.42;   // median ~14s
    static final int M_MIN = 5000, M_MAX = 34000;

    /** Attention still fades across a session, just less steeply on liked content. */
    static final double DECAY_AT_END = 0.80;

    // -- dwell gates. Eligibility is measured against the *matched*
    //    distribution; see tools/behavior.js.
    public static final int GATE_LIKE   = 5000;   public static final double ELIG_LIKE   = 0.920;
    public static final int GATE_SAVE   = 12000;  public static final double ELIG_SAVE   = 0.663;
    public static final int GATE_COMM   = 4000;   public static final double ELIG_COMM   = 0.960;
    public static final int GATE_PROF   = 8000;   public static final double ELIG_PROF   = 0.812;
    public static final int GATE_REPOST = 15000;  public static final double ELIG_REPOST = 0.564;
    public static final int GATE_FOLLOW = 15000;  public static final double ELIG_FOLLOW = 0.564;

    static final double MICRO_PAUSE_P = 0.040;
    static final int MICRO_PAUSE_MIN = 8000, MICRO_PAUSE_MAX = 70000;

    /**
     * Whether a video is in the niche.
     *
     * UNKNOWN exists because "I couldn't read the caption" is not the same as "this
     * isn't your niche". Collapsing the two meant an unreadable feed produced zero
     * engagement forever, which is exactly how the app appeared dead. Unknown videos
     * get middling watch time and a fraction of the engagement rates.
     */
    public enum Match { YES, NO, UNKNOWN }

    static final double UNKNOWN_SCALE = 0.30;
    static final int UNKNOWN_MIN = 4000, UNKNOWN_MAX = 14000;

    /** Everything the level slider drives, per 100 matched videos. */
    public static final class Rates {
        public int like, save, commentOpen, commentLike, profile, repost, rewatch, follow;

        public Rates(int like, int save, int commentOpen, int commentLike,
                     int profile, int repost, int rewatch, int follow) {
            this.like = like; this.save = save; this.commentOpen = commentOpen;
            this.commentLike = commentLike; this.profile = profile;
            this.repost = repost; this.rewatch = rewatch; this.follow = follow;
        }
    }

    /**
     * Level 1-100 to rates. Exponents keep the low end fine-grained: level 12 lands on
     * the published human average, level 100 on 80 likes and 40 reposts per 100.
     */
    public static Rates ratesForLevel(int level) {
        double t = level <= 0 ? 0 : (level >= 100 ? 1.0 : level / 100.0);
        return new Rates(
                curve(t,  1, 80, 1.55),   // like
                curve(t,  0, 40, 1.85),   // save
                curve(t,  1, 60, 1.50),   // commentOpen
                curve(t,  0, 25, 1.70),   // commentLike
                curve(t,  0, 20, 1.75),   // profile
                curve(t,  0, 40, 2.40),   // repost
                curve(t,  1, 25, 1.40),   // rewatch
                curve(t,  0, 12, 2.10));  // follow
    }

    private static int curve(double t, int lo, int hi, double exp) {
        return (int) Math.round(lo + (hi - lo) * Math.pow(t, exp));
    }

    private final Random rnd = new Random();
    private final Rates rates;

    private final double pLike, pSave, pComm, pProf, pRepost, pFollow, pCommentLike, pRewatch;
    private final int gLike, gSave, gComm, gProf, gRepost, gFollow;

    private double progress = 0.0;

    public Behavior(Rates r) {
        this.rates = r;
        double[] a;
        a = resolve(r.like,   ELIG_LIKE,   GATE_LIKE);   pLike   = a[0]; gLike   = (int) a[1];
        a = resolve(r.save,   ELIG_SAVE,   GATE_SAVE);   pSave   = a[0]; gSave   = (int) a[1];
        a = resolve(r.commentOpen, ELIG_COMM, GATE_COMM);pComm   = a[0]; gComm   = (int) a[1];
        a = resolve(r.profile,ELIG_PROF,   GATE_PROF);   pProf   = a[0]; gProf   = (int) a[1];
        a = resolve(r.repost, ELIG_REPOST, GATE_REPOST); pRepost = a[0]; gRepost = (int) a[1];
        a = resolve(r.follow, ELIG_FOLLOW, GATE_FOLLOW); pFollow = a[0]; gFollow = (int) a[1];

        pRewatch = clamp(r.rewatch / 100.0);
        pCommentLike = r.commentOpen <= 0 ? 0 : clamp(r.commentLike / (double) r.commentOpen);
    }

    private static double[] resolve(int per100, double eligible, int gate) {
        double target = per100 / 100.0;
        if (target <= 0) return new double[]{ 0, gate };
        double p = target / eligible;
        if (p > 1.0) return new double[]{ clamp(target), 0 };
        return new double[]{ p, gate };
    }

    private static double clamp(double v) { return v < 0 ? 0 : (v > 1 ? 1 : v); }

    public void setProgress(double p) { progress = p < 0 ? 0 : (p > 1 ? 1 : p); }
    public Rates rates() { return rates; }

    // ------------------------------------------------------------ watch time

    public int watchTimeMs(Match m) {
        if (m == Match.YES) return matchedWatch();
        if (m == Match.NO)  return skimWatch();
        return UNKNOWN_MIN + rnd.nextInt(UNKNOWN_MAX - UNKNOWN_MIN + 1);
    }

    /** Not our niche: get past it the way a person flicks past something dull. */
    private int skimWatch() {
        if (rnd.nextDouble() < NM_INSTANT) {
            return NM_MIN + rnd.nextInt(NM_MAX - NM_MIN + 1);
        }
        return NM_SOFT_MIN + rnd.nextInt(NM_SOFT_MAX - NM_SOFT_MIN + 1);
    }

    private int matchedWatch() {
        double decay = 1.0 - (1.0 - DECAY_AT_END) * progress;
        double r = rnd.nextDouble();

        if (r < M_BOUNCE) {
            return M_BOUNCE_MIN + rnd.nextInt(M_BOUNCE_MAX - M_BOUNCE_MIN + 1);
        }
        if (r < M_BOUNCE + M_FULL) {
            int base = M_FULL_MIN + rnd.nextInt(M_FULL_MAX - M_FULL_MIN + 1);
            if (rnd.nextDouble() < M_REWATCH) {
                base = (int) (base * (1.5 + rnd.nextDouble() * 1.3));
            }
            return (int) (base * decay);
        }
        int ms = (int) (Math.exp(M_LN_MU + M_LN_SIGMA * rnd.nextGaussian()) * decay);
        if (ms < M_MIN) ms = M_MIN;
        if (ms > M_MAX) ms = M_MAX;
        return ms;
    }

    public int microPauseMs() {
        if (rnd.nextDouble() >= MICRO_PAUSE_P) return 0;
        return MICRO_PAUSE_MIN + rnd.nextInt(MICRO_PAUSE_MAX - MICRO_PAUSE_MIN + 1);
    }

    public long sessionLengthMs(int requestedMinutes) {
        return (long) (requestedMinutes * 60_000L * (0.75 + rnd.nextDouble() * 0.5));
    }

    /** Gap between automatic sessions - people come back, they don't run continuously. */
    public long gapMs() {
        return (long) ((8 + rnd.nextDouble() * 34) * 60_000L);   // 8-42 min
    }

    // ----------------------------------------------------------- engagement

    private double scale(Match m) {
        if (m == Match.YES) return 1.0;
        if (m == Match.UNKNOWN) return UNKNOWN_SCALE;
        return 0.0;
    }

    private boolean roll(int w, int gate, double p, Match m) {
        double q = p * scale(m);
        return q > 0 && w >= gate && rnd.nextDouble() < q;
    }

    public boolean shouldLike(int w, Match m)         { return roll(w, gLike,   pLike,   m); }
    public boolean shouldSave(int w, Match m)         { return roll(w, gSave,   pSave,   m); }
    public boolean shouldOpenComments(int w, Match m) { return roll(w, gComm,   pComm,   m); }
    public boolean shouldOpenProfile(int w, Match m)  { return roll(w, gProf,   pProf,   m); }
    public boolean shouldRepost(int w, Match m)       { return roll(w, gRepost, pRepost, m); }
    public boolean shouldFollow(int w, Match m)       { return roll(w, gFollow, pFollow, m); }
    public boolean shouldSwipeBack()                  { return rnd.nextDouble() < pRewatch; }
    public boolean shouldLikeComment()                { return rnd.nextDouble() < pCommentLike; }

    public int commentDwellMs(int commentCount) {
        int perComment = 900 + rnd.nextInt(1400);
        int visible = commentCount <= 0 ? 2 : Math.min(commentCount, 8);
        return Math.min(22000, 1500 + visible * perComment);
    }

    public int profileDwellMs() { return 3500 + rnd.nextInt(9000); }
    public int searchDwellMs()  { return 2500 + rnd.nextInt(4000); }
    public int reactionMs()     { return 220 + rnd.nextInt(520); }
    public int between(int min, int max) { return min + rnd.nextInt(max - min + 1); }
    public double next()        { return rnd.nextDouble(); }
}
