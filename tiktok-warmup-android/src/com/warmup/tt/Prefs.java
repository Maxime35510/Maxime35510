package com.warmup.tt;

import android.content.Context;
import android.content.SharedPreferences;

/** Single place for every stored setting, with typed accessors. */
public final class Prefs {

    public static final String NAME = "warmup";

    // -- session ----------------------------------------------------------
    public static final String DURATION      = "durationMinutes";
    public static final String PRESET        = "preset";           // 0 light, 1 normal, 2 heavy
    public static final String SCHEDULER     = "schedulerMode";    // 0 human, 1 upstream
    public static final String DRY_RUN       = "dryRun";

    // -- features ---------------------------------------------------------
    public static final String NICHE_TERMS   = "nicheTerms";
    public static final String NICHE_ENABLED = "nicheEnabled";
    public static final String OVERLAY       = "overlayEnabled";
    public static final String RESEARCH      = "researchEnabled";
    public static final String REPOST        = "repostEnabled";
    public static final String LIKE_COMMENTS = "likeCommentsEnabled";

    // -- last-resort tap fractions (only used if the node tree yields nothing)
    public static final String RAIL_X    = "railX";
    public static final String PROFILE_Y = "profileY";
    public static final String COMMENT_Y = "commentY";
    public static final String SAVE_Y    = "saveY";
    public static final String NAV_Y     = "navY";

    public static final float D_RAIL_X    = 0.92f;
    public static final float D_PROFILE_Y = 0.33f;
    public static final float D_COMMENT_Y = 0.57f;
    public static final float D_SAVE_Y    = 0.68f;
    public static final float D_NAV_Y     = 0.965f;

    public static final int PRESET_LIGHT  = 0;
    public static final int PRESET_NORMAL = 1;
    public static final int PRESET_HEAVY  = 2;

    public static final int MODE_HUMAN    = 0;
    public static final int MODE_UPSTREAM = 1;

    public static final String DEFAULT_NICHE = "Miniature ASMR Vehicle Assembly";

    private final SharedPreferences sp;

    public Prefs(Context ctx) {
        this.sp = ctx.getSharedPreferences(NAME, Context.MODE_PRIVATE);
    }

    public int     duration()      { return sp.getInt(DURATION, 30); }
    public int     preset()        { return sp.getInt(PRESET, PRESET_NORMAL); }
    public int     scheduler()     { return sp.getInt(SCHEDULER, MODE_HUMAN); }
    public boolean dryRun()        { return sp.getBoolean(DRY_RUN, false); }
    public boolean nicheEnabled()  { return sp.getBoolean(NICHE_ENABLED, true); }
    public boolean overlay()       { return sp.getBoolean(OVERLAY, true); }
    public boolean research()      { return sp.getBoolean(RESEARCH, true); }
    public boolean repost()        { return sp.getBoolean(REPOST, false); }
    public boolean likeComments()  { return sp.getBoolean(LIKE_COMMENTS, true); }

    public float railX()    { return sp.getFloat(RAIL_X,    D_RAIL_X); }
    public float profileY() { return sp.getFloat(PROFILE_Y, D_PROFILE_Y); }
    public float commentY() { return sp.getFloat(COMMENT_Y, D_COMMENT_Y); }
    public float saveY()    { return sp.getFloat(SAVE_Y,    D_SAVE_Y); }
    public float navY()     { return sp.getFloat(NAV_Y,     D_NAV_Y); }

    public String nicheRaw() {
        return sp.getString(NICHE_TERMS, DEFAULT_NICHE
                + "\nminiature assembly\ndiecast build\nmodel kit asmr\n1/18 scale build");
    }

    /** Niche search terms, one per line, blanks dropped. */
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
