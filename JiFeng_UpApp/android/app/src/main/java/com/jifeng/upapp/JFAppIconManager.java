package com.jifeng.upapp;

import android.content.ComponentName;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;

import java.util.LinkedHashMap;
import java.util.Map;

final class JFAppIconManager {
    private static final String PREFS = "jf_android_app_icon_v1";
    private static final String KEY_FOLLOWS = "follows_theme";
    private static final String KEY_ICON_SKIN = "icon_skin";

    private static final Map<String, String> ALIASES = new LinkedHashMap<>();
    static {
        ALIASES.put("default", "MainActivityDefault");
        ALIASES.put("monster", "MainActivityAdventure");
        ALIASES.put("kitty", "MainActivityCandy");
        ALIASES.put("sunset", "MainActivitySunset");
        ALIASES.put("ocean", "MainActivityOcean");
        ALIASES.put("forest", "MainActivityForest");
        ALIASES.put("sakura", "MainActivitySakura");
        ALIASES.put("midnight", "MainActivityCyber");
        ALIASES.put("gold", "MainActivityRoyal");
        ALIASES.put("porcelain", "MainActivityPorcelain");
        ALIASES.put("celestial", "MainActivityCelestial");
        ALIASES.put("noir", "MainActivityNoir");
        ALIASES.put("prism", "MainActivityPrism");
        ALIASES.put("custom", "MainActivityAtelier");
    }

    static boolean followsTheme(Context context) {
        SharedPreferences preferences = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        return !preferences.contains(KEY_FOLLOWS) || preferences.getBoolean(KEY_FOLLOWS, true);
    }

    static void setFollowsTheme(Context context, boolean follows) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putBoolean(KEY_FOLLOWS, follows).apply();
        if (follows) applyIcon(context, JFThemeStore.current(context).id);
    }

    static String currentIconSkinId(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_ICON_SKIN, "default");
    }

    static void selectManualIcon(Context context, String themeId) {
        setFollowsTheme(context, false);
        applyIcon(context, themeId);
    }

    static void applyIcon(Context context, String themeId) {
        if (!ALIASES.containsKey(themeId)) themeId = "default";
        String current = currentIconSkinId(context);
        if (themeId.equals(current)) return;

        PackageManager packageManager = context.getPackageManager();
        ComponentName next = component(context, ALIASES.get(themeId));
        packageManager.setComponentEnabledSetting(
            next,
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP
        );

        String currentAlias = ALIASES.get(current);
        if (currentAlias == null) currentAlias = ALIASES.get("default");
        packageManager.setComponentEnabledSetting(
            component(context, currentAlias),
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP
        );

        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(KEY_ICON_SKIN, themeId).apply();
    }

    private static ComponentName component(Context context, String alias) {
        return new ComponentName(context.getPackageName(), context.getPackageName() + "." + alias);
    }

    private JFAppIconManager() {}
}
