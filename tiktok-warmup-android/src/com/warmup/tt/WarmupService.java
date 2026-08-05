package com.warmup.tt;

import android.accessibilityservice.AccessibilityService;
import android.accessibilityservice.GestureDescription;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.graphics.Path;
import android.os.BatteryManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.DisplayMetrics;
import android.view.WindowManager;
import android.view.accessibility.AccessibilityEvent;
import android.view.accessibility.AccessibilityNodeInfo;

import java.util.Random;

/**
 * Session orchestrator.
 *
 * Every cycle reads the screen first, decides second, acts third. Nothing is tapped
 * without knowing what is under it, and the session pauses rather than dispatching
 * gestures into whatever app happens to be in front.
 */
public class WarmupService extends AccessibilityService implements OverlayController.OnStop {

    public static volatile WarmupService instance;

    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Random rnd = new Random();

    private Prefs prefs;
    private Behavior behavior;
    private ResearchLog research;
    private OverlayController overlay;

    private boolean running = false;
    private boolean paused = false;
    private long startTime, endTime;
    private int videoCount = 0;
    private int recoveries = 0;
    private int unknownScreens = 0;
    private int pausedCycles = 0;
    private boolean backUnsafe = false;
    private int sinceSearch = 0;
    private int nextSearchAt = 0;
    private String lastAction = "-";

    private int screenW = 1080, screenH = 2400;

    // ------------------------------------------------------------ lifecycle

    @Override
    protected void onServiceConnected() {
        super.onServiceConnected();
        instance = this;
        prefs = new Prefs(this);
        research = new ResearchLog(this);
        measureScreen();
    }

    @Override
    public boolean onUnbind(Intent intent) {
        stopSession("service unbound");
        instance = null;
        return super.onUnbind(intent);
    }

    @Override
    public void onDestroy() {
        stopSession("service destroyed");
        instance = null;
        super.onDestroy();
    }

    @Override public void onAccessibilityEvent(AccessibilityEvent e) { }
    @Override public void onInterrupt() { }

    private void measureScreen() {
        try {
            WindowManager wm = (WindowManager) getSystemService(Context.WINDOW_SERVICE);
            DisplayMetrics dm = new DisplayMetrics();
            wm.getDefaultDisplay().getRealMetrics(dm);
            screenW = dm.widthPixels;
            screenH = dm.heightPixels;
        } catch (Throwable ignored) { }
    }

    // -------------------------------------------------------------- session

    public void startSession(int minutes, int startDelaySeconds) {
        measureScreen();
        prefs = new Prefs(this);
        behavior = new Behavior(prefs.preset());
        research = new ResearchLog(this);

        ActionLog.reset();
        running = true;
        paused = false;
        videoCount = 0;
        recoveries = 0;
        unknownScreens = 0;
        pausedCycles = 0;
        backUnsafe = false;
        sinceSearch = 0;
        nextSearchAt = prefs.nicheEnabled() ? behavior.between(2, 6) : Integer.MAX_VALUE;

        long delay = startDelaySeconds * 1000L;
        long length = behavior.sessionLengthMs(minutes);
        startTime = System.currentTimeMillis() + delay;
        endTime = startTime + length;

        ActionLog.add("session", "start, ~" + (length / 60000) + "m"
                + (prefs.dryRun() ? " (DRY RUN)" : ""), false);

        if (prefs.overlay()) {
            if (overlay == null) overlay = new OverlayController(this, this);
            overlay.show();
        }
        Notifications.show(this, "Warmup running",
                prefs.dryRun() ? "Dry run - nothing will be tapped" : "Starting...");

        if (!prefs.dryRun()) {
            if (launchTikTok()) {
                ActionLog.add("launch", "opening TikTok", false);
            } else {
                ActionLog.add("launch", "TikTok not installed?", true);
            }
        }

        handler.postDelayed(new Runnable() {
            @Override public void run() { loop(); }
        }, delay);
    }

    public void stopSession(String reason) {
        if (running) ActionLog.add("session", "stopped (" + reason + ")", false);
        running = false;
        paused = false;
        handler.removeCallbacksAndMessages(null);
        if (overlay != null) overlay.hide();
        Notifications.clear(this);
    }

    @Override public void stop() { stopSession("overlay"); }

    public boolean isRunning()     { return running; }
    public boolean isPaused()      { return paused; }
    public int     videoCount()    { return videoCount; }
    public String  lastAction()    { return lastAction; }
    public boolean dryRun()        { return prefs != null && prefs.dryRun(); }

    public long remainingMs() {
        long r = endTime - System.currentTimeMillis();
        return r > 0 ? r : 0;
    }

    private double progress() {
        long total = endTime - startTime;
        if (total <= 0) return 1.0;
        double p = (System.currentTimeMillis() - startTime) / (double) total;
        return p < 0 ? 0 : (p > 1 ? 1 : p);
    }

    private void tick(String state) {
        lastAction = state;
        if (overlay != null && overlay.isShown()) {
            long s = remainingMs() / 1000;
            overlay.update(paused ? "PAUSED" : (s / 60) + ":" + String.format("%02d", s % 60),
                    paused);
        }
        Notifications.show(this, paused ? "Warmup paused" : "Warmup running",
                "video " + videoCount + "  -  " + state);
    }

    private void later(long ms, Runnable r) {
        final Runnable rr = r;
        handler.postDelayed(new Runnable() {
            @Override public void run() { if (running) rr.run(); }
        }, ms);
    }

    // ----------------------------------------------------------- main cycle

    private void loop() {
        if (!running) return;
        if (System.currentTimeMillis() >= endTime) {
            stopSession("session complete");
            return;
        }
        behavior.setProgress(progress());

        if (batteryLow()) {
            stopSession("battery below 15%");
            return;
        }

        final ScreenState st = ScreenState.capture(this, screenW, screenH);

        if (!st.isTikTok()) {
            if (!paused) {
                paused = true;
                pausedCycles = 0;
                ActionLog.add("paused", "TikTok not in foreground (" + shortPkg(st.pkg) + ")",
                        false);
            }
            pausedCycles++;
            // Don't sit waiting for a human to switch back - bring it forward.
            if (pausedCycles == 2 || pausedCycles % 8 == 0) {
                if (launchTikTok()) ActionLog.add("launch", "reopening TikTok", false);
            }
            tick("reopening TikTok");
            later(3000, new Runnable() { @Override public void run() { loop(); } });
            return;
        }
        if (paused) {
            paused = false;
            pausedCycles = 0;
            ActionLog.add("resumed", "TikTok is back", false);
        }

        if (st.screen == ScreenState.Screen.OTHER_TIKTOK) {
            unknownScreens++;
            if (unknownScreens <= 3) {
                ActionLog.add("unknown", "screen not recognised, waiting", false);
                tick("waiting");
                later(1500, new Runnable() { @Override public void run() { loop(); } });
                return;
            }
            // Give up identifying it and carry on. Swiping on the wrong screen is
            // recoverable; pressing BACK until the app exits is not.
            ActionLog.add("unknown", "assuming feed, continuing", false);
            unknownScreens = 0;
        } else if (st.screen != ScreenState.Screen.FEED) {
            recoverToFeed(st, 0);
            return;
        } else {
            unknownScreens = 0;
        }
        recoveries = 0;

        if (sinceSearch >= nextSearchAt && prefs.nicheEnabled()) {
            sinceSearch = 0;
            nextSearchAt = behavior.between(18, 40);
            nicheSearch();
            return;
        }

        watchVideo(st);
    }

    private static String shortPkg(String p) {
        if (p == null || p.length() == 0) return "unknown";
        int i = p.lastIndexOf('.');
        return i > 0 ? p.substring(i + 1) : p;
    }

    /**
     * Get back to the feed from wherever we ended up. A single BACK is not enough:
     * with the keyboard up it only closes the keyboard, which is exactly how the
     * previous build ended up scrolling a comment list while believing it was on the
     * feed.
     */
    private void recoverToFeed(ScreenState st, final int attempt) {
        if (!running) return;

        // Only ever back out of something that is genuinely stacked on top of the
        // feed. Anything else and we leave the app.
        if (!st.isDismissable() || backUnsafe) {
            ActionLog.add("recover", "not backing out of " + st.screen
                    + (backUnsafe ? " (back disabled)" : ""), true);
            later(1500, new Runnable() { @Override public void run() { loop(); } });
            return;
        }

        if (attempt >= 4) {
            ActionLog.add("recover", "gave up after 4 attempts, on " + st.screen, false);
            recoveries++;
            if (recoveries >= 3) {
                stopSession("cannot reach the feed");
                return;
            }
            later(2000, new Runnable() { @Override public void run() { loop(); } });
            return;
        }

        ActionLog.add("recover", "on " + st.screen
                + (st.keyboardOpen ? " + keyboard" : "") + ", pressing back", prefs.dryRun());
        tick("recovering");
        back();

        later(behavior.between(700, 1300), new Runnable() {
            @Override public void run() {
                ScreenState now = ScreenState.capture(
                        WarmupService.this, screenW, screenH);

                // BACK dropped us out of TikTok, so the screen we "recovered" from was
                // really the feed. Stop trusting BACK for the rest of the session.
                if (!now.isTikTok()) {
                    backUnsafe = true;
                    ActionLog.add("recover",
                            "back exited TikTok - misread the screen, disabling back", false);
                    launchTikTok();
                    later(2500, new Runnable() { @Override public void run() { loop(); } });
                    return;
                }
                if (now.screen == ScreenState.Screen.FEED) {
                    loop();
                } else {
                    recoverToFeed(now, attempt + 1);
                }
            }
        });
    }

    /** Bring TikTok to the front. Used on start and whenever it disappears. */
    private boolean launchTikTok() {
        if (prefs != null && prefs.dryRun()) return false;
        try {
            PackageManager pm = getPackageManager();
            for (String p : ScreenState.TIKTOK_PACKAGES) {
                Intent i = pm.getLaunchIntentForPackage(p);
                if (i != null) {
                    i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK
                            | Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED);
                    startActivity(i);
                    return true;
                }
            }
        } catch (Throwable ignored) { }
        return false;
    }

    private boolean batteryLow() {
        try {
            Intent b = registerReceiver(null,
                    new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
            if (b == null) return false;
            int level = b.getIntExtra(BatteryManager.EXTRA_LEVEL, -1);
            int scale = b.getIntExtra(BatteryManager.EXTRA_SCALE, -1);
            int plugged = b.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0);
            if (level < 0 || scale <= 0 || plugged != 0) return false;
            return (level * 100 / scale) < 15;
        } catch (Throwable t) {
            return false;
        }
    }

    // --------------------------------------------------------- watch a video

    private void watchVideo(final ScreenState st) {
        videoCount++;
        sinceSearch++;

        if (prefs.research()) {
            String[] row = st.researchRow();
            research.record(row[0], row[1], row[2]);
        }

        final int watched = behavior.watchTimeMs();
        ActionLog.add("watch", (watched / 1000.0) + "s", false);
        tick("watching " + (watched / 1000) + "s");

        later(watched, new Runnable() {
            @Override public void run() { engage(watched); }
        });
    }

    /** Every decision is gated on how long the video was actually watched. */
    private void engage(final int watched) {
        if (!running) return;

        if (behavior.shouldOpenComments(watched)) {
            openComments(watched);
            return;
        }
        if (behavior.shouldOpenProfile(watched)) {
            openProfile(watched);
            return;
        }
        if (behavior.shouldSave(watched)) {
            tapNamed("savePost", currentBookmark(), new Runnable() {
                @Override public void run() { afterEngage(watched); }
            });
            return;
        }
        if (prefs.repost() && behavior.shouldRepost(watched)) {
            repost(watched);
            return;
        }
        if (behavior.shouldLike(watched)) {
            likeByDoubleTap(new Runnable() {
                @Override public void run() { afterEngage(watched); }
            });
            return;
        }
        afterEngage(watched);
    }

    private void afterEngage(int watched) {
        int pause = behavior.microPauseMs();
        if (pause > 0) {
            ActionLog.add("pause", (pause / 1000) + "s idle", false);
            tick("idle");
            later(pause, new Runnable() { @Override public void run() { advance(); } });
        } else {
            later(behavior.reactionMs(), new Runnable() {
                @Override public void run() { advance(); }
            });
        }
    }

    private void advance() {
        if (!running) return;
        if (behavior.shouldSwipeBack()) {
            ActionLog.add("swipePrevious", "re-watch", prefs.dryRun());
            swipe(false);
            later(behavior.between(2500, 6000), new Runnable() {
                @Override public void run() { swipe(true); afterSwipe(); }
            });
            return;
        }
        ActionLog.add("swipeNext", "", prefs.dryRun());
        swipe(true);
        afterSwipe();
    }

    private void afterSwipe() {
        later(behavior.between(600, 1100), new Runnable() {
            @Override public void run() { loop(); }
        });
    }

    // ------------------------------------------------------------- comments

    private void openComments(final int watched) {
        ScreenState st = ScreenState.capture(this, screenW, screenH);
        ScreenState.Item target = st.comment();
        if (target == null) {
            ActionLog.add("openComments", "button not found, skipped", true);
            afterEngage(watched);
            return;
        }
        final int count = st.commentCount();
        ActionLog.add("openComments", count > 0 ? count + " comments" : "", prefs.dryRun());
        tapItem(target);

        later(behavior.between(900, 1600), new Runnable() {
            @Override public void run() {
                ScreenState now = ScreenState.capture(
                        WarmupService.this, screenW, screenH);
                int dwell = behavior.commentDwellMs(count > 0 ? count : now.commentCount());
                tick("reading comments");

                if (prefs.likeComments() && behavior.shouldLikeComment()) {
                    likeAComment(now);
                }
                later(dwell, new Runnable() {
                    @Override public void run() { closeSheet(watched, 0); }
                });
            }
        });
    }

    /** Like one of the visible comments - a heart on the right of a comment row. */
    private void likeAComment(ScreenState st) {
        ScreenState.Item best = null;
        for (ScreenState.Item it : st.items) {
            if (!it.clickable) continue;
            if (it.cx() < st.width * 0.80) continue;
            if (it.cy() < st.height * 0.30 || it.cy() > st.height * 0.80) continue;
            if (it.bounds.width() > st.width * 0.20) continue;
            if (best == null || it.cy() < best.cy()) best = it;
        }
        if (best == null) {
            ActionLog.add("likeComment", "no comment heart found", true);
            return;
        }
        ActionLog.add("likeComment", "", prefs.dryRun());
        tapItem(best);
    }

    /** Close the sheet and verify we actually made it back to the feed. */
    private void closeSheet(final int watched, final int attempt) {
        if (!running) return;
        if (attempt >= 4) {
            ActionLog.add("closeComments", "could not confirm feed", false);
            afterEngage(watched);
            return;
        }
        back();
        later(behavior.between(600, 1100), new Runnable() {
            @Override public void run() {
                ScreenState now = ScreenState.capture(
                        WarmupService.this, screenW, screenH);
                if (now.screen == ScreenState.Screen.FEED || !now.isTikTok()) {
                    afterEngage(watched);
                } else {
                    closeSheet(watched, attempt + 1);
                }
            }
        });
    }

    // -------------------------------------------------------------- profile

    private void openProfile(final int watched) {
        ScreenState st = ScreenState.capture(this, screenW, screenH);
        ScreenState.Item target = st.avatar();
        if (target == null) {
            ActionLog.add("openProfile", "avatar not found, skipped", true);
            afterEngage(watched);
            return;
        }
        ActionLog.add("openProfile", "", prefs.dryRun());
        tapItem(target);
        tick("on a profile");

        later(behavior.profileDwellMs(), new Runnable() {
            @Override public void run() { closeSheet(watched, 0); }
        });
    }

    // --------------------------------------------------------------- repost

    private void repost(final int watched) {
        ScreenState st = ScreenState.capture(this, screenW, screenH);
        ScreenState.Item share = st.share();
        if (share == null) {
            afterEngage(watched);
            return;
        }
        ActionLog.add("repost", "opening share sheet", prefs.dryRun());
        tapItem(share);

        later(behavior.between(1000, 1800), new Runnable() {
            @Override public void run() {
                ScreenState now = ScreenState.capture(
                        WarmupService.this, screenW, screenH);
                ScreenState.Item rp = null;
                for (ScreenState.Item it : now.items) {
                    if (it.text.contains("repost") || it.desc.contains("repost")) { rp = it; break; }
                }
                if (rp != null) {
                    ActionLog.add("repost", "confirmed", prefs.dryRun());
                    tapItem(rp);
                    later(behavior.between(800, 1400), new Runnable() {
                        @Override public void run() { closeSheet(watched, 0); }
                    });
                } else {
                    ActionLog.add("repost", "no repost option, backing out", true);
                    closeSheet(watched, 0);
                }
            }
        });
    }

    // ---------------------------------------------------------- niche search

    private void nicheSearch() {
        String[] terms = prefs.nicheTerms();
        if (terms.length == 0) { loop(); return; }
        final String term = terms[rnd.nextInt(terms.length)];

        ScreenState st = ScreenState.capture(this, screenW, screenH);
        ScreenState.Item searchBtn = st.search();
        if (searchBtn == null) {
            ActionLog.add("nicheSearch", "search button not found, skipped", true);
            loop();
            return;
        }
        ActionLog.add("nicheSearch", term, prefs.dryRun());
        tick("searching");
        tapItem(searchBtn);

        later(behavior.between(1100, 1900), new Runnable() {
            @Override public void run() {
                if (!prefs.dryRun() && !typeIntoField(term)) {
                    ActionLog.add("nicheSearch", "no input field, backing out", true);
                    closeSheet(0, 0);
                    return;
                }
                later(behavior.between(700, 1400), new Runnable() {
                    @Override public void run() {
                        submitSearch();
                        later(behavior.searchDwellMs(), new Runnable() {
                            @Override public void run() { browseResults(); }
                        });
                    }
                });
            }
        });
    }

    /** Scroll the results a little, then return to the feed. */
    private void browseResults() {
        ActionLog.add("nicheSearch", "browsing results", prefs.dryRun());
        swipe(true);
        later(behavior.between(2500, 6000), new Runnable() {
            @Override public void run() {
                swipe(true);
                later(behavior.between(2500, 6000), new Runnable() {
                    @Override public void run() { closeSheet(0, 0); }
                });
            }
        });
    }

    private boolean typeIntoField(String text) {
        AccessibilityNodeInfo root = null;
        try {
            root = getRootInActiveWindow();
            AccessibilityNodeInfo field = findEditable(root, 0);
            if (field == null) return false;
            Bundle args = new Bundle();
            args.putCharSequence(
                    AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text);
            boolean ok = field.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args);
            try { field.recycle(); } catch (Throwable ignored) { }
            return ok;
        } catch (Throwable t) {
            return false;
        } finally {
            if (root != null) try { root.recycle(); } catch (Throwable ignored) { }
        }
    }

    private AccessibilityNodeInfo findEditable(AccessibilityNodeInfo node, int depth) {
        if (node == null || depth > 40) return null;
        try {
            if (node.isEditable()) return AccessibilityNodeInfo.obtain(node);
            for (int i = 0; i < node.getChildCount(); i++) {
                AccessibilityNodeInfo c = node.getChild(i);
                if (c == null) continue;
                AccessibilityNodeInfo hit = findEditable(c, depth + 1);
                try { c.recycle(); } catch (Throwable ignored) { }
                if (hit != null) return hit;
            }
        } catch (Throwable ignored) { }
        return null;
    }

    private void submitSearch() {
        if (prefs.dryRun()) { ActionLog.add("nicheSearch", "would submit", true); return; }
        AccessibilityNodeInfo root = null;
        try {
            root = getRootInActiveWindow();
            AccessibilityNodeInfo field = findEditable(root, 0);
            if (field != null) {
                if (Build.VERSION.SDK_INT >= 30) {
                    field.performAction(AccessibilityNodeInfo.AccessibilityAction
                            .ACTION_IME_ENTER.getId());
                }
                try { field.recycle(); } catch (Throwable ignored) { }
            }
        } catch (Throwable ignored) {
        } finally {
            if (root != null) try { root.recycle(); } catch (Throwable ignored) { }
        }
        // Fall back to a visible "Search" button if the IME action did nothing.
        ScreenState st = ScreenState.capture(this, screenW, screenH);
        for (ScreenState.Item it : st.items) {
            if (!it.clickable) continue;
            for (String n : new String[]{"search", "rechercher", "buscar"}) {
                if (it.text.contains(n) && it.cy() < st.height * 0.20) { tapItem(it); return; }
            }
        }
    }

    // -------------------------------------------------------------- gestures

    private ScreenState.Item currentBookmark() {
        return ScreenState.capture(this, screenW, screenH).bookmark();
    }

    private void tapNamed(String name, ScreenState.Item item, Runnable done) {
        if (item == null) {
            ActionLog.add(name, "target not found, skipped", true);
        } else {
            ActionLog.add(name, "", prefs.dryRun());
            tapItem(item);
        }
        later(behavior.between(500, 1100), done);
    }

    private void likeByDoubleTap(Runnable done) {
        // Always a centre double-tap rather than the heart: double-tap only ever
        // likes, while the heart toggles and would un-like an already-liked video.
        ActionLog.add("likePost", "double-tap", prefs.dryRun());
        float x = screenW * 0.5f + jitter(screenW * 0.10f);
        float y = screenH * 0.45f + jitter(screenH * 0.08f);
        tap(x, y);
        final float x2 = x + jitter(24f), y2 = y + jitter(24f);
        later(behavior.between(90, 170), new Runnable() {
            @Override public void run() { tap(x2, y2); }
        });
        later(behavior.between(600, 1200), done);
    }

    private void tapItem(ScreenState.Item it) {
        if (it == null) return;
        float x = it.cx() + jitter(Math.min(it.bounds.width() * 0.35f, screenW * 0.02f));
        float y = it.cy() + jitter(Math.min(it.bounds.height() * 0.35f, screenH * 0.01f));
        tap(x, y);
    }

    private float jitter(float span) { return (rnd.nextFloat() - 0.5f) * span; }

    private void swipe(boolean up) {
        if (prefs.dryRun()) return;
        float cx = screenW * 0.5f + jitter(screenW * 0.12f);
        float y1 = screenH * (up ? 0.72f : 0.30f) + jitter(screenH * 0.04f);
        float y2 = screenH * (up ? 0.28f : 0.74f) + jitter(screenH * 0.04f);

        Path p = new Path();
        p.moveTo(cx, y1);
        p.quadTo(cx + jitter(screenW * 0.10f), (y1 + y2) / 2f,
                 cx + jitter(screenW * 0.05f), y2);
        dispatch(p, behavior.between(160, 340));
    }

    private void tap(float x, float y) {
        if (prefs.dryRun()) return;
        Path p = new Path();
        p.moveTo(x, y);
        p.lineTo(x + 1f, y + 1f);
        dispatch(p, behavior.between(50, 100));
    }

    private void back() {
        if (prefs.dryRun()) return;
        try { performGlobalAction(GLOBAL_ACTION_BACK); } catch (Throwable ignored) { }
    }

    private void dispatch(Path path, int durationMs) {
        try {
            GestureDescription.Builder b = new GestureDescription.Builder();
            b.addStroke(new GestureDescription.StrokeDescription(path, 0L, durationMs));
            dispatchGesture(b.build(), null, null);
        } catch (Throwable ignored) { }
    }
}
