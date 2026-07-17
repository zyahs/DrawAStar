package com.jifeng.upapp;

import android.content.Context;
import android.content.SharedPreferences;

import java.util.Arrays;
import java.util.List;

final class JFThemeStore {
    static final class Theme {
        final String id;
        final String name;
        final String description;
        final int primary;
        final int secondary;
        final int accent;
        final int backgroundTop;
        final int backgroundBottom;

        Theme(String id, String name, String description,
              int primary, int secondary, int accent,
              int backgroundTop, int backgroundBottom) {
            this.id = id;
            this.name = name;
            this.description = description;
            this.primary = primary;
            this.secondary = secondary;
            this.accent = accent;
            this.backgroundTop = backgroundTop;
            this.backgroundBottom = backgroundBottom;
        }
    }

    private static final String PREFS = "jf_android_theme_v1";
    private static final String KEY_CURRENT = "current";

    private static final List<Theme> THEMES = Arrays.asList(
        theme("default", "星夜游乐场", "轻霓虹与星尘",
            0xff756bf2, 0xfff573c7, 0xff33d9c7, 0xff0f0f1f, 0xff1f0f38),
        theme("monster", "精灵冒险", "草地、能量球和伙伴感",
            0xff2eae5c, 0xffffc73d, 0xff338cff, 0xff0f2e1f, 0xff055738),
        theme("kitty", "蝴蝶结糖果屋", "奶油粉、蝴蝶结和软糖光泽",
            0xffff75a8, 0xffffd1e6, 0xfffa386b, 0xff2e1224, 0xff7a2647),
        theme("sunset", "落日电玩城", "暖橙霓虹与复古街机",
            0xffff735c, 0xffffb84c, 0xffff619e, 0xff2e1429, 0xff85291a),
        theme("ocean", "深海水族馆", "蓝绿流光与夜潜海面",
            0xff338cea, 0xff40c7eb, 0xff4de09e, 0xff051a33, 0xff08475c),
        theme("forest", "森林露营", "树影、萤火与自然绿",
            0xff33b37f, 0xff73d966, 0xfff2d959, 0xff0a1f14, 0xff144724),
        theme("sakura", "樱花祭", "粉白纸灯与轻甜花瓣",
            0xfff58cc7, 0xffffc7d9, 0xff9e73f2, 0xff291424, 0xff612e4d),
        theme("midnight", "赛博夜跑", "黑紫底、青粉光轨",
            0xff522e8c, 0xfff2339e, 0xff33f2bf, 0xff050512, 0xff290d38),
        theme("gold", "皇室剧场", "金色幕布与奖章质感",
            0xffd9a633, 0xfff2d966, 0xffa64033, 0xff1f140a, 0xff573814),
        theme("porcelain", "青花月影", "钴蓝纹样与朱砂点睛",
            0xff144da3, 0xffe02e3d, 0xffb3e0ff, 0xff05142e, 0xff0a3d6b),
        theme("celestial", "星穹鎏光", "深空蓝、香槟金与流星",
            0xff1f57b8, 0xff9e4dd1, 0xfff5c75c, 0xff03081a, 0xff0d1f4d),
        theme("noir", "黑曜玫瑰", "黑曜石、酒红与银色暗纹",
            0xff1a1a21, 0xffa8143d, 0xffd1d6e5, 0xff040407, 0xff290612),
        theme("prism", "棱镜幻城", "冰青、莓红与柠檬金",
            0xff1ac7d6, 0xffeb3385, 0xfff5d63d, 0xff06141f, 0xff2e0f47),
        theme("custom", "自定义工坊", "中性材质与资料背景",
            0xff737380, 0xffa6a6b3, 0xffd9d9eb, 0xff12141a, 0xff333847)
    );

    private static Theme theme(String id, String name, String description,
                               int primary, int secondary, int accent,
                               int backgroundTop, int backgroundBottom) {
        return new Theme(id, name, description, primary, secondary, accent, backgroundTop, backgroundBottom);
    }

    static List<Theme> all() {
        return THEMES;
    }

    static Theme current(Context context) {
        String id = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_CURRENT, "default");
        return byId(id);
    }

    static Theme byId(String id) {
        for (Theme theme : THEMES) {
            if (theme.id.equals(id)) return theme;
        }
        return THEMES.get(0);
    }

    static void apply(Context context, String themeId) {
        Theme theme = byId(themeId);
        SharedPreferences preferences = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        preferences.edit().putString(KEY_CURRENT, theme.id).apply();
        JFTheme.apply(context);
        if (JFAppIconManager.followsTheme(context)) {
            JFAppIconManager.applyIcon(context, theme.id);
        }
    }

    private JFThemeStore() {}
}
