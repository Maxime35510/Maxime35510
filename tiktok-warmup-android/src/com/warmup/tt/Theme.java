package com.warmup.tt;

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.RippleDrawable;
import android.graphics.drawable.Drawable;
import android.content.res.ColorStateList;
import android.os.Build;
import android.util.TypedValue;
import android.widget.TextView;

/**
 * Hand-rolled dark theme. The app is framework-only - no AndroidX, no Material - so
 * the visual language is built out of GradientDrawable rather than pulled from a
 * component library. Keeps the build to a single build.sh with no Maven resolution.
 */
public final class Theme {

    public static final int BG        = 0xFF0B0D12;
    public static final int CARD      = 0xFF161A23;
    public static final int CARD_HI   = 0xFF1E2430;
    public static final int STROKE    = 0xFF2A3240;
    public static final int TEXT      = 0xFFE8ECF4;
    public static final int MUTED     = 0xFF8A93A6;
    public static final int FAINT     = 0xFF5C6579;

    public static final int ACCENT_A  = 0xFF37D9C4;
    public static final int ACCENT_B  = 0xFF7C5CFF;
    public static final int OK        = 0xFF3DDC97;
    public static final int WARN      = 0xFFFFB020;
    public static final int DANGER    = 0xFFFF5470;

    public static int dp(Context c, float v) {
        return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v,
                c.getResources().getDisplayMetrics());
    }

    public static GradientDrawable card(Context c, int fill, float radiusDp) {
        GradientDrawable g = new GradientDrawable();
        g.setColor(fill);
        g.setCornerRadius(dp(c, radiusDp));
        g.setStroke(dp(c, 1), STROKE);
        return g;
    }

    public static GradientDrawable solid(Context c, int fill, float radiusDp) {
        GradientDrawable g = new GradientDrawable();
        g.setColor(fill);
        g.setCornerRadius(dp(c, radiusDp));
        return g;
    }

    public static GradientDrawable accent(Context c, float radiusDp) {
        GradientDrawable g = new GradientDrawable(
                GradientDrawable.Orientation.LEFT_RIGHT,
                new int[]{ ACCENT_A, ACCENT_B });
        g.setCornerRadius(dp(c, radiusDp));
        return g;
    }

    public static GradientDrawable accentCircle(Context c) {
        GradientDrawable g = new GradientDrawable(
                GradientDrawable.Orientation.TL_BR,
                new int[]{ ACCENT_A, ACCENT_B });
        g.setShape(GradientDrawable.OVAL);
        return g;
    }

    public static GradientDrawable dangerCircle(Context c) {
        GradientDrawable g = new GradientDrawable(
                GradientDrawable.Orientation.TL_BR,
                new int[]{ 0xFFFF7A5C, DANGER });
        g.setShape(GradientDrawable.OVAL);
        return g;
    }

    /** Wraps a drawable in a ripple where the platform supports it. */
    public static Drawable pressable(Drawable base) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            return new RippleDrawable(
                    ColorStateList.valueOf(0x33FFFFFF), base, null);
        }
        return base;
    }

    public static void style(TextView tv, float sizeSp, int color, boolean bold) {
        tv.setTextSize(sizeSp);
        tv.setTextColor(color);
        if (bold) tv.setTypeface(tv.getTypeface(), android.graphics.Typeface.BOLD);
    }

    public static int fade(int color, int alpha) {
        return (color & 0x00FFFFFF) | ((alpha & 0xFF) << 24);
    }

    private Theme() { }
}
