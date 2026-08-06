package com.warmup.tt;

import android.content.Context;
import android.content.SharedPreferences;

/** Single place for every stored setting, with typed accessors. */
public final class Prefs {

    public static final String NAME = "warmup";

    // -- session ----------------------------------------------------------
    public static final String DURATION = "durationMinutes";
    public static final String LEVEL    = "boostLevel";      // 1-100
    public static final String CUSTOM   = "ratesCustom";     // slider overridden?
    public static final String AUTO     = "autoMode";
    public static final String TARGET   = "nicheTarget";   // % of feed wanted
    public static final String GAP_MIN  = "gapMinMinutes";
    public static final String GAP_MAX  = "gapMaxMinutes";

    // -- rates, per 100 matched videos ------------------------------------
    public static final String R_LIKE    = "rateLike";
    public static final String R_SAVE    = "rateSave";
    public static final String R_COMMENT = "rateCommentOpen";
    public static final String R_CLIKE   = "rateCommentLike";
    public static final String R_PROFILE = "rateProfile";
    public static final String R_REPOST  = "rateRepost";
    public static final String R_REWATCH = "rateRewatch";
    public static final String R_FOLLOW  = "rateFollow";

    public static final String[] RATE_KEYS = {
        R_LIKE, R_SAVE, R_COMMENT, R_CLIKE, R_PROFILE, R_REPOST, R_REWATCH, R_FOLLOW
    };

    // -- features ---------------------------------------------------------
    public static final String NICHE_TERMS   = "nicheTerms";
    public static final String NICHE_ENABLED = "nicheEnabled";
    public static final String OVERLAY       = "overlayEnabled";
    public static final String RESEARCH      = "researchEnabled";
    public static final String SELF_STATS    = "selfStatsEnabled";
    public static final String REPOST        = "repostEnabled";
    public static final String FOLLOW        = "followEnabled";
    public static final String LIKE_COMMENTS = "likeCommentsEnabled";

    public static final int DEFAULT_LEVEL = 35;

    public static final String DEFAULT_NICHE =
            "Miniature ASMR Vehicle Assembly\nminiature assembly\ndiecast build\n"
            + "model kit asmr\n1/18 scale build\nscale model\ndiorama";

    private final SharedPreferences sp;

    public Prefs(Context ctx) {
        this.sp = ctx.getSharedPreferences(NAME, Context.MODE_PRIVATE);
    }

    public int     duration()      { return sp.getInt(DURATION, 25); }
    public int     level()         { return sp.getInt(LEVEL, DEFAULT_LEVEL); }
    public boolean custom()        { return sp.getBoolean(CUSTOM, false); }
    public boolean autoMode()      { return sp.getBoolean(AUTO, true); }
    public int     nicheTarget()   { return sp.getInt(TARGET, 70); }
    public int     gapMin()        { return sp.getInt(GAP_MIN, 8); }
    public int     gapMax()        { return sp.getInt(GAP_MAX, 42); }
    public boolean nicheEnabled()  { return sp.getBoolean(NICHE_ENABLED, true); }
    public boolean overlay()       { return sp.getBoolean(OVERLAY, true); }
    public boolean research()      { return sp.getBoolean(RESEARCH, true); }
    public boolean selfStats()     { return sp.getBoolean(SELF_STATS, true); }
    public boolean repostEnabled() { return sp.getBoolean(REPOST, false); }
    public boolean followEnabled() { return sp.getBoolean(FOLLOW, true); }
    public boolean likeComments()  { return sp.getBoolean(LIKE_COMMENTS, true); }

    /**
     * Rates come from the level slider unless individual numbers were edited, in
     * which case the stored values win and the UI shows "Custom".
     */
    public Behavior.Rates rates() {
        Behavior.Rates fromLevel = Behavior.ratesForLevel(level());
        if (!custom()) return fromLevel;
        int[] d = asArray(fromLevel);
        return new Behavior.Rates(
                sp.getInt(R_LIKE,    d[0]), sp.getInt(R_SAVE,    d[1]),
                sp.getInt(R_COMMENT, d[2]), sp.getInt(R_CLIKE,   d[3]),
                sp.getInt(R_PROFILE, d[4]), sp.getInt(R_REPOST,  d[5]),
                sp.getInt(R_REWATCH, d[6]), sp.getInt(R_FOLLOW,  d[7]));
    }

    public static int[] asArray(Behavior.Rates r) {
        return new int[]{ r.like, r.save, r.commentOpen, r.commentLike,
                          r.profile, r.repost, r.rewatch, r.follow };
    }

    /** Move the slider: rewrite every rate and drop the custom flag. */
    public void applyLevel(int level) {
        int[] v = asArray(Behavior.ratesForLevel(level));
        SharedPreferences.Editor ed = sp.edit();
        ed.putInt(LEVEL, level).putBoolean(CUSTOM, false);
        for (int i = 0; i < RATE_KEYS.length; i++) ed.putInt(RATE_KEYS[i], v[i]);
        ed.apply();
    }

    /** Reads one rate, defaulting to whatever the current level implies. */
    public int rate(String key) {
        int[] d = asArray(Behavior.ratesForLevel(level()));
        for (int i = 0; i < RATE_KEYS.length; i++) {
            if (RATE_KEYS[i].equals(key)) return sp.getInt(key, d[i]);
        }
        return sp.getInt(key, 0);
    }

    public String nicheRaw() { return sp.getString(NICHE_TERMS, DEFAULT_NICHE); }

    /** Search terms, one per line, blanks dropped. */
    public String[] nicheTerms() {
        String[] raw = nicheRaw().split("\n");
        int n = 0;
        for (String s : raw) if (s.trim().length() > 0) n++;
        String[] out = new String[n];
        int i = 0;
        for (String s : raw) if (s.trim().length() > 0) out[i++] = s.trim();
        return out;
    }

    public SharedPreferences.Editor edit() { return sp.edit(); }
    public SharedPreferences raw()         { return sp; }
}
