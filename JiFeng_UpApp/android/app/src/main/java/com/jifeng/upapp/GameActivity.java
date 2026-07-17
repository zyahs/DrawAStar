package com.jifeng.upapp;

import android.app.Activity;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Typeface;
import android.os.Bundle;
import android.os.Handler;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.widget.Button;
import android.widget.GridLayout;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Random;

public class GameActivity extends Activity {
    private final Random random = new Random();
    private String kind;
    private String title;
    private LinearLayout root;
    private String onlineRoomId;
    private int onlineLatestSeq;

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        JFTheme.apply(this);
        kind = getIntent().getStringExtra("kind");
        title = getIntent().getStringExtra("title");
        if (title == null) title = "小游戏";

        root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setGravity(Gravity.CENTER_HORIZONTAL);
        root.setBackground(JFTheme.bg());
        JFTheme.pad(root, 20, 18, 20, 20);
        setContentView(root);

        Button back = new Button(this);
        back.setText("返回");
        back.setAllCaps(false);
        back.setOnClickListener(v -> finish());
        root.addView(back, new LinearLayout.LayoutParams(-1, JFTheme.dp(this, 44)));

        TextView h = JFTheme.label(this, title, 28, JFTheme.TEXT, Typeface.BOLD);
        LinearLayout.LayoutParams hp = new LinearLayout.LayoutParams(-1, -2);
        hp.topMargin = JFTheme.dp(this, 12);
        root.addView(h, hp);

        if ("UNDERCOVER".equals(kind) || "KING".equals(kind)) {
            addOnlinePanel();
        }

        if ("DRAW_BOARD".equals(kind)) showDrawBoard();
        else if ("TRUTH_OR_DARE".equals(kind)) showTruthOrDare();
        else if ("DICE".equals(kind)) showDice();
        else if ("FIVE_IN_ROW".equals(kind)) showFiveInRow();
        else if ("UNDERCOVER".equals(kind)) showUndercover();
        else if ("KING".equals(kind)) showKingGame();
        else if ("CARD".equals(kind)) showCardGame();
        else if ("GESTURE".equals(kind)) showGestureBomb();
        else if ("PUZZLE".equals(kind)) showPuzzle();
        else if ("SNAKE".equals(kind)) showSnake();
        else if ("SUDOKU".equals(kind)) showSudoku();
        else if ("REACTION".equals(kind)) showReaction();
        else if ("MEMORY".equals(kind)) showMemory();
        else if ("GAME_2048".equals(kind)) show2048();
        else if ("RHYTHM".equals(kind)) showRhythm();
        else showScorePlaceholder();
    }

    private void showDrawBoard() {
        TextView desc = JFTheme.label(this, "黑色画布，手指拖动绘制。相册背景后续接 Android Photo Picker。", 14, JFTheme.SUBTEXT, Typeface.NORMAL);
        root.addView(desc);
        DrawView draw = new DrawView(this);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-1, 0, 1);
        lp.topMargin = JFTheme.dp(this, 12);
        root.addView(draw, lp);
    }

    private void addOnlinePanel() {
        LinearLayout panel = new LinearLayout(this);
        panel.setOrientation(LinearLayout.VERTICAL);
        panel.setBackground(JFTheme.card(this, 0x2affffff));
        JFTheme.pad(panel, 12, 10, 12, 10);
        LinearLayout.LayoutParams pp = new LinearLayout.LayoutParams(-1, -2);
        pp.topMargin = JFTheme.dp(this, 10);
        pp.bottomMargin = JFTheme.dp(this, 10);
        root.addView(panel, pp);

        TextView status = JFTheme.label(this, "跨端联机：创建房间或输入 iOS 房间号加入", 13, JFTheme.SUBTEXT, Typeface.BOLD);
        panel.addView(status);

        android.widget.EditText roomInput = new android.widget.EditText(this);
        roomInput.setHint("房间号");
        roomInput.setSingleLine(true);
        roomInput.setTextColor(JFTheme.TEXT);
        roomInput.setHintTextColor(JFTheme.SUBTEXT);
        panel.addView(roomInput, new LinearLayout.LayoutParams(-1, JFTheme.dp(this, 46)));

        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        panel.addView(row);
        Button create = smallButton("创建");
        Button join = smallButton("加入");
        Button send = smallButton("发消息");
        Button poll = smallButton("刷新");
        row.addView(create, new LinearLayout.LayoutParams(0, JFTheme.dp(this, 42), 1));
        row.addView(join, new LinearLayout.LayoutParams(0, JFTheme.dp(this, 42), 1));
        row.addView(send, new LinearLayout.LayoutParams(0, JFTheme.dp(this, 42), 1));
        row.addView(poll, new LinearLayout.LayoutParams(0, JFTheme.dp(this, 42), 1));

        create.setOnClickListener(v -> {
            try {
                JSONObject body = new JSONObject();
                body.put("kind", kind);
                body.put("displayName", android.os.Build.MODEL);
                JFApiClient.post("/multiplayer/rooms", body, (json, error) -> runOnUiThread(() -> {
                    if (json == null) {
                        status.setText("创建失败");
                        return;
                    }
                    onlineRoomId = json.optString("roomId");
                    onlineLatestSeq = json.optInt("latestSeq", 0);
                    roomInput.setText(onlineRoomId);
                    status.setText("房间 " + onlineRoomId + " 已创建，可让 iOS 输入加入");
                }));
            } catch (Exception ignored) {
            }
        });
        join.setOnClickListener(v -> {
            String room = roomInput.getText().toString().trim().toUpperCase();
            if (room.isEmpty()) {
                JFApiClient.get("/multiplayer/rooms?kind=" + kind, (json, error) -> runOnUiThread(() -> {
                    JSONArray rooms = json == null ? null : json.optJSONArray("rooms");
                    if (rooms == null) rooms = json == null ? null : json.optJSONArray("data");
                    if (rooms == null) {
                        try {
                            rooms = json == null ? null : new JSONArray(json.toString());
                        } catch (Exception ignored) {
                            rooms = null;
                        }
                    }
                    JSONObject first = rooms == null || rooms.length() == 0 ? null : rooms.optJSONObject(0);
                    String autoRoom = first == null ? "" : first.optString("roomId");
                    if (autoRoom.isEmpty()) {
                        status.setText("没有可加入的房间");
                        return;
                    }
                    roomInput.setText(autoRoom);
                    join.performClick();
                }));
                return;
            }
            try {
                JSONObject body = new JSONObject();
                body.put("displayName", android.os.Build.MODEL);
                JFApiClient.post("/multiplayer/rooms/" + room + "/join", body, (json, error) -> runOnUiThread(() -> {
                    if (json == null) {
                        status.setText("加入失败");
                        return;
                    }
                    onlineRoomId = json.optString("roomId", room);
                    onlineLatestSeq = json.optInt("latestSeq", 0);
                    status.setText("已加入房间 " + onlineRoomId);
                }));
            } catch (Exception ignored) {
            }
        });
        send.setOnClickListener(v -> sendOnlineSample(status));
        poll.setOnClickListener(v -> pollOnline(status));
    }

    private Button smallButton(String text) {
        Button b = new Button(this);
        b.setText(text);
        b.setTextSize(12);
        b.setAllCaps(false);
        return b;
    }

    private void sendOnlineSample(TextView status) {
        if (onlineRoomId == null || onlineRoomId.isEmpty()) {
            status.setText("请先创建或加入房间");
            return;
        }
        try {
            JSONObject payload = new JSONObject();
            String type;
            if ("UNDERCOVER".equals(kind)) {
                type = "identity";
                payload.put("number", 1);
                payload.put("role", "平民");
                payload.put("word", "可乐");
            } else {
                type = "king_deal";
                payload.put("card", "K");
            }
            JSONObject body = new JSONObject();
            body.put("type", type);
            body.put("payload", payload);
            JFApiClient.post("/multiplayer/rooms/" + onlineRoomId + "/messages", body, (json, error) -> runOnUiThread(() -> {
                status.setText(error == null ? "已发送 " + type : "发送失败");
                pollOnline(status);
            }));
        } catch (Exception ignored) {
        }
    }

    private void pollOnline(TextView status) {
        if (onlineRoomId == null || onlineRoomId.isEmpty()) {
            status.setText("请先创建或加入房间");
            return;
        }
        JFApiClient.get("/multiplayer/rooms/" + onlineRoomId + "?since=" + onlineLatestSeq, (json, error) -> runOnUiThread(() -> {
            if (json == null) {
                status.setText("刷新失败");
                return;
            }
            onlineLatestSeq = json.optInt("latestSeq", onlineLatestSeq);
            JSONArray messages = json.optJSONArray("messages");
            int count = messages == null ? 0 : messages.length();
            status.setText("房间 " + onlineRoomId + " · 新消息 " + count + " · seq " + onlineLatestSeq);
        }));
    }

    private void showTruthOrDare() {
        TextView result = JFTheme.label(this, "点击开始，3 秒内混合滚动", 22, JFTheme.TEXT, Typeface.BOLD);
        result.setGravity(Gravity.CENTER);
        root.addView(result, new LinearLayout.LayoutParams(-1, 0, 1));
        Button start = new Button(this);
        start.setText("开始选择");
        start.setAllCaps(false);
        root.addView(start, new LinearLayout.LayoutParams(-1, JFTheme.dp(this, 56)));
        start.setOnClickListener(v -> {
            start.setEnabled(false);
            long end = System.currentTimeMillis() + 3000;
            Handler handler = new Handler();
            Runnable tick = new Runnable() {
                @Override public void run() {
                    boolean truth = random.nextBoolean();
                    result.setText(truth ? "真心话" : "大冒险");
                    result.setTextColor(truth ? 0xffff8ab3 : 0xff8ed1ff);
                    if (System.currentTimeMillis() < end) {
                        handler.postDelayed(this, 90);
                    } else {
                        start.setEnabled(true);
                        submitScore(truth ? 10 : 12, true);
                    }
                }
            };
            handler.post(tick);
        });
    }

    private void showDice() {
        TextView dice = JFTheme.label(this, "1", 96, JFTheme.WARNING, Typeface.BOLD);
        dice.setGravity(Gravity.CENTER);
        root.addView(dice, new LinearLayout.LayoutParams(-1, 0, 1));
        Button roll = new Button(this);
        roll.setText("掷骰子");
        roll.setAllCaps(false);
        root.addView(roll, new LinearLayout.LayoutParams(-1, JFTheme.dp(this, 56)));
        roll.setOnClickListener(v -> {
            int value = random.nextInt(6) + 1;
            dice.setText(String.valueOf(value));
            submitScore(value, true);
        });
    }

    private void showFiveInRow() {
        TextView status = JFTheme.label(this, "黑棋先手，连成五子获胜", 16, JFTheme.SUBTEXT, Typeface.BOLD);
        root.addView(status);
        FiveBoardView board = new FiveBoardView(this, status);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-1, 0, 1);
        lp.topMargin = JFTheme.dp(this, 12);
        root.addView(board, lp);
    }

    private void showUndercover() {
        String normal = random.nextBoolean() ? "可乐" : "电影";
        String undercover = normal.equals("可乐") ? "雪碧" : "电视剧";
        int undercoverIndex = random.nextInt(6);
        final int[] player = {0};
        TextView card = JFTheme.label(this, "依次传手机查看身份词", 26, JFTheme.TEXT, Typeface.BOLD);
        card.setGravity(Gravity.CENTER);
        root.addView(card, new LinearLayout.LayoutParams(-1, 0, 1));
        Button next = new Button(this);
        next.setText("查看 1 号玩家");
        next.setAllCaps(false);
        root.addView(next, new LinearLayout.LayoutParams(-1, JFTheme.dp(this, 56)));
        next.setOnClickListener(v -> {
            if (player[0] >= 6) {
                card.setText("发词完成，开始描述与投票");
                next.setText("结束本局");
                next.setOnClickListener(end -> submitScore(60, true));
                return;
            }
            boolean spy = player[0] == undercoverIndex;
            card.setText((player[0] + 1) + " 号\n\n" + (spy ? undercover : normal));
            player[0]++;
            next.setText(player[0] >= 6 ? "开始游戏" : "查看 " + (player[0] + 1) + " 号玩家");
        });
    }

    private void showKingGame() {
        String[] orders = {
                "国王指定两人对视 10 秒",
                "国王指定一人说真心话",
                "国王指定一人完成大冒险",
                "抽到 7 的玩家表演 15 秒",
                "黑桃 A 和红桃 K 互换座位"
        };
        TextView result = JFTheme.label(this, "点击抽取国王命令", 24, JFTheme.TEXT, Typeface.BOLD);
        result.setGravity(Gravity.CENTER);
        root.addView(result, new LinearLayout.LayoutParams(-1, 0, 1));
        Button draw = new Button(this);
        draw.setText("抽命令");
        draw.setAllCaps(false);
        root.addView(draw, new LinearLayout.LayoutParams(-1, JFTheme.dp(this, 56)));
        draw.setOnClickListener(v -> {
            result.setText(orders[random.nextInt(orders.length)]);
            submitScore(20, true);
        });
    }

    private void showCardGame() {
        String[] suits = { "♠", "♥", "♣", "♦" };
        String[] ranks = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" };
        TextView card = JFTheme.label(this, "背面", 72, JFTheme.TEXT, Typeface.BOLD);
        card.setGravity(Gravity.CENTER);
        root.addView(card, new LinearLayout.LayoutParams(-1, 0, 1));
        Button draw = new Button(this);
        draw.setText("抽一张");
        draw.setAllCaps(false);
        root.addView(draw, new LinearLayout.LayoutParams(-1, JFTheme.dp(this, 56)));
        draw.setOnClickListener(v -> {
            String suit = suits[random.nextInt(suits.length)];
            String rank = ranks[random.nextInt(ranks.length)];
            card.setText(suit + "\n" + rank);
            card.setTextColor(("♥".equals(suit) || "♦".equals(suit)) ? 0xffff5c7a : JFTheme.TEXT);
            submitScore(rank.equals("A") ? 14 : 5, true);
        });
    }

    private void showGestureBomb() {
        TextView state = JFTheme.label(this, "点击开始传递炸弹", 24, JFTheme.TEXT, Typeface.BOLD);
        state.setGravity(Gravity.CENTER);
        root.addView(state, new LinearLayout.LayoutParams(-1, 0, 1));
        Button pass = new Button(this);
        pass.setText("开始");
        pass.setAllCaps(false);
        root.addView(pass, new LinearLayout.LayoutParams(-1, JFTheme.dp(this, 56)));
        final long[] boomAt = {0};
        final int[] passes = {0};
        pass.setOnClickListener(v -> {
            long now = System.currentTimeMillis();
            if (boomAt[0] == 0) {
                boomAt[0] = now + 3000 + random.nextInt(5000);
                passes[0] = 0;
                pass.setText("传给下一个");
                state.setText("炸弹传递中");
                return;
            }
            if (now >= boomAt[0]) {
                state.setText("爆炸\n传递 " + passes[0] + " 次");
                pass.setText("再来一局");
                submitScore(passes[0], false);
                boomAt[0] = 0;
            } else {
                passes[0]++;
                state.setText("已传递 " + passes[0] + " 次");
            }
        });
    }

    private void showPuzzle() {
        TextView status = JFTheme.label(this, "移动空格旁边的数字，还原 1-8 顺序", 16, JFTheme.SUBTEXT, Typeface.BOLD);
        root.addView(status);
        GridLayout grid = new GridLayout(this);
        grid.setColumnCount(3);
        LinearLayout.LayoutParams gp = new LinearLayout.LayoutParams(-1, 0, 1);
        gp.topMargin = JFTheme.dp(this, 16);
        root.addView(grid, gp);

        int[] tiles = { 1, 2, 3, 4, 5, 6, 7, 0, 8 };
        ArrayList<Button> buttons = new ArrayList<>();
        Runnable render = () -> {
            for (int i = 0; i < buttons.size(); i++) {
                int value = tiles[i];
                Button b = buttons.get(i);
                b.setText(value == 0 ? "" : String.valueOf(value));
                b.setEnabled(value != 0);
            }
        };
        for (int i = 0; i < 9; i++) {
            final int index = i;
            Button b = new Button(this);
            b.setTextSize(24);
            b.setAllCaps(false);
            b.setOnClickListener(v -> {
                int empty = 0;
                for (int j = 0; j < tiles.length; j++) if (tiles[j] == 0) empty = j;
                int dr = Math.abs(index / 3 - empty / 3);
                int dc = Math.abs(index % 3 - empty % 3);
                if (dr + dc != 1) return;
                tiles[empty] = tiles[index];
                tiles[index] = 0;
                render.run();
                boolean solved = true;
                for (int j = 0; j < 8; j++) solved &= tiles[j] == j + 1;
                if (solved) {
                    status.setText("完成");
                    submitScore(100, true);
                }
            });
            buttons.add(b);
            GridLayout.LayoutParams lp = new GridLayout.LayoutParams();
            lp.width = (getResources().getDisplayMetrics().widthPixels - JFTheme.dp(this, 56)) / 3;
            lp.height = JFTheme.dp(this, 92);
            lp.setMargins(5, 5, 5, 5);
            grid.addView(b, lp);
        }
        render.run();
    }

    private void showSnake() {
        TextView status = JFTheme.label(this, "滑动或按钮控制方向，吃到绿色方块得分", 16, JFTheme.SUBTEXT, Typeface.BOLD);
        root.addView(status);
        SnakeView snake = new SnakeView(this, status);
        root.addView(snake, new LinearLayout.LayoutParams(-1, 0, 1));
        LinearLayout controls = new LinearLayout(this);
        controls.setOrientation(LinearLayout.HORIZONTAL);
        String[] names = { "上", "下", "左", "右" };
        int[][] dirs = { {0, -1}, {0, 1}, {-1, 0}, {1, 0} };
        for (int i = 0; i < names.length; i++) {
            final int dx = dirs[i][0];
            final int dy = dirs[i][1];
            Button b = new Button(this);
            b.setText(names[i]);
            b.setOnClickListener(v -> snake.setDirection(dx, dy));
            controls.addView(b, new LinearLayout.LayoutParams(0, JFTheme.dp(this, 48), 1));
        }
        root.addView(controls);
        snake.start();
    }

    private void showSudoku() {
        TextView status = JFTheme.label(this, "点击空格循环 1-9，完成后自动校验", 16, JFTheme.SUBTEXT, Typeface.BOLD);
        root.addView(status);
        GridLayout grid = new GridLayout(this);
        grid.setColumnCount(9);
        LinearLayout.LayoutParams gp = new LinearLayout.LayoutParams(-1, 0, 1);
        gp.topMargin = JFTheme.dp(this, 14);
        root.addView(grid, gp);

        int[][] solution = {
            {5,3,4,6,7,8,9,1,2}, {6,7,2,1,9,5,3,4,8}, {1,9,8,3,4,2,5,6,7},
            {8,5,9,7,6,1,4,2,3}, {4,2,6,8,5,3,7,9,1}, {7,1,3,9,2,4,8,5,6},
            {9,6,1,5,3,7,2,8,4}, {2,8,7,4,1,9,6,3,5}, {3,4,5,2,8,6,1,7,9}
        };
        int[][] puzzle = {
            {5,3,0,0,7,0,0,0,0}, {6,0,0,1,9,5,0,0,0}, {0,9,8,0,0,0,0,6,0},
            {8,0,0,0,6,0,0,0,3}, {4,0,0,8,0,3,0,0,1}, {7,0,0,0,2,0,0,0,6},
            {0,6,0,0,0,0,2,8,0}, {0,0,0,4,1,9,0,0,5}, {0,0,0,0,8,0,0,7,9}
        };
        int[][] board = new int[9][9];
        ArrayList<Button> cells = new ArrayList<>();
        for (int r = 0; r < 9; r++) {
            for (int c = 0; c < 9; c++) {
                board[r][c] = puzzle[r][c];
                final int row = r;
                final int col = c;
                Button b = new Button(this);
                b.setTextSize(11);
                b.setAllCaps(false);
                b.setText(board[r][c] == 0 ? "" : String.valueOf(board[r][c]));
                b.setEnabled(puzzle[r][c] == 0);
                b.setOnClickListener(v -> {
                    board[row][col] = board[row][col] % 9 + 1;
                    b.setText(String.valueOf(board[row][col]));
                    boolean done = true;
                    for (int rr = 0; rr < 9; rr++) for (int cc = 0; cc < 9; cc++) done &= board[rr][cc] == solution[rr][cc];
                    if (done) {
                        status.setText("数独完成");
                        submitScore(300, true);
                    }
                });
                cells.add(b);
                GridLayout.LayoutParams lp = new GridLayout.LayoutParams();
                lp.width = (getResources().getDisplayMetrics().widthPixels - JFTheme.dp(this, 42)) / 9;
                lp.height = JFTheme.dp(this, 42);
                lp.setMargins(1, 1, 1, 1);
                grid.addView(b, lp);
            }
        }
    }

    private void showReaction() {
        TextView state = JFTheme.label(this, "点击开始，等待绿色信号", 24, JFTheme.TEXT, Typeface.BOLD);
        state.setGravity(Gravity.CENTER);
        root.addView(state, new LinearLayout.LayoutParams(-1, 0, 1));
        Button action = new Button(this);
        action.setText("开始");
        action.setAllCaps(false);
        root.addView(action, new LinearLayout.LayoutParams(-1, JFTheme.dp(this, 56)));
        final long[] readyAt = {0};
        action.setOnClickListener(v -> {
            if (readyAt[0] > 0) {
                long ms = System.currentTimeMillis() - readyAt[0];
                state.setText(ms + " ms");
                submitScore((int) Math.max(0, 1000 - ms), true);
                readyAt[0] = 0;
                action.setText("再来一次");
                return;
            }
            state.setText("等待...");
            action.setEnabled(false);
            new Handler().postDelayed(() -> {
                readyAt[0] = System.currentTimeMillis();
                state.setText("点！");
                state.setTextColor(JFTheme.ACCENT);
                action.setText("点击");
                action.setEnabled(true);
            }, 900 + random.nextInt(1800));
        });
    }

    private void showMemory() {
        GridLayout grid = new GridLayout(this);
        grid.setColumnCount(4);
        LinearLayout.LayoutParams gp = new LinearLayout.LayoutParams(-1, 0, 1);
        gp.topMargin = JFTheme.dp(this, 16);
        root.addView(grid, gp);

        ArrayList<Integer> values = new ArrayList<>();
        for (int i = 1; i <= 8; i++) {
            values.add(i);
            values.add(i);
        }
        Collections.shuffle(values);
        final Button[] first = { null };
        final int[] firstValue = { -1 };
        final int[] matched = { 0 };
        for (int value : values) {
            Button b = new Button(this);
            b.setText("?");
            b.setTextSize(24);
            b.setAllCaps(false);
            b.setOnClickListener(v -> {
                if (!"?".contentEquals(b.getText())) return;
                b.setText(String.valueOf(value));
                if (first[0] == null) {
                    first[0] = b;
                    firstValue[0] = value;
                } else if (firstValue[0] == value) {
                    matched[0] += 2;
                    first[0] = null;
                    if (matched[0] == values.size()) submitScore(100, true);
                } else {
                    Button old = first[0];
                    first[0] = null;
                    new Handler().postDelayed(() -> {
                        old.setText("?");
                        b.setText("?");
                    }, 500);
                }
            });
            GridLayout.LayoutParams lp = new GridLayout.LayoutParams();
            lp.width = (getResources().getDisplayMetrics().widthPixels - JFTheme.dp(this, 56)) / 4;
            lp.height = JFTheme.dp(this, 72);
            lp.setMargins(4, 4, 4, 4);
            grid.addView(b, lp);
        }
    }

    private void show2048() {
        int[][] grid = new int[4][4];
        int[] score = {0};
        spawn2048(grid);
        spawn2048(grid);
        TextView board = JFTheme.label(this, "", 24, JFTheme.TEXT, Typeface.BOLD);
        board.setGravity(Gravity.CENTER);
        root.addView(board, new LinearLayout.LayoutParams(-1, 0, 1));
        render2048(board, grid, score[0]);
        LinearLayout controls = new LinearLayout(this);
        controls.setOrientation(LinearLayout.HORIZONTAL);
        String[] names = { "上", "下", "左", "右" };
        int[] dirs = { 0, 1, 2, 3 };
        for (int i = 0; i < names.length; i++) {
            final int dir = dirs[i];
            Button b = new Button(this);
            b.setText(names[i]);
            b.setOnClickListener(v -> {
                int gain = move2048(grid, dir);
                if (gain <= 0) return;
                score[0] += gain;
                spawn2048(grid);
                render2048(board, grid, score[0]);
                if (!canMove2048(grid)) submitScore(score[0], false);
            });
            controls.addView(b, new LinearLayout.LayoutParams(0, JFTheme.dp(this, 48), 1));
        }
        root.addView(controls);
    }

    private void render2048(TextView view, int[][] grid, int score) {
        StringBuilder sb = new StringBuilder("得分 ").append(score).append("\n\n");
        for (int r = 0; r < 4; r++) {
            for (int c = 0; c < 4; c++) {
                String value = grid[r][c] == 0 ? "." : String.valueOf(grid[r][c]);
                sb.append(String.format("%4s", value));
            }
            sb.append("\n\n");
        }
        view.setText(sb.toString());
    }

    private void spawn2048(int[][] grid) {
        ArrayList<int[]> empty = new ArrayList<>();
        for (int r = 0; r < 4; r++) for (int c = 0; c < 4; c++) if (grid[r][c] == 0) empty.add(new int[] { r, c });
        if (empty.isEmpty()) return;
        int[] p = empty.get(random.nextInt(empty.size()));
        grid[p[0]][p[1]] = random.nextInt(10) == 0 ? 4 : 2;
    }

    private int move2048(int[][] grid, int dir) {
        int gain = 0;
        boolean moved = false;
        for (int line = 0; line < 4; line++) {
            int[] old = new int[4];
            for (int i = 0; i < 4; i++) old[i] = get2048(grid, dir, line, i);
            int[] next = merge2048(old);
            for (int i = 0; i < 4; i++) {
                if (old[i] != next[i]) moved = true;
                set2048(grid, dir, line, i, next[i]);
                if (next[i] > old[i]) gain += next[i];
            }
        }
        return moved ? Math.max(1, gain) : 0;
    }

    private int[] merge2048(int[] line) {
        int[] values = new int[4];
        int count = 0;
        for (int v : line) if (v != 0) values[count++] = v;
        for (int i = 0; i < 3; i++) {
            if (values[i] != 0 && values[i] == values[i + 1]) {
                values[i] *= 2;
                values[i + 1] = 0;
            }
        }
        int[] out = new int[4];
        int j = 0;
        for (int v : values) if (v != 0) out[j++] = v;
        return out;
    }

    private int get2048(int[][] g, int dir, int line, int i) {
        if (dir == 0) return g[i][line];
        if (dir == 1) return g[3 - i][line];
        if (dir == 2) return g[line][i];
        return g[line][3 - i];
    }

    private void set2048(int[][] g, int dir, int line, int i, int value) {
        if (dir == 0) g[i][line] = value;
        else if (dir == 1) g[3 - i][line] = value;
        else if (dir == 2) g[line][i] = value;
        else g[line][3 - i] = value;
    }

    private boolean canMove2048(int[][] grid) {
        for (int r = 0; r < 4; r++) {
            for (int c = 0; c < 4; c++) {
                if (grid[r][c] == 0) return true;
                if (r < 3 && grid[r][c] == grid[r + 1][c]) return true;
                if (c < 3 && grid[r][c] == grid[r][c + 1]) return true;
            }
        }
        return false;
    }

    private void showRhythm() {
        TextView beat = JFTheme.label(this, "跟随节拍点击", 28, JFTheme.TEXT, Typeface.BOLD);
        beat.setGravity(Gravity.CENTER);
        root.addView(beat, new LinearLayout.LayoutParams(-1, 0, 1));
        Button tap = new Button(this);
        tap.setText("开始");
        tap.setAllCaps(false);
        root.addView(tap, new LinearLayout.LayoutParams(-1, JFTheme.dp(this, 56)));
        Handler handler = new Handler();
        final long[] target = {0};
        final int[] round = {0};
        final int[] score = {0};
        Runnable nextBeat = new Runnable() {
            @Override public void run() {
                if (round[0] >= 10) {
                    beat.setText("结束\n得分 " + score[0]);
                    tap.setText("再来一次");
                    submitScore(score[0], true);
                    round[0] = 0;
                    target[0] = 0;
                    return;
                }
                round[0]++;
                target[0] = System.currentTimeMillis();
                beat.setText("第 " + round[0] + " 拍\n点！");
                beat.setTextColor(round[0] % 2 == 0 ? 0xffff8ab3 : JFTheme.ACCENT);
                handler.postDelayed(this, 720);
            }
        };
        tap.setOnClickListener(v -> {
            if (target[0] == 0) {
                score[0] = 0;
                tap.setText("点击节拍");
                handler.post(nextBeat);
                return;
            }
            long diff = Math.abs(System.currentTimeMillis() - target[0]);
            int gain = (int) Math.max(0, 100 - diff / 4);
            score[0] += gain;
            beat.setText("+" + gain);
        });
    }

    private void showScorePlaceholder() {
        TextView desc = JFTheme.label(this, "此游戏已接入 Android 入口、计分和上报。下一步按 iOS 规则逐项还原交互细节。", 18, JFTheme.TEXT, Typeface.BOLD);
        desc.setGravity(Gravity.CENTER);
        root.addView(desc, new LinearLayout.LayoutParams(-1, 0, 1));
        Button done = new Button(this);
        done.setText("完成一局");
        done.setAllCaps(false);
        root.addView(done, new LinearLayout.LayoutParams(-1, JFTheme.dp(this, 56)));
        done.setOnClickListener(v -> submitScore(10 + random.nextInt(90), true));
    }

    private void submitScore(int score, boolean win) {
        Toast.makeText(this, "得分 " + score, Toast.LENGTH_SHORT).show();
        try {
            JSONObject body = new JSONObject();
            body.put("kind", kind);
            body.put("score", score);
            body.put("win", win);
            JFApiClient.post("/games/records", body, (json, error) -> {});
        } catch (Exception ignored) {
        }
    }

    static final class DrawView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final ArrayList<float[]> lines = new ArrayList<>();
        private float lastX;
        private float lastY;

        DrawView(Activity c) {
            super(c);
            setBackgroundColor(Color.BLACK);
            paint.setColor(Color.WHITE);
            paint.setStrokeWidth(8);
            paint.setStrokeCap(Paint.Cap.ROUND);
        }

        @Override protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            for (float[] l : lines) canvas.drawLine(l[0], l[1], l[2], l[3], paint);
        }

        @Override public boolean onTouchEvent(MotionEvent e) {
            if (e.getAction() == MotionEvent.ACTION_DOWN) {
                lastX = e.getX();
                lastY = e.getY();
                return true;
            }
            if (e.getAction() == MotionEvent.ACTION_MOVE) {
                lines.add(new float[] { lastX, lastY, e.getX(), e.getY() });
                lastX = e.getX();
                lastY = e.getY();
                invalidate();
                return true;
            }
            return true;
        }
    }

    final class FiveBoardView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final int[][] board = new int[15][15];
        private final TextView status;
        private int player = 1;
        private boolean finished;

        FiveBoardView(Activity c, TextView status) {
            super(c);
            this.status = status;
            setBackground(JFTheme.card(c, 0xffd8b16a));
        }

        @Override protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            float size = Math.min(getWidth(), getHeight()) - 32;
            float left = (getWidth() - size) / 2f;
            float top = (getHeight() - size) / 2f;
            float cell = size / 14f;
            paint.setStrokeWidth(2);
            paint.setColor(0xff3b2414);
            for (int i = 0; i < 15; i++) {
                float p = left + i * cell;
                canvas.drawLine(left, top + i * cell, left + size, top + i * cell, paint);
                canvas.drawLine(p, top, p, top + size, paint);
            }
            for (int r = 0; r < 15; r++) {
                for (int c = 0; c < 15; c++) {
                    if (board[r][c] == 0) continue;
                    paint.setColor(board[r][c] == 1 ? Color.BLACK : Color.WHITE);
                    canvas.drawCircle(left + c * cell, top + r * cell, cell * 0.38f, paint);
                    paint.setStyle(Paint.Style.STROKE);
                    paint.setColor(0x66000000);
                    canvas.drawCircle(left + c * cell, top + r * cell, cell * 0.38f, paint);
                    paint.setStyle(Paint.Style.FILL);
                }
            }
        }

        @Override public boolean onTouchEvent(MotionEvent e) {
            if (finished || e.getAction() != MotionEvent.ACTION_DOWN) return true;
            float size = Math.min(getWidth(), getHeight()) - 32;
            float left = (getWidth() - size) / 2f;
            float top = (getHeight() - size) / 2f;
            float cell = size / 14f;
            int col = Math.round((e.getX() - left) / cell);
            int row = Math.round((e.getY() - top) / cell);
            if (row < 0 || row >= 15 || col < 0 || col >= 15 || board[row][col] != 0) return true;
            board[row][col] = player;
            if (win(row, col, player)) {
                finished = true;
                status.setText((player == 1 ? "黑棋" : "白棋") + "获胜");
                submitScore(player == 1 ? 100 : 90, true);
            } else {
                player = player == 1 ? 2 : 1;
                status.setText(player == 1 ? "黑棋回合" : "白棋回合");
            }
            invalidate();
            return true;
        }

        private boolean win(int row, int col, int p) {
            int[][] dirs = { {1,0}, {0,1}, {1,1}, {1,-1} };
            for (int[] d : dirs) {
                int count = 1 + count(row, col, d[0], d[1], p) + count(row, col, -d[0], -d[1], p);
                if (count >= 5) return true;
            }
            return false;
        }

        private int count(int row, int col, int dr, int dc, int p) {
            int n = 0;
            int r = row + dr;
            int c = col + dc;
            while (r >= 0 && r < 15 && c >= 0 && c < 15 && board[r][c] == p) {
                n++;
                r += dr;
                c += dc;
            }
            return n;
        }
    }

    final class SnakeView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Handler handler = new Handler();
        private final ArrayList<int[]> snake = new ArrayList<>();
        private final TextView status;
        private int dx = 1;
        private int dy = 0;
        private int foodX = 8;
        private int foodY = 8;
        private int score;
        private boolean dead;

        SnakeView(Activity c, TextView status) {
            super(c);
            this.status = status;
            setBackground(JFTheme.card(c, 0xff062314));
            snake.add(new int[] { 5, 5 });
            snake.add(new int[] { 4, 5 });
            snake.add(new int[] { 3, 5 });
        }

        void start() {
            handler.postDelayed(this::tick, 260);
        }

        void setDirection(int nextDx, int nextDy) {
            if (nextDx == -dx && nextDy == -dy) return;
            dx = nextDx;
            dy = nextDy;
        }

        private void tick() {
            if (dead) return;
            int[] head = snake.get(0);
            int nx = head[0] + dx;
            int ny = head[1] + dy;
            if (nx < 0 || nx >= 16 || ny < 0 || ny >= 16 || contains(nx, ny)) {
                dead = true;
                status.setText("结束 · 得分 " + score);
                submitScore(score, false);
                invalidate();
                return;
            }
            snake.add(0, new int[] { nx, ny });
            if (nx == foodX && ny == foodY) {
                score += 10;
                do {
                    foodX = random.nextInt(16);
                    foodY = random.nextInt(16);
                } while (contains(foodX, foodY));
                status.setText("得分 " + score);
            } else {
                snake.remove(snake.size() - 1);
            }
            invalidate();
            handler.postDelayed(this::tick, 260);
        }

        private boolean contains(int x, int y) {
            for (int[] p : snake) if (p[0] == x && p[1] == y) return true;
            return false;
        }

        @Override protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            float size = Math.min(getWidth(), getHeight()) - 24;
            float left = (getWidth() - size) / 2f;
            float top = (getHeight() - size) / 2f;
            float cell = size / 16f;
            paint.setColor(0xff34d399);
            for (int[] p : snake) {
                canvas.drawRoundRect(left + p[0] * cell, top + p[1] * cell,
                        left + (p[0] + 1) * cell - 3, top + (p[1] + 1) * cell - 3, 8, 8, paint);
            }
            paint.setColor(0xffff5c7a);
            canvas.drawCircle(left + foodX * cell + cell / 2, top + foodY * cell + cell / 2, cell * 0.36f, paint);
        }

        @Override public boolean onTouchEvent(MotionEvent e) {
            if (e.getAction() != MotionEvent.ACTION_UP) return true;
            float cx = getWidth() / 2f;
            float cy = getHeight() / 2f;
            float ax = Math.abs(e.getX() - cx);
            float ay = Math.abs(e.getY() - cy);
            if (ax > ay) setDirection(e.getX() > cx ? 1 : -1, 0);
            else setDirection(0, e.getY() > cy ? 1 : -1);
            return true;
        }
    }
}
