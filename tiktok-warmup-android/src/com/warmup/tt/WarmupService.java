package com.warmup.tt;

import android.accessibilityservice.AccessibilityService;
import android.accessibilityservice.GestureDescription;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Path;
import android.os.Handler;
import android.os.Looper;
import android.util.DisplayMetrics;
import android.view.WindowManager;
import android.view.accessibility.AccessibilityEvent;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Random;

/**
 * Port of l-portet/tiktok-warmup-bot's scheduler.
 *
 * The original drives an iPhone by playing MP3s at iOS Voice Control. This does the
 * same thing natively: same action table, same intervals, same pause formula, but the
 * gestures go straight through AccessibilityService.dispatchGesture().
 */
public class WarmupService extends AccessibilityService {

    public static volatile WarmupService instance;

    /** {durationMs, minInterval, maxInterval} — verbatim from index.js VOICE_ACTIONS. */
    static final Map<String, int[]> ACTIONS = new LinkedHashMap<String, int[]>();

    /** Insertion order matters: index.js fires only the first threshold that matches. */
    static final String[] ORDER = {
        "swipePrevious", "likePost", "savePost", "openComments",
        "openProfile", "openShop", "openInbox"
    };

    static {
        ACTIONS.put("swipeNext",     new int[]{ 5000,  0,  0});
        ACTIONS.put("swipePrevious", new int[]{ 5000,  4,  7});
        ACTIONS.put("likePost",      new int[]{ 1500,  4,  7});
        ACTIONS.put("savePost",      new int[]{ 5000,  4,  7});
        ACTIONS.put("openComments",  new int[]{ 7000,  4,  7});
        ACTIONS.put("openProfile",   new int[]{ 7000, 10, 15});
        ACTIONS.put("openShop",      new int[]{15000, 30, 35});
        ACTIONS.put("openInbox",     new int[]{15000, 30, 35});
    }

    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Random rnd = new Random();
    private final Map<String, Integer> thresholds = new LinkedHashMap<String, Integer>();
    private final Map<String, Integer> stats = new LinkedHashMap<String, Integer>();

    private boolean running = false;
    private long endTime = 0L;
    private int swipeCount = 0;
    private String lastAction = "-";

    private int screenW = 1080;
    private int screenH = 2400;

    @Override
    protected void onServiceConnected() {
        super.onServiceConnected();
        instance = this;
        measureScreen();
    }

    @Override
    public boolean onUnbind(android.content.Intent intent) {
        stopSession();
        instance = null;
        return super.onUnbind(intent);
    }

    @Override
    public void onDestroy() {
        stopSession();
        instance = null;
        super.onDestroy();
    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) { }

    @Override
    public void onInterrupt() { }

    private void measureScreen() {
        try {
            WindowManager wm = (WindowManager) getSystemService(Context.WINDOW_SERVICE);
            DisplayMetrics dm = new DisplayMetrics();
            wm.getDefaultDisplay().getRealMetrics(dm);
            screenW = dm.widthPixels;
            screenH = dm.heightPixels;
        } catch (Throwable ignored) { }
    }

    // ---------------------------------------------------------------- session

    public void startSession(int minutes, int startDelaySeconds) {
        measureScreen();
        running = true;
        swipeCount = 0;
        stats.clear();
        regenerateThresholds();
        long delayMs = startDelaySeconds * 1000L;
        endTime = System.currentTimeMillis() + delayMs + minutes * 60_000L;
        handler.postDelayed(new Runnable() {
            @Override public void run() { step(); }
        }, delayMs);
    }

    public void stopSession() {
        running = false;
        handler.removeCallbacksAndMessages(null);
    }

    public boolean isRunning() { return running; }
    public int getSwipeCount() { return swipeCount; }
    public String getLastAction() { return lastAction; }

    public long getRemainingMs() {
        long r = endTime - System.currentTimeMillis();
        return r > 0 ? r : 0;
    }

    public String getStatsLine() {
        if (stats.isEmpty()) return "no actions yet";
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<String, Integer> e : stats.entrySet()) {
            if (sb.length() > 0) sb.append("  ");
            sb.append(e.getKey()).append(" ").append(e.getValue());
        }
        return sb.toString();
    }

    // --------------------------------------------------------------- schedule

    private int rand(int min, int max) {
        return rnd.nextInt(max - min + 1) + min;
    }

    /** Mirrors generateThresholds(): every interval action re-rolls off the current count. */
    private void regenerateThresholds() {
        thresholds.clear();
        for (String key : ORDER) {
            int[] a = ACTIONS.get(key);
            thresholds.put(key, swipeCount + rand(a[1], a[2]));
        }
    }

    /** Re-roll a single action, leaving the others' progress intact. */
    private void regenerateOne(String key) {
        int[] a = ACTIONS.get(key);
        thresholds.put(key, swipeCount + rand(a[1], a[2]));
    }

    /**
     * Mirrors the runWarmup() while-loop, one iteration per callback.
     *
     * Upstream re-rolls *every* threshold whenever any action fires, and matches on
     * exact equality. Because four actions sit at interval 4-7, one of them always
     * fires first and resets the counters, so openProfile (10-15), openShop and
     * openInbox (30-35) can never be reached — they are dead in the original. Faithful
     * mode reproduces that verbatim; otherwise only the fired action is re-rolled and
     * matching is >=, which is what the interval table evidently intends.
     */
    private void step() {
        if (!running) return;
        if (System.currentTimeMillis() >= endTime) {
            stopSession();
            return;
        }

        swipeCount++;
        perform("swipeNext", new Runnable() {
            @Override public void run() {
                if (!running) return;

                final boolean faithful = prefBool(Prefs.FAITHFUL, Prefs.D_FAITHFUL);

                String found = null;
                for (String key : ORDER) {
                    Integer t = thresholds.get(key);
                    if (t == null) continue;
                    boolean hit = faithful ? (t.intValue() == swipeCount)
                                           : (t.intValue() <= swipeCount);
                    if (hit) { found = key; break; }
                }

                if (found == null) {
                    step();
                    return;
                }

                final String fired = found;
                perform(fired, new Runnable() {
                    @Override public void run() {
                        if (faithful) regenerateThresholds();
                        else regenerateOne(fired);
                        step();
                    }
                });
            }
        });
    }

    /** Mirrors perform(): dispatch, then wait duration + random(1000,4000). */
    private void perform(String key, final Runnable done) {
        int[] a = ACTIONS.get(key);
        lastAction = key;
        Integer prev = stats.get(key);
        stats.put(key, (prev == null ? 0 : prev) + 1);

        dispatchFor(key, a[0]);

        long wait = a[0] + rand(1000, 4000);
        handler.postDelayed(new Runnable() {
            @Override public void run() { if (running) done.run(); }
        }, wait);
    }

    // --------------------------------------------------------------- gestures

    private void dispatchFor(String key, int durationMs) {
        if ("swipeNext".equals(key))          { swipe(true); }
        else if ("swipePrevious".equals(key)) { swipe(false); }
        else if ("likePost".equals(key))      { doubleTapCentre(); }
        else if ("savePost".equals(key))      { tapFrac(railX(), saveY()); }
        else if ("openComments".equals(key))  { tapFrac(railX(), commentY()); back(durationMs - 1500); }
        else if ("openProfile".equals(key))   { tapFrac(railX(), profileY()); back(durationMs - 1500); }
        else if ("openShop".equals(key))      { tapFrac(shopX(), navY());    back(durationMs - 2000); }
        else if ("openInbox".equals(key))     { tapFrac(inboxX(), navY());   back(durationMs - 2000); }
    }

    /** Return to the feed before the pause elapses, so the next swipe starts from a known state. */
    private void back(int delayMs) {
        final int d = delayMs < 800 ? 800 : delayMs;
        handler.postDelayed(new Runnable() {
            @Override public void run() {
                if (running) performGlobalAction(GLOBAL_ACTION_BACK);
            }
        }, d);
    }

    private float jitter(float span) {
        return (rnd.nextFloat() - 0.5f) * span;
    }

    private void swipe(boolean up) {
        float cx = screenW * 0.5f + jitter(screenW * 0.12f);
        float y1 = screenH * (up ? 0.72f : 0.30f) + jitter(screenH * 0.04f);
        float y2 = screenH * (up ? 0.28f : 0.74f) + jitter(screenH * 0.04f);

        Path p = new Path();
        p.moveTo(cx, y1);
        // Slight arc rather than a ruler-straight line.
        p.quadTo(cx + jitter(screenW * 0.10f), (y1 + y2) / 2f,
                 cx + jitter(screenW * 0.05f), y2);

        dispatch(p, 160 + rnd.nextInt(180));
    }

    private void tapFrac(float fx, float fy) {
        tap(screenW * fx + jitter(screenW * 0.015f),
            screenH * fy + jitter(screenH * 0.008f));
    }

    private void tap(float x, float y) {
        Path p = new Path();
        p.moveTo(x, y);
        p.lineTo(x + 1f, y + 1f);
        dispatch(p, 50 + rnd.nextInt(50));
    }

    private void doubleTapCentre() {
        final float x = screenW * 0.5f + jitter(screenW * 0.10f);
        final float y = screenH * 0.45f + jitter(screenH * 0.08f);
        tap(x, y);
        handler.postDelayed(new Runnable() {
            @Override public void run() {
                if (running) tap(x + jitter(20f), y + jitter(20f));
            }
        }, 90 + rnd.nextInt(70));
    }

    private void dispatch(Path path, int durationMs) {
        try {
            GestureDescription.Builder b = new GestureDescription.Builder();
            b.addStroke(new GestureDescription.StrokeDescription(path, 0L, durationMs));
            dispatchGesture(b.build(), null, null);
        } catch (Throwable ignored) { }
    }

    // ------------------------------------------------------ tunable positions

    private float pref(String key, float def) {
        SharedPreferences sp = getSharedPreferences(Prefs.NAME, Context.MODE_PRIVATE);
        return sp.getFloat(key, def);
    }

    private boolean prefBool(String key, boolean def) {
        SharedPreferences sp = getSharedPreferences(Prefs.NAME, Context.MODE_PRIVATE);
        return sp.getBoolean(key, def);
    }

    private float railX()    { return pref(Prefs.RAIL_X,    Prefs.D_RAIL_X); }
    private float profileY() { return pref(Prefs.PROFILE_Y, Prefs.D_PROFILE_Y); }
    private float commentY() { return pref(Prefs.COMMENT_Y, Prefs.D_COMMENT_Y); }
    private float saveY()    { return pref(Prefs.SAVE_Y,    Prefs.D_SAVE_Y); }
    private float navY()     { return pref(Prefs.NAV_Y,     Prefs.D_NAV_Y); }
    private float shopX()    { return pref(Prefs.SHOP_X,    Prefs.D_SHOP_X); }
    private float inboxX()   { return pref(Prefs.INBOX_X,   Prefs.D_INBOX_X); }
}
