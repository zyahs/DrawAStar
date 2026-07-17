package com.jifeng.upapp;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Typeface;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.PopupMenu;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class RecommendedGamesActivity extends Activity {
    private final Random random = new Random();
    private final List<JFSocialGameGuide> filtered = new ArrayList<>();
    private LinearLayout listContainer;
    private Button peopleButton;
    private Button moodButton;
    private int peopleFilter;
    private String moodFilter;
    private boolean showingDetail;

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        JFTheme.apply(this);
        showCatalog();
    }

    private void showCatalog() {
        showingDetail = false;
        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        scroll.setBackground(JFTheme.bg());

        LinearLayout page = new LinearLayout(this);
        page.setOrientation(LinearLayout.VERTICAL);
        JFTheme.pad(page, 18, 16, 18, 28);
        scroll.addView(page, new ScrollView.LayoutParams(-1, -2));
        setContentView(scroll);

        page.addView(header("推荐游戏", "不知道玩什么，就按人数和气氛挑一局", this::finish));

        LinearLayout feature = surface(0x18ffffff, JFTheme.ACCENT);
        feature.addView(JFTheme.label(this, "今晚玩什么", 21, JFTheme.TEXT, Typeface.BOLD));
        feature.addView(JFTheme.label(this,
            "从破冰、熟人聊天、热闹互动和推理中筛选，规则已经替你整理好。",
            13, JFTheme.SUBTEXT, Typeface.NORMAL));
        Button pick = JFTheme.primaryButton(this, "帮我选一局");
        LinearLayout.LayoutParams pickParams = new LinearLayout.LayoutParams(-1, JFTheme.dp(this, 50));
        pickParams.topMargin = JFTheme.dp(this, 13);
        feature.addView(pick, pickParams);
        page.addView(feature, spaced(-1, -2, 0, 12));

        LinearLayout filters = new LinearLayout(this);
        filters.setOrientation(LinearLayout.HORIZONTAL);
        peopleButton = JFTheme.secondaryButton(this, peopleFilterText());
        moodButton = JFTheme.secondaryButton(this, moodFilter == null ? "全部气氛" : moodFilter);
        filters.addView(peopleButton, new LinearLayout.LayoutParams(0, JFTheme.dp(this, 46), 1));
        LinearLayout.LayoutParams moodParams = new LinearLayout.LayoutParams(0, JFTheme.dp(this, 46), 1);
        moodParams.leftMargin = JFTheme.dp(this, 10);
        filters.addView(moodButton, moodParams);
        page.addView(filters, spaced(-1, -2, 0, 14));

        TextView section = JFTheme.label(this, "游戏清单", 17, JFTheme.TEXT, Typeface.BOLD);
        page.addView(section, spaced(-1, -2, 0, 8));

        listContainer = new LinearLayout(this);
        listContainer.setOrientation(LinearLayout.VERTICAL);
        page.addView(listContainer, new LinearLayout.LayoutParams(-1, -2));

        peopleButton.setOnClickListener(this::showPeopleMenu);
        moodButton.setOnClickListener(this::showMoodMenu);
        pick.setOnClickListener(v -> {
            if (filtered.isEmpty()) {
                Toast.makeText(this, "当前条件没有合适的游戏", Toast.LENGTH_SHORT).show();
                return;
            }
            showDetail(filtered.get(random.nextInt(filtered.size())));
        });
        rebuildList();
    }

    private View header(String title, String subtitle, Runnable backAction) {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);

        Button back = JFTheme.secondaryButton(this, "返回");
        back.setOnClickListener(v -> backAction.run());
        row.addView(back, new LinearLayout.LayoutParams(JFTheme.dp(this, 70), JFTheme.dp(this, 44)));

        LinearLayout copy = new LinearLayout(this);
        copy.setOrientation(LinearLayout.VERTICAL);
        copy.addView(JFTheme.label(this, title, 27, JFTheme.TEXT, Typeface.BOLD));
        copy.addView(JFTheme.label(this, subtitle, 13, JFTheme.SUBTEXT, Typeface.NORMAL));
        LinearLayout.LayoutParams copyParams = new LinearLayout.LayoutParams(0, -2, 1);
        copyParams.leftMargin = JFTheme.dp(this, 12);
        row.addView(copy, copyParams);
        row.setPadding(0, 0, 0, JFTheme.dp(this, 16));
        return row;
    }

    private void showPeopleMenu(View anchor) {
        PopupMenu menu = new PopupMenu(this, anchor);
        menu.getMenu().add(0, 0, 0, "全部人数");
        menu.getMenu().add(0, 1, 1, "2-4 人");
        menu.getMenu().add(0, 2, 2, "5-8 人");
        menu.getMenu().add(0, 3, 3, "9 人以上");
        menu.setOnMenuItemClickListener(item -> {
            peopleFilter = item.getItemId();
            peopleButton.setText(peopleFilterText());
            rebuildList();
            return true;
        });
        menu.show();
    }

    private void showMoodMenu(View anchor) {
        PopupMenu menu = new PopupMenu(this, anchor);
        menu.getMenu().add(0, 0, 0, "全部气氛");
        String[] moods = {
            JFSocialGameGuide.MOOD_ICEBREAKER,
            JFSocialGameGuide.MOOD_FRIENDS,
            JFSocialGameGuide.MOOD_LIVELY,
            JFSocialGameGuide.MOOD_THINKING
        };
        for (int index = 0; index < moods.length; index++) {
            menu.getMenu().add(0, index + 1, index + 1, moods[index]);
        }
        menu.setOnMenuItemClickListener(item -> {
            moodFilter = item.getItemId() == 0 ? null : moods[item.getItemId() - 1];
            moodButton.setText(moodFilter == null ? "全部气氛" : moodFilter);
            rebuildList();
            return true;
        });
        menu.show();
    }

    private String peopleFilterText() {
        if (peopleFilter == 1) return "2-4 人";
        if (peopleFilter == 2) return "5-8 人";
        if (peopleFilter == 3) return "9 人以上";
        return "全部人数";
    }

    private void rebuildList() {
        filtered.clear();
        listContainer.removeAllViews();
        for (JFSocialGameGuide guide : JFSocialGameGuide.all()) {
            if (matchesPeople(guide) && (moodFilter == null || moodFilter.equals(guide.mood))) {
                filtered.add(guide);
                listContainer.addView(guideCard(guide), spaced(-1, -2, 0, 10));
            }
        }
        if (filtered.isEmpty()) {
            LinearLayout empty = surface(0x14ffffff, 0x22ffffff);
            TextView label = JFTheme.label(this, "没有匹配的游戏，换一组筛选条件试试。",
                14, JFTheme.SUBTEXT, Typeface.NORMAL);
            label.setGravity(Gravity.CENTER);
            empty.addView(label);
            listContainer.addView(empty, new LinearLayout.LayoutParams(-1, JFTheme.dp(this, 96)));
        }
    }

    private boolean matchesPeople(JFSocialGameGuide guide) {
        if (peopleFilter == 1) return guide.minPlayers <= 4 && guide.maxPlayers >= 2;
        if (peopleFilter == 2) return guide.minPlayers <= 8 && guide.maxPlayers >= 5;
        if (peopleFilter == 3) return guide.maxPlayers >= 9;
        return true;
    }

    private View guideCard(JFSocialGameGuide guide) {
        int tint = moodColor(guide.mood);
        LinearLayout card = surface(JFTheme.blend(JFTheme.CARD_SOLID, tint, 0.13f), JFTheme.blend(tint, 0xffffffff, 0.08f));
        card.setOnClickListener(v -> showDetail(guide));

        LinearLayout titleRow = new LinearLayout(this);
        titleRow.setOrientation(LinearLayout.HORIZONTAL);
        titleRow.setGravity(Gravity.CENTER_VERTICAL);
        TextView title = JFTheme.label(this, guide.title, 19, JFTheme.TEXT, Typeface.BOLD);
        titleRow.addView(title, new LinearLayout.LayoutParams(0, -2, 1));
        TextView state = JFTheme.label(this, guide.playableInApp() ? "可直接开始" : "玩法指南",
            12, guide.playableInApp() ? JFTheme.ACCENT : JFTheme.SUBTEXT, Typeface.BOLD);
        titleRow.addView(state);
        card.addView(titleRow);

        card.addView(JFTheme.label(this, guide.subtitle, 13, JFTheme.SUBTEXT, Typeface.NORMAL));
        TextView meta = JFTheme.label(this,
            guide.playersText() + "  ·  " + guide.durationText() + "  ·  " + guide.mood,
            12, JFTheme.blend(JFTheme.TEXT, tint, 0.30f), Typeface.BOLD);
        card.addView(meta, spaced(-1, -2, 8, 0));
        return card;
    }

    private void showDetail(JFSocialGameGuide guide) {
        showingDetail = true;
        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        scroll.setBackground(JFTheme.bg());
        LinearLayout page = new LinearLayout(this);
        page.setOrientation(LinearLayout.VERTICAL);
        JFTheme.pad(page, 18, 16, 18, 28);
        scroll.addView(page, new ScrollView.LayoutParams(-1, -2));
        setContentView(scroll);

        page.addView(header(guide.title, guide.subtitle, this::showCatalog));

        LinearLayout hero = surface(JFTheme.blend(JFTheme.CARD_SOLID, moodColor(guide.mood), 0.18f), moodColor(guide.mood));
        hero.addView(JFTheme.label(this, guide.summary, 16, JFTheme.TEXT, Typeface.BOLD));
        hero.addView(JFTheme.label(this,
            guide.playersText() + "  ·  " + guide.durationText() + "  ·  " + guide.mood + "  ·  " + guide.props,
            12, JFTheme.SUBTEXT, Typeface.NORMAL), spaced(-1, -2, 10, 0));
        page.addView(hero, spaced(-1, -2, 0, 14));

        addDetailSection(page, "开局准备", guide.setup, null);
        addDetailSection(page, "怎么玩", null, guide.steps);
        addDetailSection(page, "玩得更舒服", null, guide.tips);

        if (guide.playableInApp()) {
            Button launch = JFTheme.primaryButton(this, "直接开始 " + guide.title);
            launch.setOnClickListener(v -> launchGuide(guide));
            page.addView(launch, spaced(-1, JFTheme.dp(this, 54), 4, 0));
        } else {
            TextView hint = JFTheme.label(this, "这项游戏无需专用页面，照着规则就能开局。",
                13, JFTheme.SUBTEXT, Typeface.NORMAL);
            hint.setGravity(Gravity.CENTER);
            page.addView(hint, spaced(-1, -2, 6, 0));
        }
    }

    private void addDetailSection(LinearLayout page, String title, String body, List<String> rows) {
        LinearLayout card = surface(0x18ffffff, 0x22ffffff);
        card.addView(JFTheme.label(this, title, 17, JFTheme.TEXT, Typeface.BOLD));
        if (body != null) {
            card.addView(JFTheme.label(this, body, 14, JFTheme.SUBTEXT, Typeface.NORMAL), spaced(-1, -2, 8, 0));
        }
        if (rows != null) {
            for (int index = 0; index < rows.size(); index++) {
                LinearLayout row = new LinearLayout(this);
                row.setOrientation(LinearLayout.HORIZONTAL);
                row.setGravity(Gravity.TOP);
                TextView number = JFTheme.label(this, String.valueOf(index + 1), 13, JFTheme.ACCENT, Typeface.BOLD);
                number.setGravity(Gravity.CENTER);
                number.setBackground(JFTheme.outlined(this, 0x16ffffff, 0x33ffffff));
                row.addView(number, new LinearLayout.LayoutParams(JFTheme.dp(this, 28), JFTheme.dp(this, 28)));
                TextView copy = JFTheme.label(this, rows.get(index), 14, JFTheme.SUBTEXT, Typeface.NORMAL);
                LinearLayout.LayoutParams copyParams = new LinearLayout.LayoutParams(0, -2, 1);
                copyParams.leftMargin = JFTheme.dp(this, 10);
                row.addView(copy, copyParams);
                card.addView(row, spaced(-1, -2, 10, 0));
            }
        }
        page.addView(card, spaced(-1, -2, 0, 12));
    }

    private void launchGuide(JFSocialGameGuide guide) {
        if ("NEVER_HAVE_I_EVER".equals(guide.launchKind)) {
            startActivity(new Intent(this, NeverHaveIEverActivity.class));
            return;
        }
        Intent intent = new Intent(this, GameActivity.class);
        intent.putExtra("kind", guide.launchKind);
        intent.putExtra("title", guide.title);
        startActivity(intent);
    }

    private LinearLayout surface(int fill, int stroke) {
        LinearLayout view = new LinearLayout(this);
        view.setOrientation(LinearLayout.VERTICAL);
        view.setBackground(JFTheme.outlined(this, fill, stroke));
        JFTheme.pad(view, 15, 14, 15, 14);
        return view;
    }

    private LinearLayout.LayoutParams spaced(int width, int height, int top, int bottom) {
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(width, height);
        params.topMargin = JFTheme.dp(this, top);
        params.bottomMargin = JFTheme.dp(this, bottom);
        return params;
    }

    private int moodColor(String mood) {
        if (JFSocialGameGuide.MOOD_ICEBREAKER.equals(mood)) return JFTheme.ACCENT;
        if (JFSocialGameGuide.MOOD_FRIENDS.equals(mood)) return JFTheme.SECONDARY;
        if (JFSocialGameGuide.MOOD_THINKING.equals(mood)) return JFTheme.PRIMARY;
        return JFTheme.WARNING;
    }

    @Override
    public void onBackPressed() {
        if (showingDetail) showCatalog();
        else super.onBackPressed();
    }
}
