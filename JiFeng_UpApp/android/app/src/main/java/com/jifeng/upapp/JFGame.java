package com.jifeng.upapp;

final class JFGame {
    final String kind;
    final String title;
    final String subtitle;
    final int colorA;
    final int colorB;

    JFGame(String kind, String title, String subtitle, int colorA, int colorB) {
        this.kind = kind;
        this.title = title;
        this.subtitle = subtitle;
        this.colorA = colorA;
        this.colorB = colorB;
    }

    static JFGame[] all() {
        return new JFGame[] {
            new JFGame("DRAW_BOARD", "画板", "自由作画", 0xff2dd4bf, 0xff111827),
            new JFGame("RECOMMENDED_SOCIAL", "推荐游戏", "14 种社交玩法 · 完整规则", 0xff24c9a5, 0xff2864d7),
            new JFGame("TRUTH_OR_DARE", "真心话大冒险", "双色球抽签", 0xffff4d8d, 0xff7c3aed),
            new JFGame("NEVER_HAVE_I_EVER", "我有你没有", "实时房间 · 全员投票", 0xffffa94d, 0xffe44572),
            new JFGame("RHYTHM", "节奏大师", "横屏音轨 · 长按滑动", 0xfffb7185, 0xffbe123c),
            new JFGame("DICE", "骰子游乐场", "14 种玩法 · 支持联机", 0xfff59e0b, 0xffef4444),
            new JFGame("FIVE_IN_ROW", "五子棋", "双人对弈", 0xff38bdf8, 0xff2563eb),
            new JFGame("UNDERCOVER", "谁是卧底", "联机 · 找卧底", 0xffa78bfa, 0xff4338ca),
            new JFGame("KING", "国王游戏", "联机 · 抽 K 牌", 0xfff97316, 0xffdb2777),
            new JFGame("CARD", "纸牌游乐场", "10 种派对与经典玩法", 0xff22c55e, 0xff15803d),
            new JFGame("GESTURE", "手势炸弹", "快手反应", 0xffef4444, 0xff7f1d1d),
            new JFGame("PUZZLE", "拼图", "相册照片 · 三档难度", 0xff06b6d4, 0xff0f766e),
            new JFGame("SNAKE", "贪吃蛇", "经典单机", 0xff84cc16, 0xff166534),
            new JFGame("GAME_2048", "2048", "滑动合并 · 冲击高分", 0xfffacc15, 0xffa16207),
            new JFGame("SUDOKU", "数独", "九宫格 · 三档", 0xff60a5fa, 0xff1d4ed8),
            new JFGame("MEMORY", "记忆翻牌", "找对子 · 三档难度", 0xffc084fc, 0xff86198f),
            new JFGame("REACTION", "反应力测试", "30 秒挑战手速", 0xff34d399, 0xff065f46),
        };
    }
}
