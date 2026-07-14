package com.jifeng.upapp;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Typeface;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.GridLayout;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONObject;

public class MainActivity extends Activity {
    private FrameLayout content;
    private LinearLayout footer;
    private Button[] tabs;
    private JFGame[] games;
    private int selectedTab = 0;

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        games = JFGame.all();
        JFApiClient.ensureGuest(this, (json, error) -> {});
        buildRoot();
        showTab(0);
    }

    private void buildRoot() {
        FrameLayout root = new FrameLayout(this);
        root.setBackground(JFTheme.bg());
        setContentView(root);

        content = new FrameLayout(this);
        FrameLayout.LayoutParams cp = new FrameLayout.LayoutParams(-1, -1);
        cp.bottomMargin = JFTheme.dp(this, 88);
        root.addView(content, cp);

        footer = new LinearLayout(this);
        footer.setOrientation(LinearLayout.HORIZONTAL);
        footer.setGravity(Gravity.CENTER);
        footer.setBackground(JFTheme.card(this, 0xee050814));
        JFTheme.pad(footer, 8, 8, 8, 8);
        FrameLayout.LayoutParams fp = new FrameLayout.LayoutParams(-1, JFTheme.dp(this, 72));
        fp.gravity = Gravity.BOTTOM;
        fp.leftMargin = JFTheme.dp(this, 12);
        fp.rightMargin = JFTheme.dp(this, 12);
        fp.bottomMargin = JFTheme.dp(this, 10);
        root.addView(footer, fp);

        String[] names = { "游戏", "排行", "聊天", "成就", "皮肤", "我的" };
        tabs = new Button[names.length];
        for (int i = 0; i < names.length; i++) {
            final int index = i;
            Button b = new Button(this);
            b.setText(names[i]);
            b.setTextSize(12);
            b.setAllCaps(false);
            b.setTextColor(JFTheme.TEXT);
            b.setBackground(JFTheme.card(this, 0x00000000));
            b.setOnClickListener(v -> showTab(index));
            footer.addView(b, new LinearLayout.LayoutParams(0, -1, 1));
            tabs[i] = b;
        }
    }

    private void showTab(int index) {
        selectedTab = index;
        for (int i = 0; i < tabs.length; i++) {
            tabs[i].setTextColor(i == index ? JFTheme.ACCENT : JFTheme.TEXT);
            tabs[i].setBackground(JFTheme.card(this, i == index ? 0x337cffb2 : 0x00000000));
        }
        content.removeAllViews();
        if (index == 0) showGames();
        else if (index == 1) showLeaderboard();
        else if (index == 2) showChat();
        else if (index == 3) showAchievements();
        else if (index == 4) showSkins();
        else showProfile();
    }

    private LinearLayout page(String title, String subtitle) {
        ScrollView scroll = new ScrollView(this);
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        JFTheme.pad(box, 20, 22, 20, 24);
        scroll.addView(box);
        content.addView(scroll, new FrameLayout.LayoutParams(-1, -1));

        TextView h = JFTheme.label(this, title, 30, JFTheme.TEXT, Typeface.BOLD);
        box.addView(h);
        TextView sub = JFTheme.label(this, subtitle, 15, JFTheme.SUBTEXT, Typeface.NORMAL);
        LinearLayout.LayoutParams sp = new LinearLayout.LayoutParams(-1, -2);
        sp.bottomMargin = JFTheme.dp(this, 16);
        box.addView(sub, sp);
        return box;
    }

    private void showGames() {
        LinearLayout box = page("继风小游戏", "Android 原生移植版，已接入底部 tab 和后端基础接口");

        LinearLayout profile = cardBox();
        profile.addView(JFTheme.label(this, "Lv 1  ·  风之币 0  ·  连续 0 天", 14, JFTheme.TEXT, Typeface.BOLD));
        profile.addView(JFTheme.label(this, "点击底部「我的」维护昵称、头像、背景和签名", 12, JFTheme.SUBTEXT, Typeface.NORMAL));
        box.addView(profile);

        GridLayout grid = new GridLayout(this);
        grid.setColumnCount(2);
        LinearLayout.LayoutParams gp = new LinearLayout.LayoutParams(-1, -2);
        gp.topMargin = JFTheme.dp(this, 14);
        box.addView(grid, gp);

        for (JFGame game : games) {
            LinearLayout card = new LinearLayout(this);
            card.setOrientation(LinearLayout.VERTICAL);
            card.setGravity(Gravity.BOTTOM);
            card.setBackground(JFTheme.gradient(game.colorA, game.colorB, 0xff111827, JFTheme.dp(this, 18)));
            JFTheme.pad(card, 14, 14, 14, 14);
            TextView title = JFTheme.label(this, game.title, 18, JFTheme.TEXT, Typeface.BOLD);
            TextView desc = JFTheme.label(this, game.subtitle, 12, 0xddffffff, Typeface.NORMAL);
            card.addView(title);
            card.addView(desc);
            card.setOnClickListener(v -> {
                Intent intent = new Intent(this, GameActivity.class);
                intent.putExtra("kind", game.kind);
                intent.putExtra("title", game.title);
                startActivity(intent);
            });
            GridLayout.LayoutParams lp = new GridLayout.LayoutParams();
            lp.width = (getResources().getDisplayMetrics().widthPixels - JFTheme.dp(this, 52)) / 2;
            lp.height = JFTheme.dp(this, 132);
            lp.setMargins(JFTheme.dp(this, 4), JFTheme.dp(this, 4), JFTheme.dp(this, 4), JFTheme.dp(this, 10));
            grid.addView(card, lp);
        }
    }

    private void showLeaderboard() {
        LinearLayout box = page("排行榜", "展示各小游戏分数排名");
        TextView list = JFTheme.label(this, "加载中...", 15, JFTheme.TEXT, Typeface.NORMAL);
        box.addView(cardBoxWith(list));
        JFApiClient.get("/games/leaderboard?kind=TRUTH_OR_DARE&take=20", (json, error) -> runOnUiThread(() -> {
            if (error != null || json == null) {
                list.setText("暂时无法连接后端，稍后重试");
                return;
            }
            JSONArray arr = json.optJSONArray("items");
            if (arr == null) arr = json.optJSONArray("data");
            if (arr == null || arr.length() == 0) {
                list.setText("暂无排行数据");
                return;
            }
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < arr.length(); i++) {
                JSONObject item = arr.optJSONObject(i);
                sb.append(i + 1).append(". ")
                  .append(item == null ? "玩家" : item.optString("displayName", "玩家"))
                  .append("  ")
                  .append(item == null ? 0 : item.optInt("score"))
                  .append("\n");
            }
            list.setText(sb.toString());
        }));
    }

    private void showChat() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        JFTheme.pad(root, 20, 22, 20, 14);
        content.addView(root, new FrameLayout.LayoutParams(-1, -1));
        root.addView(JFTheme.label(this, "大厅聊天", 30, JFTheme.TEXT, Typeface.BOLD));
        TextView messages = JFTheme.label(this, "加载中...", 14, JFTheme.TEXT, Typeface.NORMAL);
        root.addView(cardBoxWith(messages), new LinearLayout.LayoutParams(-1, 0, 1));

        LinearLayout input = new LinearLayout(this);
        input.setOrientation(LinearLayout.HORIZONTAL);
        EditText field = new EditText(this);
        field.setHint("说点什么");
        field.setTextColor(JFTheme.TEXT);
        field.setHintTextColor(JFTheme.SUBTEXT);
        Button send = new Button(this);
        send.setText("发送");
        input.addView(field, new LinearLayout.LayoutParams(0, JFTheme.dp(this, 48), 1));
        input.addView(send, new LinearLayout.LayoutParams(JFTheme.dp(this, 76), JFTheme.dp(this, 48)));
        root.addView(input);

        Runnable reload = () -> JFApiClient.get("/chat/messages?room=global&take=30", (json, error) -> runOnUiThread(() -> {
            JSONArray arr = json == null ? null : json.optJSONArray("items");
            if (arr == null) arr = json == null ? null : json.optJSONArray("data");
            if (arr == null || arr.length() == 0) {
                messages.setText(error == null ? "暂无消息" : "聊天服务暂不可用");
                return;
            }
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < arr.length(); i++) {
                JSONObject item = arr.optJSONObject(i);
                JSONObject user = item == null ? null : item.optJSONObject("user");
                sb.append(user == null ? "玩家" : user.optString("displayName", "玩家"))
                  .append(": ")
                  .append(item == null ? "" : item.optString("content", ""))
                  .append("\n\n");
            }
            messages.setText(sb.toString());
        }));
        reload.run();
        send.setOnClickListener(v -> {
            String text = field.getText().toString().trim();
            if (text.isEmpty()) return;
            try {
                JSONObject body = new JSONObject();
                body.put("room", "global");
                body.put("content", text);
                JFApiClient.post("/chat/messages", body, (json, error) -> runOnUiThread(() -> {
                    field.setText("");
                    reload.run();
                }));
            } catch (Exception e) {
                Toast.makeText(this, "发送失败", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void showAchievements() {
        LinearLayout box = page("成就墙", "Android 版先保留本地成就展示，后续同步 iOS 成就判定");
        String[] rows = { "初来乍到 · 完成第一次游戏", "手速挑战 · 反应力突破 300ms", "聚会核心 · 真心话大冒险 10 局", "策略玩家 · 五子棋获胜" };
        for (String row : rows) box.addView(cardBoxWith(JFTheme.label(this, row, 15, JFTheme.TEXT, Typeface.BOLD)));
    }

    private void showSkins() {
        LinearLayout box = page("皮肤商店", "主题预设会同步影响 Android 首页和游戏背景");
        String[] skins = { "星夜派对", "像素萌宠", "粉色 Kitty", "宝可梦草地", "霓虹电玩城", "自定义主题" };
        for (String skin : skins) {
            Button b = new Button(this);
            b.setText(skin + "  ·  使用");
            b.setAllCaps(false);
            b.setTextColor(JFTheme.TEXT);
            b.setBackground(JFTheme.card(this, 0x22ffffff));
            b.setOnClickListener(v -> Toast.makeText(this, "已切换主题: " + skin, Toast.LENGTH_SHORT).show());
            LinearLayout.LayoutParams bp = new LinearLayout.LayoutParams(-1, JFTheme.dp(this, 54));
            bp.bottomMargin = JFTheme.dp(this, 10);
            box.addView(b, bp);
        }
    }

    private void showProfile() {
        LinearLayout box = page("个人主页", "昵称、头像、背景、签名与后端账号数据");
        box.addView(cardBoxWith(JFTheme.label(this, "继风玩家\n今晚也要赢一局\nLv 1 · 风之币 0 · 总局数 0", 16, JFTheme.TEXT, Typeface.BOLD)));
        JFApiClient.get("/me", (json, error) -> runOnUiThread(() -> {
            if (json == null) return;
            Toast.makeText(this, "个人资料已连接后端", Toast.LENGTH_SHORT).show();
        }));
    }

    private LinearLayout cardBox() {
        LinearLayout v = new LinearLayout(this);
        v.setOrientation(LinearLayout.VERTICAL);
        v.setBackground(JFTheme.card(this, JFTheme.CARD));
        JFTheme.pad(v, 16, 14, 16, 14);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-1, -2);
        lp.bottomMargin = JFTheme.dp(this, 12);
        v.setLayoutParams(lp);
        return v;
    }

    private LinearLayout cardBoxWith(View child) {
        LinearLayout v = cardBox();
        v.addView(child);
        return v;
    }
}
