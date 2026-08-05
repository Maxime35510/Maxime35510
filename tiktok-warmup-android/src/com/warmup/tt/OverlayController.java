package com.warmup.tt;

import android.content.Context;
import android.graphics.PixelFormat;
import android.os.Build;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.widget.LinearLayout;
import android.widget.TextView;

/**
 * Always-on-top stop control.
 *
 * Uses TYPE_ACCESSIBILITY_OVERLAY, which an accessibility service may add without the
 * "display over other apps" permission - so there is no extra prompt to grant.
 *
 * Parked on the LEFT edge at mid height on purpose: the bot's own targets are the
 * right-hand rail (x > 0.78W), the screen centre and the bottom nav, so it can never
 * tap its own stop button.
 */
public final class OverlayController {

    public interface OnStop { void stop(); }

    private final Context ctx;
    private final OnStop onStop;
    private WindowManager wm;
    private View root;
    private TextView label;
    private View dot;
    private WindowManager.LayoutParams lp;
    private boolean shown = false;

    public OverlayController(Context ctx, OnStop onStop) {
        this.ctx = ctx;
        this.onStop = onStop;
    }

    public void show() {
        if (shown) return;
        try {
            wm = (WindowManager) ctx.getSystemService(Context.WINDOW_SERVICE);

            LinearLayout row = new LinearLayout(ctx);
            row.setOrientation(LinearLayout.HORIZONTAL);
            row.setGravity(Gravity.CENTER_VERTICAL);
            int padH = Theme.dp(ctx, 12), padV = Theme.dp(ctx, 9);
            row.setPadding(padH, padV, padH, padV);
            row.setBackground(Theme.solid(ctx, Theme.fade(Theme.BG, 0xE0), 22));

            dot = new View(ctx);
            dot.setBackground(Theme.accentCircle(ctx));
            LinearLayout.LayoutParams dlp = new LinearLayout.LayoutParams(
                    Theme.dp(ctx, 10), Theme.dp(ctx, 10));
            dlp.rightMargin = Theme.dp(ctx, 8);
            row.addView(dot, dlp);

            label = new TextView(ctx);
            Theme.style(label, 12f, Theme.TEXT, true);
            label.setText("STOP");
            row.addView(label);

            lp = new WindowManager.LayoutParams(
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    overlayType(),
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                            | WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
                            | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                    PixelFormat.TRANSLUCENT);
            lp.gravity = Gravity.TOP | Gravity.START;
            lp.x = Theme.dp(ctx, 6);
            lp.y = ctx.getResources().getDisplayMetrics().heightPixels / 2;

            row.setOnTouchListener(new Dragger());
            wm.addView(row, lp);
            root = row;
            shown = true;
        } catch (Throwable t) {
            shown = false;
        }
    }

    private static int overlayType() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            return WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY;
        }
        return WindowManager.LayoutParams.TYPE_SYSTEM_ALERT;
    }

    public void update(final String text, final boolean paused) {
        if (!shown || root == null) return;
        root.post(new Runnable() {
            @Override public void run() {
                try {
                    label.setText(text);
                    dot.setBackground(paused ? Theme.dangerCircle(ctx)
                                             : Theme.accentCircle(ctx));
                } catch (Throwable ignored) { }
            }
        });
    }

    public void hide() {
        if (!shown || root == null) return;
        try { wm.removeView(root); } catch (Throwable ignored) { }
        root = null;
        shown = false;
    }

    public boolean isShown() { return shown; }

    /** Drag to reposition; a tap without meaningful movement stops the session. */
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
                    v.setAlpha(0.75f);
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
                    if (!moved && onStop != null) onStop.stop();
                    return true;
            }
            return false;
        }
    }
}
