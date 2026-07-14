package com.jifeng.upapp;

import android.content.Context;
import android.graphics.drawable.GradientDrawable;
import android.view.View;
import android.widget.TextView;

final class JFTheme {
    static final int BG = 0xff0b1020;
    static final int CARD = 0x2affffff;
    static final int CARD_SOLID = 0xff151b2d;
    static final int TEXT = 0xffffffff;
    static final int SUBTEXT = 0xffaeb7cc;
    static final int ACCENT = 0xff7cffb2;
    static final int WARNING = 0xffffd166;

    static int dp(Context c, int value) {
        return Math.round(value * c.getResources().getDisplayMetrics().density);
    }

    static GradientDrawable bg() {
        return gradient(0xff111827, 0xff0b1020, 0xff201033, 0);
    }

    static GradientDrawable gradient(int top, int middle, int bottom, int radius) {
        GradientDrawable g = new GradientDrawable(GradientDrawable.Orientation.TL_BR, new int[] { top, middle, bottom });
        g.setCornerRadius(radius);
        return g;
    }

    static GradientDrawable card(Context c, int color) {
        GradientDrawable d = new GradientDrawable();
        d.setColor(color);
        d.setCornerRadius(dp(c, 18));
        d.setStroke(dp(c, 1), 0x22ffffff);
        return d;
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
}
