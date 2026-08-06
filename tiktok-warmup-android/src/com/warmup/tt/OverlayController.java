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
 * Messenger-style floating bubble.
 *
 * A round chat-head you can fling around. It snaps to whichever edge is nearer, and
 * dragging it reveals a dismiss target at the bottom of the screen - drop it there and
 * the bubble goes away, exactly like closing a Messenger head. Tapping opens a control
 * panel beside it.
 *
 * Uses TYPE_ACCESSIBILITY_OVERLAY, which an accessibility service may add without the
 * "display over other apps" permission, so there is no extra prompt to grant.
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
    private static final int BUBBLE_DP = 58;
    private static final int DISMISS_DP = 68;

    private final Context ctx;
    private final Listener listener;
    private final Handler h = new Handler(Looper.getMainLooper());

    private WindowManager wm;
    private WindowManager.LayoutParams lp, dismissLp;
    private LinearLayout root;

    private TextView bubble;
    private View dismissView;

    private LinearLayout panel;
    private TextView title, timeText, statLine1, statLine2, statLine3;
    private TextView pauseBtn, skipBtn, mainBtn;

    private Mode mode = Mode.ARMED;
    private boolean shown = false, expanded = false, paused = false, dragging = false;
    private int screenW, screenH;

    public OverlayController(Context ctx, Listener listener) {
        this.ctx = ctx;
        this.listener = listener;
    }

    // ------------------------------------------------------------------ show

    public void show() {
        if (shown) return;
        try {
            wm = (WindowManager) ctx.getSystemService(Context.WINDOW_SERVICE);
            screenW = ctx.getResources().getDisplayMetrics().widthPixels;
            screenH = ctx.getResources().getDisplayMetrics().heightPixels;

            root = new LinearLayout(ctx);
            root.setOrientation(LinearLayout.VERTICAL);
            root.addView(buildBubble());
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
            lp.x = Theme.dp(ctx, 10);
            lp.y = (int) (screenH * 0.45);

            wm.addView(root, lp);
            shown = true;
            applyMode();
        } catch (Throwable t) {
            shown = false;
        }
    }

    private TextView buildBubble() {
        bubble = new TextView(ctx);
        bubble.setGravity(Gravity.CENTER);
        Theme.style(bubble, 16f, 0xFF07131A, true);
        bubble.setText("▶");
        bubble.setBackground(Theme.accentCircle(ctx));
        int d = Theme.dp(ctx, BUBBLE_DP);
        bubble.setLayoutParams(new LinearLayout.LayoutParams(d, d));
        bubble.setElevation(Theme.dp(ctx, 8));
        bubble.setOnTouchListener(new Dragger());
        return bubble;
    }

    private LinearLayout buildPanel() {
        panel = new LinearLayout(ctx);
        panel.setOrientation(LinearLayout.VERTICAL);
        int q = Theme.dp(ctx, 14);
        panel.setPadding(q, q, q, q);
        panel.setBackground(Theme.card(ctx, Theme.fade(Theme.CARD, 0xF7), 16));
        LinearLayout.LayoutParams plp = new LinearLayout.LayoutParams(
                Theme.dp(ctx, 210), ViewGroup.LayoutParams.WRAP_CONTENT);
        plp.topMargin = Theme.dp(ctx, 8);
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
        hint.setText("drag the bubble down to close");
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

    // ------------------------------------------------------- dismiss target

    private void showDismiss() {
        if (dismissView != null) return;
        try {
            TextView x = new TextView(ctx);
            x.setText("✕");
            x.setGravity(Gravity.CENTER);
            Theme.style(x, 22f, 0xFFFFFFFF, true);
            x.setBackground(Theme.solid(ctx, Theme.fade(Theme.DANGER, 0xDD), 999));
            int d = Theme.dp(ctx, DISMISS_DP);

            dismissLp = new WindowManager.LayoutParams(d, d, overlayType(),
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                            | WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
                            | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                    PixelFormat.TRANSLUCENT);
            dismissLp.gravity = Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL;
            dismissLp.y = Theme.dp(ctx, 80);
            wm.addView(x, dismissLp);
            dismissView = x;
        } catch (Throwable ignored) { }
    }

    private void hideDismiss() {
        if (dismissView == null) return;
        try { wm.removeView(dismissView); } catch (Throwable ignored) { }
        dismissView = null;
    }

    /** Screen-space centre of the dismiss target. */
    private int dismissCx() { return screenW / 2; }
    private int dismissCy() {
        return screenH - Theme.dp(ctx, 80) - Theme.dp(ctx, DISMISS_DP) / 2;
    }

    private boolean overDismiss() {
        int bx = lp.x + Theme.dp(ctx, BUBBLE_DP) / 2;
        int by = lp.y + Theme.dp(ctx, BUBBLE_DP) / 2;
        int dx = bx - dismissCx(), dy = by - dismissCy();
        return Math.sqrt(dx * dx + dy * dy) < Theme.dp(ctx, 90);
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
            bubble.setBackground(armed ? Theme.accentCircle(ctx)
                    : (paused ? Theme.solid(ctx, Theme.WARN, 999)
                              : Theme.dangerCircle(ctx)));
            if (armed) bubble.setText("▶");
            else if (paused) bubble.setText("❚❚");

            mainBtn.setText(armed ? "START" : "STOP");
            mainBtn.setBackground(Theme.pressable(
                    armed ? Theme.accent(ctx, 10) : Theme.solid(ctx, Theme.DANGER, 10)));
            pauseBtn.setText(paused ? "RESUME" : "PAUSE");
            pauseBtn.setTextColor(paused ? Theme.OK : Theme.WARN);
            pauseBtn.setVisibility(armed ? View.GONE : View.VISIBLE);
            skipBtn.setVisibility(armed ? View.GONE : View.VISIBLE);
            title.setText(armed ? "READY" : (paused ? "PAUSED" : "BOOSTING"));
        } catch (Throwable ignored) { }
    }

    public void updateStats(final String time, final int videos, final int matchedPct,
                            final int targetPct, final String screen, final String action,
                            final boolean nicheMatch, final String counts,
                            final boolean scoreReady) {
        if (!shown || root == null) return;
        post(new Runnable() {
            @Override public void run() {
                try {
                    if (mode == Mode.RUNNING && !paused) {
                        // Minutes left, so the bubble stays legible at this size.
                        int colon = time.indexOf(':');
                        bubble.setText(colon > 0 ? time.substring(0, colon) : time);
                    }
                    timeText.setText(time);
                    statLine1.setText(videos + " videos  ·  "
                            + (scoreReady ? matchedPct + "% niche" : "scoring…")
                            + "  (target " + targetPct + "%)");
                    statLine1.setTextColor(scoreReady && matchedPct >= targetPct
                            ? Theme.OK : Theme.MUTED);
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

    private void toggle() { if (expanded) collapse(); else expand(); }

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
            if (paused) { bumpCollapse(); return; }
            collapse();
        }
    };

    private void bumpCollapse() {
        h.removeCallbacks(autoCollapse);
        h.postDelayed(autoCollapse, AUTO_COLLAPSE_MS);
    }

    public void hide() {
        h.removeCallbacksAndMessages(null);
        hideDismiss();
        if (!shown || root == null) return;
        try { wm.removeView(root); } catch (Throwable ignored) { }
        root = null;
        shown = false;
        expanded = false;
    }

    /** Drag to move, drop on the ✕ to close, tap to open the panel. */
    private final class Dragger implements View.OnTouchListener {
        private int startX, startY;
        private float touchX, touchY;
        private boolean moved;

        @Override public boolean onTouch(View v, MotionEvent e) {
            switch (e.getAction()) {
                case MotionEvent.ACTION_DOWN:
                    startX = lp.x; startY = lp.y;
                    touchX = e.getRawX(); touchY = e.getRawY();
                    moved = false;
                    v.animate().scaleX(0.9f).scaleY(0.9f).setDuration(90).start();
                    return true;

                case MotionEvent.ACTION_MOVE:
                    int dx = (int) (e.getRawX() - touchX);
                    int dy = (int) (e.getRawY() - touchY);
                    if (!moved && (Math.abs(dx) > Theme.dp(ctx, 8)
                                || Math.abs(dy) > Theme.dp(ctx, 8))) {
                        moved = true;
                        dragging = true;
                        collapse();
                        showDismiss();
                    }
                    lp.x = startX + dx;
                    lp.y = startY + dy;
                    try { wm.updateViewLayout(root, lp); } catch (Throwable ignored) { }
                    if (dragging && dismissView != null) {
                        boolean near = overDismiss();
                        dismissView.setScaleX(near ? 1.25f : 1f);
                        dismissView.setScaleY(near ? 1.25f : 1f);
                        v.setAlpha(near ? 0.45f : 1f);
                    }
                    return true;

                case MotionEvent.ACTION_UP:
                case MotionEvent.ACTION_CANCEL:
                    v.animate().scaleX(1f).scaleY(1f).setDuration(90).start();
                    v.setAlpha(1f);
                    if (dragging && overDismiss()) {
                        hideDismiss();
                        dragging = false;
                        if (listener != null) listener.onOverlayDismiss();
                        return true;
                    }
                    hideDismiss();
                    dragging = false;
                    if (moved) { snapToEdge(); return true; }
                    toggle();
                    return true;
            }
            return false;
        }
    }

    /** Settle against whichever side is closer, like a chat head. */
    private void snapToEdge() {
        try {
            int size = Theme.dp(ctx, BUBBLE_DP);
            int margin = Theme.dp(ctx, 10);
            int centre = lp.x + size / 2;
            lp.x = centre < screenW / 2 ? margin : screenW - size - margin;
            if (lp.y < Theme.dp(ctx, 40)) lp.y = Theme.dp(ctx, 40);
            if (lp.y > screenH - size - Theme.dp(ctx, 60)) {
                lp.y = screenH - size - Theme.dp(ctx, 60);
            }
            wm.updateViewLayout(root, lp);
        } catch (Throwable ignored) { }
    }
}
