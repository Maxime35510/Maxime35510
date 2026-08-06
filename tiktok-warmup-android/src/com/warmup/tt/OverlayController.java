package com.warmup.tt;

import android.content.Context;
import android.graphics.PixelFormat;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.LinearLayout;
import android.widget.TextView;

/**
 * Floating control panel.
 *
 * Collapsed it's a small draggable pill showing state and time left. Tapped, it opens
 * into a panel with live stats and controls, then auto-collapses so it stops covering
 * the feed.
 *
 * Uses TYPE_ACCESSIBILITY_OVERLAY, which an accessibility service may add without the
 * "display over other apps" permission, so there's no extra prompt.
 *
 * Parked on the LEFT edge: the bot's own targets are the right-hand rail (x > 0.78W),
 * the screen centre and the bottom nav, so it can never tap its own controls.
 */
public final class OverlayController {

    public interface Listener {
        void onOverlayStart();
        void onOverlayStop();
        void onOverlayPause();
        void onOverlaySkip();
        void onOverlayDismiss();
    }

    public enum Mode { ARMED, RUNNING }

    private static final long AUTO_COLLAPSE_MS = 7000;

    private final Context ctx;
    private final Listener listener;
    private final Handler h = new Handler(Looper.getMainLooper());

    private WindowManager wm;
    private WindowManager.LayoutParams lp;
    private LinearLayout root;

    // collapsed
    private LinearLayout pill;
    private View dot;
    private TextView pillText;

    // expanded
    private LinearLayout panel;
    private TextView title, timeText, statLine1, statLine2, statLine3;
    private TextView pauseBtn, skipBtn, mainBtn;

    private Mode mode = Mode.ARMED;
    private boolean shown = false, expanded = false, paused = false;

    public OverlayController(Context ctx, Listener listener) {
        this.ctx = ctx;
        this.listener = listener;
    }

    // ------------------------------------------------------------------ show

    public void show() {
        if (shown) return;
        try {
            wm = (WindowManager) ctx.getSystemService(Context.WINDOW_SERVICE);

            root = new LinearLayout(ctx);
            root.setOrientation(LinearLayout.VERTICAL);
            root.addView(buildPill());
            root.addView(buildPanel());
            panel.setVisibility(View.GONE);

            lp = new WindowManager.LayoutParams(
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    overlayType(),
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                            | WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                    PixelFormat.TRANSLUCENT);
            lp.gravity = Gravity.TOP | Gravity.START;
            lp.x = Theme.dp(ctx, 8);
            lp.y = ctx.getResources().getDisplayMetrics().heightPixels / 2;

            wm.addView(root, lp);
            shown = true;
            applyMode();
        } catch (Throwable t) {
            shown = false;
        }
    }

    private LinearLayout buildPill() {
        pill = new LinearLayout(ctx);
        pill.setOrientation(LinearLayout.HORIZONTAL);
        pill.setGravity(Gravity.CENTER_VERTICAL);
        int ph = Theme.dp(ctx, 13), pv = Theme.dp(ctx, 10);
        pill.setPadding(ph, pv, ph, pv);
        pill.setBackground(Theme.solid(ctx, Theme.fade(Theme.BG, 0xEE), 24));

        dot = new View(ctx);
        dot.setBackground(Theme.accentCircle(ctx));
        LinearLayout.LayoutParams dlp = new LinearLayout.LayoutParams(
                Theme.dp(ctx, 11), Theme.dp(ctx, 11));
        dlp.rightMargin = Theme.dp(ctx, 9);
        pill.addView(dot, dlp);

        pillText = new TextView(ctx);
        Theme.style(pillText, 13f, Theme.TEXT, true);
        pillText.setText("START");
        pill.addView(pillText);

        pill.setOnTouchListener(new Dragger());
        return pill;
    }

    private LinearLayout buildPanel() {
        panel = new LinearLayout(ctx);
        panel.setOrientation(LinearLayout.VERTICAL);
        int q = Theme.dp(ctx, 14);
        panel.setPadding(q, q, q, q);
        panel.setBackground(Theme.card(ctx, Theme.fade(Theme.CARD, 0xF5), 16));
        LinearLayout.LayoutParams plp = new LinearLayout.LayoutParams(
                Theme.dp(ctx, 208), ViewGroup.LayoutParams.WRAP_CONTENT);
        plp.topMargin = Theme.dp(ctx, 6);
        panel.setLayoutParams(plp);

        LinearLayout head = new LinearLayout(ctx);
        head.setOrientation(LinearLayout.HORIZONTAL);
        head.setGravity(Gravity.CENTER_VERTICAL);

        title = new TextView(ctx);
        Theme.style(title, 11f, Theme.FAINT, true);
        title.setLetterSpacing(0.12f);
        title.setText("BOOST");
        head.addView(title, new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));

        timeText = new TextView(ctx);
        Theme.style(timeText, 15f, Theme.TEXT, true);
        head.addView(timeText);
        panel.addView(head, wide());

        statLine1 = addStat();
        statLine2 = addStat();
        statLine3 = addStat();

        LinearLayout row = new LinearLayout(ctx);
        row.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout.LayoutParams rlp = wide();
        rlp.topMargin = Theme.dp(ctx, 12);
        pauseBtn = smallBtn("PAUSE", Theme.WARN);
        skipBtn  = smallBtn("SKIP",  Theme.MUTED);
        LinearLayout.LayoutParams a = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        LinearLayout.LayoutParams b = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        b.leftMargin = Theme.dp(ctx, 8);
        row.addView(pauseBtn, a);
        row.addView(skipBtn, b);
        panel.addView(row, rlp);

        pauseBtn.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                if (listener != null) listener.onOverlayPause();
                bumpCollapse();
            }
        });
        skipBtn.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                if (listener != null) listener.onOverlaySkip();
                bumpCollapse();
            }
        });

        mainBtn = new TextView(ctx);
        mainBtn.setGravity(Gravity.CENTER);
        Theme.style(mainBtn, 14f, 0xFF07131A, true);
        mainBtn.setPadding(0, Theme.dp(ctx, 12), 0, Theme.dp(ctx, 12));
        LinearLayout.LayoutParams mlp = wide();
        mlp.topMargin = Theme.dp(ctx, 8);
        mainBtn.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                if (listener == null) return;
                if (mode == Mode.ARMED) listener.onOverlayStart();
                else listener.onOverlayStop();
                collapse();
            }
        });
        panel.addView(mainBtn, mlp);

        TextView hint = new TextView(ctx);
        Theme.style(hint, 9f, Theme.FAINT, false);
        hint.setGravity(Gravity.CENTER);
        hint.setText("long-press the pill to hide");
        LinearLayout.LayoutParams hlp = wide();
        hlp.topMargin = Theme.dp(ctx, 8);
        panel.addView(hint, hlp);

        return panel;
    }

    private TextView addStat() {
        TextView t = new TextView(ctx);
        Theme.style(t, 11f, Theme.MUTED, false);
        t.setPadding(0, Theme.dp(ctx, 5), 0, 0);
        panel.addView(t, wide());
        return t;
    }

    private TextView smallBtn(String text, int colour) {
        TextView t = new TextView(ctx);
        t.setText(text);
        t.setGravity(Gravity.CENTER);
        Theme.style(t, 11f, colour, true);
        t.setPadding(0, Theme.dp(ctx, 10), 0, Theme.dp(ctx, 10));
        t.setBackground(Theme.pressable(Theme.card(ctx, Theme.CARD_HI, 9)));
        return t;
    }

    private LinearLayout.LayoutParams wide() {
        return new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
    }

    private static int overlayType() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            return WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY;
        }
        return WindowManager.LayoutParams.TYPE_SYSTEM_ALERT;
    }

    // ----------------------------------------------------------------- state

    public void setMode(Mode m) {
        mode = m;
        if (m == Mode.ARMED) paused = false;
        post(new Runnable() { @Override public void run() { applyMode(); } });
    }

    public Mode mode() { return mode; }
    public boolean isShown() { return shown; }

    public void setPaused(boolean p) {
        paused = p;
        post(new Runnable() { @Override public void run() { applyMode(); } });
    }

    private void applyMode() {
        if (!shown || root == null) return;
        try {
            boolean armed = mode == Mode.ARMED;
            dot.setBackground(armed ? Theme.accentCircle(ctx)
                    : (paused ? Theme.solid(ctx, Theme.WARN, 99) : Theme.dangerCircle(ctx)));
            if (armed) pillText.setText("START");
            mainBtn.setText(armed ? "START" : "STOP");
            mainBtn.setBackground(Theme.pressable(
                    armed ? Theme.accent(ctx, 10) : Theme.solid(ctx, Theme.DANGER, 10)));
            pauseBtn.setText(paused ? "RESUME" : "PAUSE");
            pauseBtn.setTextColor(paused ? Theme.OK : Theme.WARN);
            pauseBtn.setBackground(Theme.pressable(Theme.card(ctx,
                    paused ? Theme.CARD_HI : Theme.CARD_HI, 9)));
            pauseBtn.setVisibility(armed ? View.GONE : View.VISIBLE);
            skipBtn.setVisibility(armed ? View.GONE : View.VISIBLE);
            title.setText(armed ? "READY" : (paused ? "PAUSED" : "BOOSTING"));
            dot.setAlpha(paused ? 0.55f : 1f);
        } catch (Throwable ignored) { }
    }

    /** Live figures pushed from the service each cycle. */
    public void updateStats(final String time, final int videos, final int matchedPct,
                            final int targetPct, final String screen, final String action,
                            final boolean nicheMatch, final String counts) {
        if (!shown || root == null) return;
        post(new Runnable() {
            @Override public void run() {
                try {
                    if (mode == Mode.RUNNING) {
                        pillText.setText(paused ? "PAUSED  " + time
                                                : time + "   " + matchedPct + "%");
                    }
                    timeText.setText(time);
                    statLine1.setText(videos + " videos  ·  " + matchedPct + "% niche"
                            + "  (target " + targetPct + "%)");
                    statLine1.setTextColor(matchedPct >= targetPct ? Theme.OK : Theme.MUTED);
                    statLine2.setText(screen.toLowerCase() + "  ·  " + action);
                    statLine2.setTextColor(nicheMatch ? Theme.ACCENT_A : Theme.MUTED);
                    statLine3.setText(counts);
                } catch (Throwable ignored) { }
            }
        });
    }

    private void post(Runnable r) {
        if (root != null) root.post(r); else h.post(r);
    }

    // -------------------------------------------------------------- expanding

    private void toggle() {
        if (expanded) collapse(); else expand();
    }

    private void expand() {
        if (!shown) return;
        expanded = true;
        panel.setVisibility(View.VISIBLE);
        bumpCollapse();
    }

    private void collapse() {
        if (!shown) return;
        expanded = false;
        panel.setVisibility(View.GONE);
        h.removeCallbacks(autoCollapse);
    }

    private final Runnable autoCollapse = new Runnable() {
        @Override public void run() {
            if (paused) { bumpCollapse(); return; }   // stay open while paused
            collapse();
        }
    };

    private void bumpCollapse() {
        h.removeCallbacks(autoCollapse);
        h.postDelayed(autoCollapse, AUTO_COLLAPSE_MS);
    }

    public void hide() {
        h.removeCallbacksAndMessages(null);
        if (!shown || root == null) return;
        try { wm.removeView(root); } catch (Throwable ignored) { }
        root = null;
        shown = false;
        expanded = false;
    }

    /** Drag to move, tap to open the panel, long-press to hide entirely. */
    private final class Dragger implements View.OnTouchListener {
        private static final long LONG_PRESS_MS = 650;
        private int startX, startY;
        private float touchX, touchY;
        private long downAt;
        private boolean moved;

        @Override public boolean onTouch(View v, MotionEvent e) {
            switch (e.getAction()) {
                case MotionEvent.ACTION_DOWN:
                    startX = lp.x; startY = lp.y;
                    touchX = e.getRawX(); touchY = e.getRawY();
                    downAt = System.currentTimeMillis();
                    moved = false;
                    v.setAlpha(0.7f);
                    return true;
                case MotionEvent.ACTION_MOVE:
                    int dx = (int) (e.getRawX() - touchX);
                    int dy = (int) (e.getRawY() - touchY);
                    if (Math.abs(dx) > Theme.dp(ctx, 6) || Math.abs(dy) > Theme.dp(ctx, 6)) {
                        moved = true;
                    }
                    lp.x = startX + dx;
                    lp.y = startY + dy;
                    try { wm.updateViewLayout(root, lp); } catch (Throwable ignored) { }
                    return true;
                case MotionEvent.ACTION_UP:
                case MotionEvent.ACTION_CANCEL:
                    v.setAlpha(1f);
                    if (moved || listener == null) return true;
                    if (System.currentTimeMillis() - downAt >= LONG_PRESS_MS) {
                        listener.onOverlayDismiss();
                    } else {
                        toggle();
                    }
                    return true;
            }
            return false;
        }
    }
}
