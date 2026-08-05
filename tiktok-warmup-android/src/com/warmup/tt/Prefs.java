package com.warmup.tt;

/**
 * Tap targets are stored as fractions of screen width/height, so they survive a
 * change of device. The defaults are approximations of TikTok's feed layout — expect
 * to calibrate them once on your own phone.
 */
public final class Prefs {

    public static final String NAME = "warmup";

    public static final String DURATION = "durationMinutes";

    /**
     * Reproduce upstream's threshold handling exactly, bug included: any action fires
     * a full re-roll, so openProfile / openShop / openInbox never run. Off by default.
     */
    public static final String FAITHFUL = "faithfulMode";
    public static final boolean D_FAITHFUL = false;

    public static final String RAIL_X    = "railX";
    public static final String PROFILE_Y = "profileY";
    public static final String COMMENT_Y = "commentY";
    public static final String SAVE_Y    = "saveY";
    public static final String NAV_Y     = "navY";
    public static final String SHOP_X    = "shopX";
    public static final String INBOX_X   = "inboxX";

    /** Right-hand action rail, as a fraction of screen width. */
    public static final float D_RAIL_X    = 0.92f;
    /** Avatar, top of the rail. */
    public static final float D_PROFILE_Y = 0.33f;
    /** Comment bubble. */
    public static final float D_COMMENT_Y = 0.57f;
    /** Bookmark. */
    public static final float D_SAVE_Y    = 0.68f;
    /** Bottom navigation bar. */
    public static final float D_NAV_Y     = 0.965f;
    public static final float D_SHOP_X    = 0.30f;
    public static final float D_INBOX_X   = 0.70f;

    private Prefs() { }
}
