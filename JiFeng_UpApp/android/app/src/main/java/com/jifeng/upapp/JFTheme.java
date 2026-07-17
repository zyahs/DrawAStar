package com.jifeng.upapp;

import android.content.Context;
import android.graphics.drawable.GradientDrawable;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

final class JFTheme {
    static int BG = 0xff0b1020;
    static final int CARD = 0x2affffff;
    static int CARD_SOLID = 0xff151b2d;
    static final int TEXT = 0xffffffff;
    static final int SUBTEXT = 0xffaeb7cc;
    static int PRIMARY = 0xff756bf2;
    static int SECONDARY = 0xfff573c7;
    static int ACCENT = 0xff33d9c7;
    static int WARNING = 0xffffd166;
    private static int backgroundTop = 0xff0f0f1f;
    private static int backgroundBottom = 0xff1f0f38;

    static void apply(Context context) {
        JFThemeStore.Theme theme = JFThemeStore.current(context);
        PRIMARY = theme.primary;
        SECONDARY = theme.secondary;
        ACCENT = theme.accent;
        backgroundTop = theme.backgroundTop;
        backgroundBottom = theme.backgroundBottom;
        BG = theme.backgroundTop;
        CARD_SOLID = blend(theme.backgroundTop, 0xffffffff, 0.08f);
    }

    static int dp(Context c, int value) {
        return Math.round(value * c.getResources().getDisplayMetrics().density);
    }

    static GradientDrawable bg() {
        return gradient(backgroundTop, blend(backgroundTop, PRIMARY, 0.22f), backgroundBottom, 0);
    }

    static GradientDrawable gradient(int top, int middle, int bottom, int radius) {
        GradientDrawable g = new GradientDrawable(GradientDrawable.Orientation.TL_BR, new int[] { top, middle, bottom });
        g.setCornerRadius(radius);
        return g;
    }

    static GradientDrawable card(Context c, int color) {
        GradientDrawable d = new GradientDrawable();
        d.setColor(color);
        d.setCornerRadius(dp(c, 8));
        d.setStroke(dp(c, 1), 0x22ffffff);
        return d;
    }

    static GradientDrawable outlined(Context c, int fill, int stroke) {
        GradientDrawable d = new GradientDrawable();
        d.setColor(fill);
        d.setCornerRadius(dp(c, 8));
        d.setStroke(dp(c, 1), stroke);
        return d;
    }

    static Button primaryButton(Context context, String text) {
        Button button = new Button(context);
        button.setText(text);
        button.setTextSize(15);
        button.setTypeface(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD);
        button.setTextColor(TEXT);
        button.setAllCaps(false);
        button.setBackground(outlined(context, PRIMARY, blend(PRIMARY, 0xffffffff, 0.22f)));
        return button;
    }

    static Button secondaryButton(Context context, String text) {
        Button button = new Button(context);
        button.setText(text);
        button.setTextSize(14);
        button.setTypeface(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD);
        button.setTextColor(ACCENT);
        button.setAllCaps(false);
        button.setBackground(outlined(context, 0x18ffffff, 0x33ffffff));
        return button;
    }

    static TextView label(Context c, String text, float sp, int color, int style) {
        TextView v = new TextView(c);
        v.setText(text);
        v.setTextSize(sp);
        v.setTextColor(color);
        v.setTypeface(android.graphics.Typeface.DEFAULT, style);
        return v;
    }

    static void pad(View v, int l, int t, int r, int b) {
        Context c = v.getContext();
        v.setPadding(dp(c, l), dp(c, t), dp(c, r), dp(c, b));
    }

    static int blend(int from, int to, float amount) {
        amount = Math.max(0f, Math.min(1f, amount));
        int a = Math.round(((from >>> 24) & 0xff) * (1f - amount) + ((to >>> 24) & 0xff) * amount);
        int r = Math.round(((from >>> 16) & 0xff) * (1f - amount) + ((to >>> 16) & 0xff) * amount);
        int g = Math.round(((from >>> 8) & 0xff) * (1f - amount) + ((to >>> 8) & 0xff) * amount);
        int b = Math.round((from & 0xff) * (1f - amount) + (to & 0xff) * amount);
        return (a << 24) | (r << 16) | (g << 8) | b;
    }
}
