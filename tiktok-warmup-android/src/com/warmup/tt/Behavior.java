package com.warmup.tt;

import java.util.Random;

/**
 * Human viewing model.
 *
 * Upstream picks watch time from a flat 6-9s window and fires engagement off a swipe
 * counter, independent of how long anything was watched. Both are wrong in ways that
 * are trivially visible in aggregate: the watch-time histogram is a box no person
 * produces, and likes land on skipped videos as often as watched ones.
 *
 * Real behaviour, from published benchmarks:
 *   - median watch ~8.4s, heavily right-skewed; most viewers see ~30% of a video
 *   - ~10% of views reach the end
 *   - engagement rate by view ~3.4-4%, and saves are far rarer than likes
 *   - attention decays across a session; people skip faster the longer they scroll
 *
 * So: watch time is a three-mode mixture (skip / normal / long), and every engagement
 * decision is gated on actual dwell before a probability is rolled.
 */
public final class Behavior {

    // -- watch-time mixture ------------------------------------------------
    static final double SKIP_BASE   = 0.35;  // P(instant skip) at session start
    static final double SKIP_GROWTH = 0.15;  // added linearly by session end
    static final double LONG_SHARE  = 0.10;  // P(watch to completion)

    static final int SKIP_MIN = 1200, SKIP_MAX = 3200;
    static final double LN_MU = 9.05, LN_SIGMA = 0.5;   // median ~8.5s
    static final int NORMAL_MIN = 3000, NORMAL_MAX = 25000;
    static final int LONG_MIN = 18000, LONG_MAX = 45000;
    static final double REWATCH_CHANCE = 0.30;

    /** Watch times shrink toward the end of a session as attention fades. */
    static final double DECAY_AT_END = 0.65;

    // -- engagement: {minimum dwell ms, P(fire | eligible)} ----------------
    static final int    LIKE_MIN_MS = 5000;   static final double LIKE_P     = 0.082;
    static final int    SAVE_MIN_MS = 12000;  static final double SAVE_P     = 0.030;
    static final int    COMM_MIN_MS = 4000;   static final double COMM_P     = 0.123;
    static final int    PROF_MIN_MS = 8000;   static final double PROF_P     = 0.043;
    static final int    REPOST_MIN_MS = 15000; static final double REPOST_P  = 0.013;

    static final double BACK_P        = 0.030;  // re-watch the previous video
    static final double LIKE_COMMENT_P = 0.25;  // given the comment sheet is open
    static final double MICRO_PAUSE_P  = 0.040;
    static final int MICRO_PAUSE_MIN = 8000, MICRO_PAUSE_MAX = 70000;

    /** Multiplies every engagement probability. */
    static double presetScale(int preset) {
        if (preset == Prefs.PRESET_LIGHT) return 0.55;
        if (preset == Prefs.PRESET_HEAVY) return 1.80;
        return 1.0;
    }

    private final Random rnd = new Random();
    private final double scale;

    /** 0.0 at session start, 1.0 at the scheduled end. */
    private double progress = 0.0;

    public Behavior(int preset) {
        this.scale = presetScale(preset);
    }

    public void setProgress(double p) {
        progress = p < 0 ? 0 : (p > 1 ? 1 : p);
    }

    // ------------------------------------------------------------ watch time

    /** How long to sit on this video before swiping. */
    public int watchTimeMs() {
        double decay = 1.0 - (1.0 - DECAY_AT_END) * progress;
        double skipP = SKIP_BASE + SKIP_GROWTH * progress;
        double r = rnd.nextDouble();

        if (r < skipP) {
            return SKIP_MIN + rnd.nextInt(SKIP_MAX - SKIP_MIN + 1);
        }
        if (r < skipP + LONG_SHARE) {
            int base = LONG_MIN + rnd.nextInt(LONG_MAX - LONG_MIN + 1);
            if (rnd.nextDouble() < REWATCH_CHANCE) {
                base = (int) (base * (1.5 + rnd.nextDouble()));   // looped 2-3x
            }
            return (int) (base * decay);
        }
        double v = Math.exp(LN_MU + LN_SIGMA * rnd.nextGaussian());
        int ms = (int) (v * decay);
        if (ms < NORMAL_MIN) ms = NORMAL_MIN;
        if (ms > NORMAL_MAX) ms = NORMAL_MAX;
        return ms;
    }

    /** Occasional "put the phone down" gap. 0 when there isn't one. */
    public int microPauseMs() {
        if (rnd.nextDouble() >= MICRO_PAUSE_P) return 0;
        return MICRO_PAUSE_MIN + rnd.nextInt(MICRO_PAUSE_MAX - MICRO_PAUSE_MIN + 1);
    }

    /** Real sessions don't end on a round number. */
    public long sessionLengthMs(int requestedMinutes) {
        double jitter = 0.75 + rnd.nextDouble() * 0.5;      // 0.75x - 1.25x
        return (long) (requestedMinutes * 60_000L * jitter);
    }

    // ----------------------------------------------------------- engagement

    private boolean roll(double p) {
        double q = p * scale;
        return rnd.nextDouble() < (q > 1.0 ? 1.0 : q);
    }

    public boolean shouldLike(int watchedMs) {
        return watchedMs >= LIKE_MIN_MS && roll(LIKE_P);
    }

    public boolean shouldSave(int watchedMs) {
        return watchedMs >= SAVE_MIN_MS && roll(SAVE_P);
    }

    public boolean shouldOpenComments(int watchedMs) {
        return watchedMs >= COMM_MIN_MS && roll(COMM_P);
    }

    public boolean shouldOpenProfile(int watchedMs) {
        return watchedMs >= PROF_MIN_MS && roll(PROF_P);
    }

    public boolean shouldRepost(int watchedMs) {
        return watchedMs >= REPOST_MIN_MS && roll(REPOST_P);
    }

    public boolean shouldSwipeBack() { return roll(BACK_P); }

    public boolean shouldLikeComment() { return rnd.nextDouble() < LIKE_COMMENT_P; }

    /** Dwell in the comment sheet, scaled by how much there is to read. */
    public int commentDwellMs(int commentCount) {
        int perComment = 900 + rnd.nextInt(1400);
        int visible = commentCount <= 0 ? 2 : (commentCount > 8 ? 8 : commentCount);
        int ms = 1500 + visible * perComment;
        return ms > 22000 ? 22000 : ms;
    }

    public int profileDwellMs() { return 3500 + rnd.nextInt(9000); }

    public int searchDwellMs()  { return 2500 + rnd.nextInt(4000); }

    /** Small human hesitation before acting on something. */
    public int reactionMs() { return 220 + rnd.nextInt(520); }

    public int between(int min, int max) { return min + rnd.nextInt(max - min + 1); }

    public double next() { return rnd.nextDouble(); }
}
