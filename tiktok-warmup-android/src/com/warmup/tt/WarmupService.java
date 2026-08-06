package com.warmup.tt;

import android.accessibilityservice.AccessibilityService;
import android.accessibilityservice.GestureDescription;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
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

import java.util.List;
import java.util.Random;

/**
 * Session orchestrator.
 *
 * Every cycle reads the screen once, decides, then acts. The central decision is
 * whether the video is in the account's niche: matches get watched properly and
 * engaged with, everything else gets skipped in a second or two and touched by
 * nothing. Engagement that isn't niche-gated trains the interest graph toward
 * whatever the feed happens to serve, which is worse than doing nothing at all.
 */
public class WarmupService extends AccessibilityService implements OverlayController.Listener {

    public static volatile WarmupService instance;

    private final Handler handler = new Handler(Looper.getMainLooper());
    /** Separate from the action handler, which gets wholesale-cleared on stop/skip. */
    private final Handler beat = new Handler(Looper.getMainLooper());
    private final Random rnd = new Random();

    private Prefs prefs;
    private Behavior behavior;
    private Niche niche;
    private ResearchLog research;
    private SelfStats selfStats;
    private OverlayController overlay;

    private boolean running = false, paused = false, userPaused = false;
    private long startTime, endTime;
    private int videoCount = 0, matchedCount = 0;
    private int likes = 0, saves = 0, comments = 0, follows = 0, reposts = 0;
    private int recoveries = 0, unknownScreens = 0, pausedCycles = 0;
    private boolean backUnsafe = false;
    private int sinceSearch = 0, nextSearchAt = 0;
    private boolean statsDoneThisSession = false;
    private String lastAction = "-", detected = "-";
    private Behavior.Match lastMatch = Behavior.Match.UNKNOWN;
    private long lastNotify = 0;
    private String lastText = "";
    private int unreadable = 0, forcedMatch = 0;
    private boolean inSearchFeed = false;
    /** Rolling window - the current state of the feed, not the session average. */
    private final boolean[] recent = new boolean[40];
    private int recentIdx = 0, recentN = 0;
    private long pauseStart = 0;

    private int screenW = 1080, screenH = 2400;

    // ------------------------------------------------------------ lifecycle

    @Override
    protected void onServiceConnected() {
        super.onServiceConnected();
        instance = this;
        reload();
        measureScreen();
    }

    public void reload() {
        prefs = new Prefs(this);
        niche = new Niche(prefs.nicheRaw());
        research = new ResearchLog(this);
        selfStats = new SelfStats(this);
    }

    @Override
    public boolean onUnbind(Intent intent) {
        stopSession("service unbound");
        if (overlay != null) overlay.hide();
        instance = null;
        return super.onUnbind(intent);
    }

    @Override
    public void onDestroy() {
        stopSession("service destroyed");
        if (overlay != null) overlay.hide();
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

    /** Show the control without starting - the user opens TikTok, then taps it. */
    public void arm() {
        reload();
        if (overlay == null) overlay = new OverlayController(this, this);
        overlay.setMode(OverlayController.Mode.ARMED);
        overlay.show();
        ActionLog.add("armed", "open TikTok, then tap the pill", false);
    }

    public void disarm() {
        stopSession("dismissed");
        if (overlay != null) overlay.hide();
    }

    public boolean isArmed() { return overlay != null && overlay.isShown(); }

    public void startSession(int minutes, int startDelaySeconds) {
        measureScreen();
        reload();
        behavior = new Behavior(prefs.rates());

        ActionLog.reset();
        running = true;
        paused = userPaused = false;
        videoCount = matchedCount = 0;
        likes = saves = comments = follows = reposts = 0;
        recoveries = unknownScreens = pausedCycles = 0;
        backUnsafe = false;
        statsDoneThisSession = false;
        inSearchFeed = false;
        forcedMatch = 0;
        unreadable = 0;
        sinceSearch = 0;
        nextSearchAt = prefs.nicheEnabled() && !niche.isEmpty() ? behavior.between(2, 6)
                                                                : Integer.MAX_VALUE;

        long delay = startDelaySeconds * 1000L;
        long length = behavior.sessionLengthMs(minutes);
        startTime = System.currentTimeMillis() + delay;
        endTime = startTime + length;

        ActionLog.add("session", "start ~" + (length / 60000) + "m, niche: "
                + (niche.isEmpty() ? "none set" : niche.size() + " keywords"), false);

        if (prefs.overlay()) {
            if (overlay == null) overlay = new OverlayController(this, this);
            overlay.show();
            overlay.setMode(OverlayController.Mode.RUNNING);
        }
        notify("Boost running", "starting");
        beat.removeCallbacks(heartbeat);
        beat.post(heartbeat);
        handler.postDelayed(new Runnable() {
            @Override public void run() { loop(); }
        }, delay);
    }

    /** Explicit stop: end the session and take the bubble away. */
    public void stopAll(String reason) {
        stopSession(reason);
        if (overlay != null) overlay.hide();
    }

    public void stopSession(String reason) {
        boolean was = running;
        if (was) ActionLog.add("session", "stopped (" + reason + ")", false);
        running = false;
        paused = userPaused = false;
        pauseStart = 0;
        recentIdx = recentN = 0;
        handler.removeCallbacksAndMessages(null);
        beat.removeCallbacks(heartbeat);
        if (overlay != null && overlay.isShown()) {
            overlay.setMode(OverlayController.Mode.ARMED);
        }
        Notifications.clear(this);

        // Auto mode: come back after a natural gap rather than running non-stop.
        if (was && prefs != null && prefs.autoMode()
                && "session complete".equals(reason)) {
            long gap = behavior.gapMs();
            ActionLog.add("auto", "next session in " + (gap / 60000) + "m", false);
            handler.postDelayed(new Runnable() {
                @Override public void run() {
                    if (isArmed()) startSession(prefs.duration(), 4);
                }
            }, gap);
        }
    }

    // -------------------------------------------------------- overlay events

    @Override public void onOverlayStart() {
        if (running || prefs == null) return;
        startSession(prefs.duration(), 3);
    }

    @Override public void onOverlayStop()    { stopAll("stopped from bubble"); }
    @Override public void onOverlayDismiss() { disarm(); }

    @Override public void onOverlayPause() {
        if (!running) return;
        userPaused = !userPaused;
        if (userPaused) {
            pauseStart = System.currentTimeMillis();
        } else if (pauseStart > 0) {
            endTime += System.currentTimeMillis() - pauseStart;   // give the time back
            pauseStart = 0;
        }
        ActionLog.add(userPaused ? "paused" : "resumed", "by you", false);
        if (overlay != null) overlay.setPaused(userPaused);
        if (!userPaused) loop();
    }

    @Override public void onOverlaySkip() {
        if (!running) return;
        ActionLog.add("skip", "by you", false);
        handler.removeCallbacksAndMessages(null);
        swipe(true);
        later(900, new Runnable() { @Override public void run() { loop(); } });
    }

    // ------------------------------------------------------------ accessors

    public boolean isRunning()      { return running; }
    public boolean isPaused()       { return paused || userPaused; }
    public int     videoCount()     { return videoCount; }
    public int     matchedPercent() {
        return videoCount == 0 ? 0 : (int) Math.round(matchedCount * 100.0 / videoCount);
    }
    public String  lastAction()     { return lastAction; }
    public String  detectedScreen() { return detected; }
    public String  lastText()       { return lastText; }
    public int     unreadableRun()  { return unreadable; }

    /** Frozen while paused, so the countdown stays honest. */
    public long remainingMs() {
        long now = userPaused && pauseStart > 0 ? pauseStart : System.currentTimeMillis();
        long r = endTime - now;
        return r > 0 ? r : 0;
    }

    public long elapsedMs() {
        long now = userPaused && pauseStart > 0 ? pauseStart : System.currentTimeMillis();
        long e = now - startTime;
        return e > 0 ? e : 0;
    }

    private void pushMatch(boolean m) {
        recent[recentIdx] = m;
        recentIdx = (recentIdx + 1) % recent.length;
        if (recentN < recent.length) recentN++;
    }

    /** Share of the last 40 *For You* videos that matched - search results excluded. */
    public int rollingPercent() {
        if (recentN == 0) return 0;
        int c = 0;
        for (int i = 0; i < recentN; i++) if (recent[i]) c++;
        return c * 100 / recentN;
    }

    /** Below target, the bot pushes harder: more searching, faster skipping. */
    public boolean belowTarget() {
        return recentN >= 8 && rollingPercent() < prefs.nicheTarget();
    }

    private double progress() {
        long total = endTime - startTime;
        if (total <= 0) return 1.0;
        double p = (System.currentTimeMillis() - startTime) / (double) total;
        return p < 0 ? 0 : (p > 1 ? 1 : p);
    }

    private String countsLine() {
        return "♥ " + likes + "   ⚑ " + saves + "   ○ " + comments
                + (follows > 0 ? "   +" + follows : "");
    }

    /**
     * The pill used to freeze because tick() only ran at decision points, and a matched
     * video can sit for fifty seconds. This drives the display independently of the
     * action loop, on its own handler so stop/skip can't wipe it.
     */
    private final Runnable heartbeat = new Runnable() {
        @Override public void run() {
            if (!running) return;
            paint();
            beat.postDelayed(this, 1000L);
        }
    };

    private void paint() {
        long s = remainingMs() / 1000;
        String time = String.format("%d:%02d", s / 60, s % 60);
        if (overlay != null && overlay.isShown()) {
            overlay.updateStats(time, videoCount, rollingPercent(), prefs.nicheTarget(),
                    detected, lastAction, lastMatch == Behavior.Match.YES, countsLine());
        }
        long now = System.currentTimeMillis();
        if (now - lastNotify > 2500) {
            lastNotify = now;
            notify(isPaused() ? "Boost paused" : "Boost running",
                    videoCount + " videos - " + rollingPercent() + "% niche - " + time);
        }
    }

    private void tick(String state) {
        lastAction = state;
        paint();
    }

    private void notify(String a, String b) {
        try { Notifications.show(this, a, b); } catch (Throwable ignored) { }
    }

    private void later(long ms, Runnable r) {
        final Runnable rr = r;
        handler.postDelayed(new Runnable() {
            @Override public void run() { if (running && !userPaused) rr.run(); }
        }, ms);
    }

    // ----------------------------------------------------------- main cycle

    private void loop() {
        if (!running || userPaused) return;
        if (System.currentTimeMillis() >= endTime) {
            stopSession("session complete");
            return;
        }
        behavior.setProgress(progress());

        if (batteryLow()) { stopSession("battery below 15%"); return; }

        // One capture per cycle, threaded through everything below.
        final ScreenState st = ScreenState.capture(this, screenW, screenH);
        detected = st.screen.toString();

        if (!st.isTikTok()) {
            if (!paused) {
                paused = true;
                ActionLog.add("paused", "TikTok not in front (" + shortPkg(st.pkg) + ")", false);
            }
            pausedCycles++;
            tick("waiting for TikTok");
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
                tick("unrecognised screen");
                later(1500, new Runnable() { @Override public void run() { loop(); } });
                return;
            }
            ActionLog.add("unknown", "assuming feed", false);
            unknownScreens = 0;
        } else if (st.screen != ScreenState.Screen.FEED) {
            recoverToFeed(st, 0);
            return;
        } else {
            unknownScreens = 0;
        }
        recoveries = 0;

        // Once per session, snapshot your own numbers.
        if (!statsDoneThisSession && prefs.selfStats() && videoCount > 6
                && selfStats.dueForSnapshot()) {
            statsDoneThisSession = true;
            snapshotOwnProfile();
            return;
        }

        if (sinceSearch >= nextSearchAt && prefs.nicheEnabled() && !niche.isEmpty()) {
            sinceSearch = 0;
            // A cold feed needs searching far more often - it is the fastest way to get
            // niche content in front of the account at all.
            nextSearchAt = belowTarget() ? behavior.between(4, 9)
                                         : behavior.between(16, 34);
            nicheSearch(st);
            return;
        }

        watchVideo(st);
    }

    private static String shortPkg(String p) {
        if (p == null || p.length() == 0) return "unknown";
        int i = p.lastIndexOf('.');
        return i > 0 ? p.substring(i + 1) : p;
    }

    // --------------------------------------------------------- watch a video

    private void watchVideo(final ScreenState st) {
        videoCount++;
        sinceSearch++;

        String[] row = st.researchRow();          // author, caption, sound
        String blob = st.contentText();
        lastText = blob.length() > 100 ? blob.substring(0, 100) : blob;
        long likeCount = st.likeCount();

        final Behavior.Match match;
        boolean fromSearch = false;
        if (forcedMatch > 0) {
            forcedMatch--;                       // came from a niche search
            fromSearch = true;
            match = Behavior.Match.YES;
        } else if (niche.isEmpty()) {
            match = Behavior.Match.YES;
        } else if (st.textUnreadable()) {
            unreadable++;
            match = Behavior.Match.UNKNOWN;
        } else {
            unreadable = 0;
            match = niche.matches(blob) ? Behavior.Match.YES : Behavior.Match.NO;
        }
        lastMatch = match;
        if (match == Behavior.Match.YES) matchedCount++;
        // Only real For You videos count toward the score. Search results are matches
        // by construction, so counting them would let the number climb to target
        // without your actual feed improving - measuring the push, not the result.
        if (!fromSearch) pushMatch(match == Behavior.Match.YES);
        behavior.setAggressive(belowTarget());

        if (prefs.research()) {
            research.record(row[0], row[1], row[2], likeCount,
                    match == Behavior.Match.YES);
        }

        final int watched = behavior.watchTimeMs(match);
        String tag = match == Behavior.Match.YES ? "watch"
                   : (match == Behavior.Match.UNKNOWN ? "unsure" : "skim");
        ActionLog.add(tag, (watched / 1000.0) + "s"
                + (match == Behavior.Match.UNKNOWN ? "  no text readable" : ""), false);
        tick(match == Behavior.Match.NO ? "skipping"
                : "watching " + (watched / 1000) + "s");

        later(watched, new Runnable() {
            @Override public void run() { engage(watched, match); }
        });
    }

    /** Probabilities scale with match state; NO engages with nothing. */
    private void engage(final int watched, final Behavior.Match m) {
        if (!running) return;
        if (m == Behavior.Match.NO) { afterEngage(watched); return; }

        if (behavior.shouldOpenComments(watched, m)) { openComments(watched); return; }
        if (behavior.shouldOpenProfile(watched, m))  { openProfile(watched, m); return; }

        if (behavior.shouldSave(watched, m)) {
            ScreenState st = ScreenState.capture(this, screenW, screenH);
            tapNamed("save", st.bookmark(), new Runnable() {
                @Override public void run() { saves++; afterEngage(watched); }
            });
            return;
        }
        if (prefs.repostEnabled() && behavior.shouldRepost(watched, m)) {
            repost(watched);
            return;
        }
        if (behavior.shouldLike(watched, m)) {
            likeByDoubleTap(new Runnable() {
                @Override public void run() { likes++; afterEngage(watched); }
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
        if (inSearchFeed && forcedMatch == 0) {
            ActionLog.add("search", "back to For You", false);
            returnHome();
            return;
        }
        if (lastMatch == Behavior.Match.YES && behavior.shouldSwipeBack()) {
            ActionLog.add("rewatch", "", false);
            swipe(false);
            later(behavior.between(3000, 8000), new Runnable() {
                @Override public void run() { swipe(true); afterSwipe(); }
            });
            return;
        }
        swipe(true);
        afterSwipe();
    }

    private void afterSwipe() {
        later(behavior.between(600, 1100), new Runnable() {
            @Override public void run() { loop(); }
        });
    }

    // ------------------------------------------------------------- recovery

    private void recoverToFeed(ScreenState st, final int attempt) {
        if (!running) return;
        if (attempt >= 5) {
            ActionLog.add("recover", "gave up on " + st.screen, false);
            recoveries++;
            if (recoveries >= 3) { stopSession("cannot reach the feed"); return; }
            later(2000, new Runnable() { @Override public void run() { loop(); } });
            return;
        }

        // Home in the bottom nav returns to the feed from anywhere and can never
        // eject us from the app, so it is always tried before BACK.
        ScreenState.Item home = st.home();
        if (home != null && attempt < 3) {
            ActionLog.add("recover", "on " + st.screen + ", tapping Home", false);
            tick("returning to feed");
            tapItem(home);
            verifyRecovery(attempt);
            return;
        }
        if (!st.isDismissable() || backUnsafe) {
            later(1500, new Runnable() { @Override public void run() { loop(); } });
            return;
        }
        ActionLog.add("recover", "on " + st.screen + ", pressing back", false);
        back();
        verifyRecovery(attempt);
    }

    private void verifyRecovery(final int attempt) {
        later(behavior.between(700, 1300), new Runnable() {
            @Override public void run() {
                ScreenState now = ScreenState.capture(
                        WarmupService.this, screenW, screenH);
                if (!now.isTikTok()) {
                    backUnsafe = true;
                    ActionLog.add("recover", "left TikTok - disabling back", false);
                    later(2500, new Runnable() { @Override public void run() { loop(); } });
                    return;
                }
                if (now.screen == ScreenState.Screen.FEED) loop();
                else recoverToFeed(now, attempt + 1);
            }
        });
    }

    // ------------------------------------------------------------- comments

    private void openComments(final int watched) {
        ScreenState st = ScreenState.capture(this, screenW, screenH);
        ScreenState.Item target = st.comment();
        if (target == null) { afterEngage(watched); return; }

        final int count = st.commentCount();
        ActionLog.add("comments", count > 0 ? count + " comments" : "", false);
        comments++;
        tapItem(target);

        later(behavior.between(900, 1600), new Runnable() {
            @Override public void run() {
                ScreenState now = ScreenState.capture(
                        WarmupService.this, screenW, screenH);
                int dwell = behavior.commentDwellMs(count > 0 ? count : now.commentCount());
                tick("reading comments");
                if (prefs.likeComments() && behavior.shouldLikeComment()) likeAComment(now);
                later(dwell, new Runnable() {
                    @Override public void run() { closeSheet(watched, 0); }
                });
            }
        });
    }

    private void likeAComment(ScreenState st) {
        ScreenState.Item best = null;
        for (ScreenState.Item it : st.items) {
            if (!it.clickable) continue;
            if (it.cx() < st.width * 0.80) continue;
            if (it.cy() < st.height * 0.30 || it.cy() > st.height * 0.80) continue;
            if (it.bounds.width() > st.width * 0.20) continue;
            if (best == null || it.cy() < best.cy()) best = it;
        }
        if (best == null) return;
        ActionLog.add("likeComment", "", false);
        tapItem(best);
    }

    private void closeSheet(final int watched, final int attempt) {
        if (!running) return;
        if (attempt >= 4) { afterEngage(watched); return; }
        back();
        later(behavior.between(600, 1100), new Runnable() {
            @Override public void run() {
                ScreenState now = ScreenState.capture(
                        WarmupService.this, screenW, screenH);
                if (now.screen == ScreenState.Screen.FEED || !now.isTikTok()) {
                    afterEngage(watched);
                } else closeSheet(watched, attempt + 1);
            }
        });
    }

    // -------------------------------------------------------------- profile

    private void openProfile(final int watched, final Behavior.Match m) {
        ScreenState st = ScreenState.capture(this, screenW, screenH);
        ScreenState.Item target = st.avatar();
        if (target == null) { afterEngage(watched); return; }

        ActionLog.add("profile", "", false);
        tapItem(target);
        tick("on a creator profile");

        later(behavior.between(1200, 2200), new Runnable() {
            @Override public void run() {
                // Following a creator in your niche is a strong, lasting interest
                // signal - but only ever on a matched video, and never in bulk.
                if (prefs.followEnabled() && behavior.shouldFollow(watched, m)) {
                    ScreenState now = ScreenState.capture(
                            WarmupService.this, screenW, screenH);
                    ScreenState.Item f = findFollow(now);
                    if (f != null) {
                        ActionLog.add("follow", "niche creator", false);
                        follows++;
                        tapItem(f);
                    }
                }
                later(behavior.profileDwellMs(), new Runnable() {
                    @Override public void run() { closeSheet(watched, 0); }
                });
            }
        });
    }

    private ScreenState.Item findFollow(ScreenState st) {
        for (ScreenState.Item it : st.items) {
            if (!it.clickable) continue;
            String s = it.text.length() > 0 ? it.text : it.desc;
            if (s.equals("follow") || s.equals("suivre") || s.equals("seguir")) return it;
        }
        return null;
    }

    // --------------------------------------------------------------- repost

    private void repost(final int watched) {
        ScreenState st = ScreenState.capture(this, screenW, screenH);
        ScreenState.Item share = st.share();
        if (share == null) { afterEngage(watched); return; }
        ActionLog.add("repost", "opening share", false);
        tapItem(share);

        later(behavior.between(1000, 1800), new Runnable() {
            @Override public void run() {
                ScreenState now = ScreenState.capture(
                        WarmupService.this, screenW, screenH);
                ScreenState.Item rp = null;
                for (ScreenState.Item it : now.items) {
                    if (it.text.contains("repost") || it.desc.contains("repost")) { rp = it; break; }
                }
                if (rp != null) { reposts++; tapItem(rp); }
                later(behavior.between(800, 1400), new Runnable() {
                    @Override public void run() { closeSheet(watched, 0); }
                });
            }
        });
    }

    // ---------------------------------------------------------- niche search

    private void nicheSearch(ScreenState st) {
        String[] terms = prefs.nicheTerms();
        if (terms.length == 0) { loop(); return; }
        final String term = terms[rnd.nextInt(terms.length)];

        ScreenState.Item searchBtn = st.search();
        if (searchBtn == null) {
            ActionLog.add("search", "search button not found", true);
            loop();
            return;
        }

        ActionLog.add("search", term, false);
        tick("searching niche");
        tapItem(searchBtn);

        later(behavior.between(1100, 1900), new Runnable() {
            @Override public void run() {
                if (!typeIntoField(term)) {
                    ActionLog.add("search", "could not type", true);
                    returnHome();
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

    /**
     * Open the first search result and work through a few videos there.
     *
     * Search results are niche by construction, so this is the only place engagement
     * is guaranteed to land on the right content - which makes it the fastest way to
     * push the interest graph when the For You page hasn't tuned yet.
     */
    private void browseResults() {
        ScreenState st = ScreenState.capture(this, screenW, screenH);
        ScreenState.Item first = firstResult(st);
        if (first == null) {
            ActionLog.add("search", "no results found", true);
            returnHome();
            return;
        }
        ActionLog.add("search", "opening results", false);
        tapItem(first);
        // Behind target, stay in the search feed longer - it is the only place every
        // video is guaranteed to be on-niche.
        forcedMatch = belowTarget() ? behavior.between(8, 16) : behavior.between(4, 9);
        inSearchFeed = true;

        later(behavior.between(1400, 2400), new Runnable() {
            @Override public void run() { loop(); }
        });
    }

    /** Top-left thumbnail of the results grid. */
    private ScreenState.Item firstResult(ScreenState st) {
        ScreenState.Item best = null;
        for (ScreenState.Item it : st.items) {
            if (!it.clickable) continue;
            if (it.cy() < st.height * 0.20 || it.cy() > st.height * 0.80) continue;
            if (it.bounds.width() < st.width * 0.18) continue;   // not an icon
            if (best == null
                    || it.cy() < best.cy() - st.height * 0.02
                    || (Math.abs(it.cy() - best.cy()) < st.height * 0.02
                        && it.cx() < best.cx())) {
                best = it;
            }
        }
        return best;
    }

    private void returnHome() {
        inSearchFeed = false;
        forcedMatch = 0;
        ScreenState st = ScreenState.capture(this, screenW, screenH);
        ScreenState.Item home = st.home();
        if (home != null) tapItem(home); else back();
        later(behavior.between(1200, 2000), new Runnable() {
            @Override public void run() { loop(); }
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
    }

    // ---------------------------------------------------- own-account stats

    /**
     * Read-only visit to your own profile to snapshot each video's play count.
     * TikTok keeps no history, so this builds the time series you need to tell
     * whether anything you changed actually worked.
     */
    private void snapshotOwnProfile() {
        ScreenState st = ScreenState.capture(this, screenW, screenH);
        ScreenState.Item tab = st.profileTab();
        if (tab == null) { loop(); return; }

        ActionLog.add("stats", "checking your numbers", false);
        tick("reading your stats");
        tapItem(tab);

        later(behavior.between(1600, 2600), new Runnable() {
            @Override public void run() {
                ScreenState now = ScreenState.capture(
                        WarmupService.this, screenW, screenH);
                List<Long> counts = now.tileCounts();
                if (!counts.isEmpty()) {
                    selfStats.record(counts);
                    long total = 0;
                    for (Long c : counts) total += c;
                    ActionLog.add("stats", counts.size() + " videos, "
                            + ResearchLog.human(total) + " views", false);
                } else {
                    ActionLog.add("stats", "no counts readable", true);
                }
                later(behavior.between(1200, 2400), new Runnable() {
                    @Override public void run() { closeSheet(0, 0); }
                });
            }
        });
    }

    // -------------------------------------------------------------- gestures

    private void tapNamed(String name, ScreenState.Item item, Runnable done) {
        if (item != null) {
            ActionLog.add(name, "", false);
            tapItem(item);
        }
        later(behavior.between(500, 1100), done);
    }

    private void likeByDoubleTap(Runnable done) {
        // Centre double-tap rather than the heart: double-tap only ever likes, while
        // the heart toggles and would un-like an already-liked video.
        ActionLog.add("like", "", false);
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
        tap(it.cx() + jitter(Math.min(it.bounds.width() * 0.35f, screenW * 0.02f)),
            it.cy() + jitter(Math.min(it.bounds.height() * 0.35f, screenH * 0.01f)));
    }

    private float jitter(float span) { return (rnd.nextFloat() - 0.5f) * span; }

    private void swipe(boolean up) {
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
        Path p = new Path();
        p.moveTo(x, y);
        p.lineTo(x + 1f, y + 1f);
        dispatch(p, behavior.between(50, 100));
    }

    private void back() {
        try { performGlobalAction(GLOBAL_ACTION_BACK); } catch (Throwable ignored) { }
    }

    private void dispatch(Path path, int durationMs) {
        try {
            GestureDescription.Builder b = new GestureDescription.Builder();
            b.addStroke(new GestureDescription.StrokeDescription(path, 0L, durationMs));
            dispatchGesture(b.build(), null, null);
        } catch (Throwable ignored) { }
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
}
