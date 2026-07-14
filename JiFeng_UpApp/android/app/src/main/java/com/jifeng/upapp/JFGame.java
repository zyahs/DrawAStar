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
            new JFGame("DRAW_BOARD", "画板", "黑底绘画与相册背景", 0xff2dd4bf, 0xff111827),
            new JFGame("TRUTH_OR_DARE", "真心话大冒险", "3 秒混合选择", 0xffff4d8d, 0xff7c3aed),
            new JFGame("DICE", "骰子", "聚会快速随机", 0xfff59e0b, 0xffef4444),
            new JFGame("FIVE_IN_ROW", "五子棋", "横屏棋盘", 0xff38bdf8, 0xff2563eb),
            new JFGame("UNDERCOVER", "谁是卧底", "身份词卡", 0xffa78bfa, 0xff4338ca),
            new JFGame("KING", "国王游戏", "抽签惩罚", 0xfff97316, 0xffdb2777),
            new JFGame("CARD", "卡牌", "卡牌预览与抽取", 0xff22c55e, 0xff15803d),
            new JFGame("GESTURE", "手势炸弹", "反应惩罚", 0xffef4444, 0xff7f1d1d),
            new JFGame("PUZZLE", "拼图", "数字滑块", 0xff06b6d4, 0xff0f766e),
            new JFGame("SNAKE", "贪吃蛇", "方向控制", 0xff84cc16, 0xff166534),
            new JFGame("GAME_2048", "2048", "合成数字", 0xfffacc15, 0xffa16207),
            new JFGame("SUDOKU", "数独", "逻辑填数", 0xff60a5fa, 0xff1d4ed8),
            new JFGame("MEMORY", "记忆翻牌", "匹配卡片", 0xffc084fc, 0xff86198f),
            new JFGame("REACTION", "反应力", "等待绿灯", 0xff34d399, 0xff065f46),
            new JFGame("RHYTHM", "节奏", "跟随节拍", 0xfffb7185, 0xffbe123c),
        };
    }
}
