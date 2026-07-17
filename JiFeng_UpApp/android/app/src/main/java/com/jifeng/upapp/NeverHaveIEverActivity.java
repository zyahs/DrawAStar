package com.jifeng.upapp;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.InputFilter;
import android.view.Gravity;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

public class NeverHaveIEverActivity extends Activity {
    private static final String KIND = "NEVER_HAVE_I_EVER";
    private static final String SERVICE_TYPE = "haveyounot";
    private static final String TYPE_STATE = "have_you_not_state";
    private static final String TYPE_STATEMENT = "have_you_not_statement";
    private static final String TYPE_VOTE = "have_you_not_vote";
    private static final String PHASE_LOBBY = "lobby";
    private static final String PHASE_STATEMENT = "statement";
    private static final String PHASE_VOTING = "voting";
    private static final String PHASE_RESULT = "result";
    private static final String PHASE_FINISHED = "finished";
    private static final String PREFS = "jf_have_you_not_profile_v1";
    private static final String KEY_DISPLAY_NAME = "display_name";

    private static final class Player {
        String peerId;
        String name;
        int fingers = 5;
    }

    private final Handler handler = new Handler(Looper.getMainLooper());
    private final ArrayList<Player> players = new ArrayList<>();
    private final HashMap<String, Boolean> votes = new HashMap<>();
    private final Set<String> resultNoPeerIds = new HashSet<>();

    private boolean host;
    private boolean destroyed;
    private boolean polling;
    private boolean hasAuthoritativeState;
    private boolean pendingStatement;
    private Boolean pendingVote;
    private boolean resultReported;
    private String displayName = "";
    private String roomId = "";
    private String selfPeerId = "";
    private String hostPeerId = "";
    private String phase = PHASE_LOBBY;
    private String speakerPeerId = "";
    private String statement = "";
    private String peerSignature = "";
    private int round;
    private int revision;
    private int lastAppliedRevision;
    private int latestSeq;
    private int settlementToken;

    private ScrollView scrollView;
    private LinearLayout pageRoot;
    private EditText statementInput;

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        JFTheme.apply(this);
        displayName = getSharedPreferences(PREFS, MODE_PRIVATE).getString(KEY_DISPLAY_NAME, "");
        render();
        ensureDisplayName();
    }

    @Override
    protected void onDestroy() {
        destroyed = true;
        handler.removeCallbacksAndMessages(null);
        super.onDestroy();
    }

    private void ensureDisplayName() {
        if (displayName != null && displayName.trim().length() >= 2) {
            ensureBackendIdentity();
            return;
        }
        EditText input = new EditText(this);
        input.setHint("输入 2-16 个字符的昵称");
        input.setSingleLine(true);
        input.setFilters(new InputFilter[]{new InputFilter.LengthFilter(16)});
        input.setTextColor(JFTheme.TEXT);
        input.setHintTextColor(JFTheme.SUBTEXT);
        AlertDialog dialog = new AlertDialog.Builder(this)
            .setTitle("创建玩家账号")
            .setMessage("这个昵称会展示给房间里的所有玩家。")
            .setView(input)
            .setCancelable(false)
            .setPositiveButton("创建并进入", null)
            .create();
        dialog.setOnShowListener(ignored -> dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(v -> {
            String name = input.getText().toString().trim();
            if (name.length() < 2) {
                input.setError("昵称至少需要 2 个字符");
                return;
            }
            displayName = name;
            getSharedPreferences(PREFS, MODE_PRIVATE).edit().putString(KEY_DISPLAY_NAME, name).apply();
            dialog.dismiss();
            ensureBackendIdentity();
        }));
        dialog.show();
    }

    private void ensureBackendIdentity() {
        JFApiClient.ensureGuest(this, (json, error) -> runOnUiThread(() -> {
            if (destroyed) return;
            if (error != null) {
                showConnectionError("账号连接失败，请检查网络后重试。");
                return;
            }
            showModeMenu();
        }));
    }

    private void showModeMenu() {
        new AlertDialog.Builder(this)
            .setTitle("我有你没有")
            .setMessage("每个人使用自己的手机加入同一房间。")
            .setItems(new String[]{"创建房间", "加入房间"}, (dialog, which) -> {
                if (which == 0) createRoom();
                else showJoinDialog();
            })
            .setOnCancelListener(dialog -> finish())
            .show();
    }

    private void showJoinDialog() {
        EditText input = new EditText(this);
        input.setHint("例如 A1B2C3");
        input.setSingleLine(true);
        input.setAllCaps(true);
        input.setFilters(new InputFilter[]{new InputFilter.LengthFilter(6)});
        input.setTextColor(JFTheme.TEXT);
        input.setHintTextColor(JFTheme.SUBTEXT);
        new AlertDialog.Builder(this)
            .setTitle("加入房间")
            .setMessage("输入房主分享的 6 位房间码；留空会加入最近创建的房间。")
            .setView(input)
            .setNegativeButton("取消", (dialog, which) -> showModeMenu())
            .setPositiveButton("加入", (dialog, which) -> {
                String code = input.getText().toString().trim().toUpperCase(Locale.ROOT);
                if (code.isEmpty()) joinLatestRoom();
                else joinRoom(code);
            })
            .show();
    }

    private void createRoom() {
        host = true;
        phase = PHASE_LOBBY;
        render();
        try {
            JSONObject body = new JSONObject();
            body.put("kind", KIND);
            body.put("serviceType", SERVICE_TYPE);
            body.put("displayName", displayName);
            JFApiClient.post("/multiplayer/rooms", body, (json, error) -> runOnUiThread(() -> {
                if (destroyed) return;
                if (error != null || json == null || json.optString("roomId").isEmpty()) {
                    showConnectionError(messageFrom(json, "创建房间失败"));
                    return;
                }
                handleSnapshot(json);
                startPolling();
            }));
        } catch (Exception error) {
            showConnectionError("创建房间失败");
        }
    }

    private void joinLatestRoom() {
        String path = "/multiplayer/rooms?kind=" + KIND + "&serviceType=" + SERVICE_TYPE;
        JFApiClient.get(path, (json, error) -> runOnUiThread(() -> {
            JSONArray rooms = json == null ? null : json.optJSONArray("data");
            JSONObject first = rooms == null || rooms.length() == 0 ? null : rooms.optJSONObject(0);
            String code = first == null ? "" : first.optString("roomId");
            if (code.isEmpty()) {
                showConnectionError("暂时没有可加入的房间");
                return;
            }
            joinRoom(code);
        }));
    }

    private void joinRoom(String code) {
        host = false;
        roomId = code;
        phase = PHASE_LOBBY;
        render();
        try {
            JSONObject body = new JSONObject();
            body.put("serviceType", SERVICE_TYPE);
            body.put("displayName", displayName);
            JFApiClient.post("/multiplayer/rooms/" + code + "/join", body, (json, error) -> runOnUiThread(() -> {
                if (destroyed) return;
                if (error != null || json == null || json.optString("roomId").isEmpty()) {
                    showConnectionError(messageFrom(json, "加入房间失败"));
                    return;
                }
                handleSnapshot(json);
                startPolling();
            }));
        } catch (Exception error) {
            showConnectionError("加入房间失败");
        }
    }

    private void startPolling() {
        if (polling) return;
        polling = true;
        pollRoom();
    }

    private void pollRoom() {
        if (destroyed || roomId.isEmpty()) return;
        JFApiClient.get("/multiplayer/rooms/" + roomId + "?since=" + latestSeq, (json, error) -> runOnUiThread(() -> {
            if (destroyed) return;
            if (json != null && error == null && json.optString("roomId").length() > 0) handleSnapshot(json);
            handler.postDelayed(this::pollRoom, 1500);
        }));
    }

    private void handleSnapshot(JSONObject snapshot) {
        roomId = snapshot.optString("roomId", roomId);
        selfPeerId = snapshot.optString("selfPeerId", selfPeerId);
        hostPeerId = snapshot.optString("hostPeerId", hostPeerId);
        JSONArray peers = snapshot.optJSONArray("peers");
        boolean changed = false;
        if (PHASE_LOBBY.equals(phase) && (host || !hasAuthoritativeState)) changed = syncLobbyPlayers(peers);

        JSONArray messages = snapshot.optJSONArray("messages");
        if (messages != null) {
            for (int index = 0; index < messages.length(); index++) {
                JSONObject message = messages.optJSONObject(index);
                if (message == null) continue;
                latestSeq = Math.max(latestSeq, message.optInt("seq"));
                String from = message.optString("from");
                if (from.equals(selfPeerId)) continue;
                String type = message.optString("type");
                JSONObject payload = message.optJSONObject("payload");
                if (TYPE_STATE.equals(type) && !host && from.equals(hostPeerId)) {
                    changed = applyState(payload) || changed;
                } else if (host && TYPE_STATEMENT.equals(type)) {
                    hostAcceptStatement(payload == null ? "" : payload.optString("statement"), from,
                        payload == null ? 0 : payload.optInt("round"));
                    changed = true;
                } else if (host && TYPE_VOTE.equals(type)) {
                    hostAcceptVote(payload != null && payload.optBoolean("has"), from,
                        payload == null ? 0 : payload.optInt("round"));
                    changed = true;
                }
            }
        }
        latestSeq = Math.max(latestSeq, snapshot.optInt("latestSeq", latestSeq));
        if (host && PHASE_LOBBY.equals(phase) && changed && !roomId.isEmpty()) broadcastState();
        if (changed || pageRoot == null) render();
    }

    private boolean syncLobbyPlayers(JSONArray peers) {
        if (peers == null) return false;
        StringBuilder signature = new StringBuilder();
        ArrayList<Player> next = new ArrayList<>();
        for (int index = 0; index < peers.length(); index++) {
            JSONObject peer = peers.optJSONObject(index);
            if (peer == null) continue;
            String peerId = peer.optString("peerId");
            if (peerId.isEmpty()) continue;
            String name = peer.optString("displayName", "玩家");
            signature.append(peerId).append(':').append(name).append('|');
            Player existing = playerForId(peerId);
            Player player = existing == null ? new Player() : existing;
            player.peerId = peerId;
            player.name = name;
            player.fingers = 5;
            next.add(player);
        }
        if (signature.toString().equals(peerSignature) && !players.isEmpty()) return false;
        peerSignature = signature.toString();
        players.clear();
        players.addAll(next);
        hasAuthoritativeState = host;
        return true;
    }

    private boolean applyState(JSONObject payload) {
        if (payload == null) return false;
        int incomingRevision = payload.optInt("revision");
        if (incomingRevision > 0 && incomingRevision <= lastAppliedRevision) return false;
        JSONArray rawPlayers = payload.optJSONArray("players");
        if (rawPlayers == null) return false;

        String oldPhase = phase;
        int oldRound = round;
        players.clear();
        for (int index = 0; index < rawPlayers.length(); index++) {
            JSONObject item = rawPlayers.optJSONObject(index);
            if (item == null || item.optString("peerId").isEmpty()) continue;
            Player player = new Player();
            player.peerId = item.optString("peerId");
            player.name = item.optString("name", "玩家");
            player.fingers = Math.max(0, Math.min(5, item.optInt("fingers", 5)));
            players.add(player);
        }
        phase = payload.optString("phase", PHASE_LOBBY);
        round = payload.optInt("round");
        hostPeerId = payload.optString("hostPeerId", hostPeerId);
        speakerPeerId = payload.optString("speakerPeerId");
        statement = payload.optString("statement");
        votes.clear();
        JSONObject rawVotes = payload.optJSONObject("votes");
        if (rawVotes != null) {
            Iterator<String> keys = rawVotes.keys();
            while (keys.hasNext()) {
                String key = keys.next();
                votes.put(key, rawVotes.optBoolean(key));
            }
        }
        resultNoPeerIds.clear();
        JSONArray rawResult = payload.optJSONArray("resultNoPeerIds");
        if (rawResult != null) {
            for (int index = 0; index < rawResult.length(); index++) {
                String peerId = rawResult.optString(index);
                if (!peerId.isEmpty()) resultNoPeerIds.add(peerId);
            }
        }
        lastAppliedRevision = Math.max(lastAppliedRevision, incomingRevision);
        hasAuthoritativeState = true;
        if (votes.containsKey(selfPeerId)) pendingVote = null;
        if (!PHASE_STATEMENT.equals(phase) || !speakerPeerId.equals(selfPeerId)) pendingStatement = false;
        if (oldRound != round) {
            pendingVote = null;
            pendingStatement = false;
        }
        if ((PHASE_LOBBY.equals(oldPhase) || PHASE_FINISHED.equals(oldPhase)) && !PHASE_LOBBY.equals(phase)) {
            resultReported = false;
        }
        return true;
    }

    private void startGame() {
        if (!host || players.size() < 2) return;
        settlementToken++;
        for (Player player : players) player.fingers = 5;
        phase = PHASE_STATEMENT;
        round = 1;
        speakerPeerId = players.get(0).peerId;
        statement = "";
        votes.clear();
        resultNoPeerIds.clear();
        pendingVote = null;
        pendingStatement = false;
        resultReported = false;
        broadcastState();
        render();
    }

    private void submitStatement() {
        String text = statementInput == null ? "" : statementInput.getText().toString().trim();
        if (text.isEmpty()) {
            Toast.makeText(this, "先说一件自己有的事", Toast.LENGTH_SHORT).show();
            return;
        }
        if (!text.startsWith("我有")) text = "我有" + text;
        if (text.length() < 4) {
            Toast.makeText(this, "再说具体一点吧", Toast.LENGTH_SHORT).show();
            return;
        }
        dismissKeyboard();
        if (host) {
            hostAcceptStatement(text, selfPeerId, round);
        } else {
            pendingStatement = true;
            JSONObject payload = new JSONObject();
            try {
                payload.put("round", round);
                payload.put("statement", text);
            } catch (Exception ignored) {
            }
            sendMessage(TYPE_STATEMENT, payload);
            render();
            int expectedRound = round;
            handler.postDelayed(() -> {
                if (expectedRound == round && pendingStatement && PHASE_STATEMENT.equals(phase)) {
                    pendingStatement = false;
                    render();
                    Toast.makeText(this, "发言尚未同步，请再试一次", Toast.LENGTH_SHORT).show();
                }
            }, 4000);
        }
    }

    private void submitVote(boolean hasIt) {
        Player local = playerForId(selfPeerId);
        if (local == null || local.fingers <= 0 || speakerPeerId.equals(selfPeerId) || votes.containsKey(selfPeerId)) return;
        if (host) {
            hostAcceptVote(hasIt, selfPeerId, round);
        } else {
            pendingVote = hasIt;
            JSONObject payload = new JSONObject();
            try {
                payload.put("round", round);
                payload.put("has", hasIt);
            } catch (Exception ignored) {
            }
            sendMessage(TYPE_VOTE, payload);
            render();
            int expectedRound = round;
            handler.postDelayed(() -> {
                if (expectedRound == round && pendingVote != null && !votes.containsKey(selfPeerId)) {
                    pendingVote = null;
                    render();
                    Toast.makeText(this, "投票尚未同步，请再试一次", Toast.LENGTH_SHORT).show();
                }
            }, 4000);
        }
    }

    private void hostAcceptStatement(String text, String fromPeerId, int messageRound) {
        if (!host || !PHASE_STATEMENT.equals(phase) || messageRound != round) return;
        if (!speakerPeerId.equals(fromPeerId) || text == null || text.trim().isEmpty()) return;
        statement = text.trim();
        phase = PHASE_VOTING;
        votes.clear();
        pendingStatement = false;
        broadcastState();
        render();
    }

    private void hostAcceptVote(boolean hasIt, String fromPeerId, int messageRound) {
        if (!host || !PHASE_VOTING.equals(phase) || messageRound != round) return;
        Player player = playerForId(fromPeerId);
        if (player == null || player.fingers <= 0 || speakerPeerId.equals(fromPeerId) || votes.containsKey(fromPeerId)) return;
        votes.put(fromPeerId, hasIt);
        if (fromPeerId.equals(selfPeerId)) pendingVote = null;
        if (submittedVoteCount() >= requiredVoterCount()) settleVotes();
        else {
            broadcastState();
            render();
        }
    }

    private void settleVotes() {
        resultNoPeerIds.clear();
        for (Player player : players) {
            Boolean vote = votes.get(player.peerId);
            if (player.fingers > 0 && !player.peerId.equals(speakerPeerId) && vote != null && !vote) {
                player.fingers = Math.max(0, player.fingers - 1);
                resultNoPeerIds.add(player.peerId);
            }
        }
        phase = PHASE_RESULT;
        settlementToken++;
        int token = settlementToken;
        broadcastState();
        render();
        handler.postDelayed(() -> {
            if (host && token == settlementToken && PHASE_RESULT.equals(phase)) advanceRound();
        }, 1600);
    }

    private void advanceRound() {
        if (activePlayerCount() <= 1) {
            phase = PHASE_FINISHED;
            broadcastState();
            render();
            return;
        }
        int current = indexOfPlayer(speakerPeerId);
        for (int offset = 1; offset <= players.size(); offset++) {
            Player candidate = players.get((current + offset) % players.size());
            if (candidate.fingers > 0) {
                speakerPeerId = candidate.peerId;
                break;
            }
        }
        round++;
        phase = PHASE_STATEMENT;
        statement = "";
        votes.clear();
        resultNoPeerIds.clear();
        pendingVote = null;
        pendingStatement = false;
        broadcastState();
        render();
    }

    private void broadcastState() {
        if (!host || roomId.isEmpty()) return;
        revision++;
        JSONObject payload = new JSONObject();
        JSONArray playerArray = new JSONArray();
        JSONObject voteObject = new JSONObject();
        JSONArray resultArray = new JSONArray();
        try {
            for (Player player : players) {
                JSONObject item = new JSONObject();
                item.put("peerId", player.peerId);
                item.put("name", player.name);
                item.put("fingers", player.fingers);
                playerArray.put(item);
            }
            for (Map.Entry<String, Boolean> entry : votes.entrySet()) voteObject.put(entry.getKey(), entry.getValue());
            for (String peerId : resultNoPeerIds) resultArray.put(peerId);
            payload.put("version", 1);
            payload.put("revision", revision);
            payload.put("phase", phase);
            payload.put("round", round);
            payload.put("hostPeerId", hostPeerId);
            payload.put("speakerPeerId", speakerPeerId);
            payload.put("statement", statement);
            payload.put("players", playerArray);
            payload.put("votes", voteObject);
            payload.put("resultNoPeerIds", resultArray);
        } catch (Exception ignored) {
        }
        sendMessage(TYPE_STATE, payload);
    }

    private void sendMessage(String type, JSONObject payload) {
        if (roomId.isEmpty()) return;
        try {
            JSONObject body = new JSONObject();
            body.put("type", type);
            body.put("payload", payload == null ? new JSONObject() : payload);
            JFApiClient.post("/multiplayer/rooms/" + roomId + "/messages", body, (json, error) -> {
            });
        } catch (Exception ignored) {
        }
    }

    private void render() {
        if (destroyed) return;
        scrollView = new ScrollView(this);
        scrollView.setFillViewport(true);
        scrollView.setBackground(JFTheme.bg());
        pageRoot = new LinearLayout(this);
        pageRoot.setOrientation(LinearLayout.VERTICAL);
        JFTheme.pad(pageRoot, 18, 14, 18, 28);
        scrollView.addView(pageRoot, new ScrollView.LayoutParams(-1, -2));
        setContentView(scrollView);
        addHeader();

        if (roomId.isEmpty()) {
            LinearLayout intro = surface();
            intro.addView(label("每个人都在自己的手机上操作", 19, JFTheme.TEXT, Typeface.BOLD));
            intro.addView(label("创建或加入同一个房间后，昵称、剩余手指与投票进度都会实时显示。", 14, JFTheme.SUBTEXT, Typeface.NORMAL), spaced(-1, -2, 7, 0));
            pageRoot.addView(intro);
            return;
        }
        if (PHASE_LOBBY.equals(phase)) renderLobby();
        else renderGame();
    }

    private void addHeader() {
        LinearLayout header = new LinearLayout(this);
        header.setOrientation(LinearLayout.HORIZONTAL);
        header.setGravity(Gravity.CENTER_VERTICAL);
        Button back = JFTheme.secondaryButton(this, "返回");
        back.setOnClickListener(v -> finish());
        header.addView(back, new LinearLayout.LayoutParams(JFTheme.dp(this, 70), JFTheme.dp(this, 44)));

        LinearLayout copy = new LinearLayout(this);
        copy.setOrientation(LinearLayout.VERTICAL);
        copy.addView(label("我有你没有", 26, JFTheme.TEXT, Typeface.BOLD));
        String subtitle = roomId.isEmpty() ? "实时房间 · 轮流发言 · 全员投票"
            : "房间 " + roomId + " · " + (host ? "房主" : "玩家");
        copy.addView(label(subtitle, 12, JFTheme.SUBTEXT, Typeface.NORMAL));
        LinearLayout.LayoutParams copyParams = new LinearLayout.LayoutParams(0, -2, 1);
        copyParams.leftMargin = JFTheme.dp(this, 10);
        header.addView(copy, copyParams);

        Button rules = JFTheme.secondaryButton(this, "规则");
        rules.setOnClickListener(v -> showRules());
        header.addView(rules, new LinearLayout.LayoutParams(JFTheme.dp(this, 64), JFTheme.dp(this, 44)));
        pageRoot.addView(header, spaced(-1, -2, 0, 15));
    }

    private void renderLobby() {
        LinearLayout room = surface();
        room.setBackground(JFTheme.outlined(this, JFTheme.blend(JFTheme.CARD_SOLID, JFTheme.PRIMARY, 0.15f), JFTheme.blend(JFTheme.PRIMARY, 0xffffffff, 0.18f)));
        LinearLayout roomRow = new LinearLayout(this);
        roomRow.setOrientation(LinearLayout.HORIZONTAL);
        roomRow.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout codeCopy = new LinearLayout(this);
        codeCopy.setOrientation(LinearLayout.VERTICAL);
        codeCopy.addView(label("房间码", 12, JFTheme.SUBTEXT, Typeface.BOLD));
        codeCopy.addView(label(roomId, 26, JFTheme.TEXT, Typeface.BOLD));
        roomRow.addView(codeCopy, new LinearLayout.LayoutParams(0, -2, 1));
        Button copy = JFTheme.secondaryButton(this, "复制");
        copy.setOnClickListener(v -> copyRoomCode());
        roomRow.addView(copy, new LinearLayout.LayoutParams(JFTheme.dp(this, 84), JFTheme.dp(this, 44)));
        room.addView(roomRow);
        pageRoot.addView(room, spaced(-1, -2, 0, 12));

        LinearLayout rule = surface();
        rule.addView(label("这一局怎么进行", 18, JFTheme.TEXT, Typeface.BOLD));
        rule.addView(label("轮到你时说一件“我有”的事。其他人选择“我有”或“我没有”，选“我没有”的玩家熄灭一根。全员投完自动进入下一位。", 14, JFTheme.SUBTEXT, Typeface.NORMAL), spaced(-1, -2, 7, 0));
        pageRoot.addView(rule, spaced(-1, -2, 0, 13));
        addPlayers();
        if (host) {
            Button start = JFTheme.primaryButton(this, players.size() >= 2 ? "开始游戏" : "至少等待 2 位玩家");
            start.setEnabled(players.size() >= 2);
            start.setAlpha(start.isEnabled() ? 1f : 0.48f);
            start.setOnClickListener(v -> startGame());
            pageRoot.addView(start, spaced(-1, JFTheme.dp(this, 54), 5, 0));
        } else {
            TextView waiting = label("等待房主开始游戏…", 15, JFTheme.SUBTEXT, Typeface.BOLD);
            waiting.setGravity(Gravity.CENTER);
            pageRoot.addView(waiting, spaced(-1, JFTheme.dp(this, 50), 5, 0));
        }
    }

    private void renderGame() {
        Player speaker = playerForId(speakerPeerId);
        LinearLayout turn = surface();
        turn.setBackground(JFTheme.outlined(this, JFTheme.blend(JFTheme.CARD_SOLID, JFTheme.ACCENT, 0.13f), JFTheme.blend(JFTheme.ACCENT, 0xffffffff, 0.12f)));
        turn.addView(label("第 " + Math.max(1, round) + " 轮", 13, JFTheme.ACCENT, Typeface.BOLD));
        turn.addView(label(PHASE_FINISHED.equals(phase) ? "本局结束" : (speaker == null ? "等待同步" : speaker.name + " 的回合"), 24, JFTheme.TEXT, Typeface.BOLD), spaced(-1, -2, 3, 0));
        pageRoot.addView(turn, spaced(-1, -2, 0, 12));

        if (PHASE_STATEMENT.equals(phase)) renderStatementTurn(speaker);
        else if (PHASE_VOTING.equals(phase)) renderVoting(speaker);
        else if (PHASE_RESULT.equals(phase)) renderResult(speaker);
        else if (PHASE_FINISHED.equals(phase)) renderWinner();
        addPlayers();
        if (PHASE_FINISHED.equals(phase) && host) {
            Button restart = JFTheme.primaryButton(this, "用当前玩家再来一局");
            restart.setOnClickListener(v -> startGame());
            pageRoot.addView(restart, spaced(-1, JFTheme.dp(this, 54), 5, 0));
        }
        reportResultIfNeeded();
    }

    private void renderStatementTurn(Player speaker) {
        LinearLayout panel = surface();
        boolean myTurn = speakerPeerId.equals(selfPeerId);
        panel.addView(label(myTurn ? "轮到你说一件自己有的事" : "等待 " + (speaker == null ? "当前玩家" : speaker.name) + " 发言", 18, JFTheme.TEXT, Typeface.BOLD));
        if (myTurn) {
            statementInput = new EditText(this);
            statementInput.setHint("例如：我有独自旅行过");
            statementInput.setSingleLine(true);
            statementInput.setFilters(new InputFilter[]{new InputFilter.LengthFilter(60)});
            statementInput.setTextColor(JFTheme.TEXT);
            statementInput.setHintTextColor(JFTheme.SUBTEXT);
            statementInput.setBackground(JFTheme.outlined(this, 0x12ffffff, 0x22ffffff));
            JFTheme.pad(statementInput, 12, 0, 12, 0);
            statementInput.setEnabled(!pendingStatement);
            panel.addView(statementInput, spaced(-1, JFTheme.dp(this, 50), 12, 10));
            Button submit = JFTheme.primaryButton(this, pendingStatement ? "等待房主确认…" : "说完了，开始投票");
            submit.setEnabled(!pendingStatement);
            submit.setAlpha(submit.isEnabled() ? 1f : 0.55f);
            submit.setOnClickListener(v -> submitStatement());
            panel.addView(submit, new LinearLayout.LayoutParams(-1, JFTheme.dp(this, 52)));
        } else {
            panel.addView(label("发言提交后，其他玩家的投票按钮会同时出现。", 14, JFTheme.SUBTEXT, Typeface.NORMAL), spaced(-1, -2, 8, 0));
        }
        pageRoot.addView(panel, spaced(-1, -2, 0, 12));
    }

    private void renderVoting(Player speaker) {
        pageRoot.addView(statementPanel(speaker, false), spaced(-1, -2, 0, 10));
        TextView progress = label(submittedVoteCount() + " / " + requiredVoterCount() + " 人已投票", 15, JFTheme.SUBTEXT, Typeface.BOLD);
        progress.setGravity(Gravity.CENTER);
        pageRoot.addView(progress, spaced(-1, JFTheme.dp(this, 40), 0, 6));
        Player local = playerForId(selfPeerId);
        boolean canVote = local != null && local.fingers > 0 && !speakerPeerId.equals(selfPeerId);
        Boolean choice = votes.containsKey(selfPeerId) ? votes.get(selfPeerId) : pendingVote;
        if (!canVote) {
            TextView waiting = label(speakerPeerId.equals(selfPeerId) ? "你是本轮发言者，等待其他人投票" : "本轮等待其他玩家投票", 14, JFTheme.SUBTEXT, Typeface.BOLD);
            waiting.setGravity(Gravity.CENTER);
            pageRoot.addView(waiting, spaced(-1, JFTheme.dp(this, 46), 0, 10));
            return;
        }
        if (choice != null) {
            String text = (votes.containsKey(selfPeerId) ? "已选择：" : "正在提交：") + (choice ? "我有" : "我没有");
            TextView selected = label(text, 18, choice ? JFTheme.ACCENT : JFTheme.WARNING, Typeface.BOLD);
            selected.setGravity(Gravity.CENTER);
            pageRoot.addView(selected, spaced(-1, JFTheme.dp(this, 54), 0, 10));
            return;
        }
        LinearLayout buttons = new LinearLayout(this);
        buttons.setOrientation(LinearLayout.HORIZONTAL);
        Button have = JFTheme.primaryButton(this, "我有");
        have.setBackground(JFTheme.outlined(this, JFTheme.ACCENT, JFTheme.blend(JFTheme.ACCENT, 0xffffffff, 0.2f)));
        have.setOnClickListener(v -> submitVote(true));
        Button haveNot = JFTheme.primaryButton(this, "我没有");
        haveNot.setBackground(JFTheme.outlined(this, JFTheme.WARNING, JFTheme.blend(JFTheme.WARNING, 0xffffffff, 0.2f)));
        haveNot.setTextColor(0xff181818);
        haveNot.setOnClickListener(v -> submitVote(false));
        buttons.addView(have, new LinearLayout.LayoutParams(0, JFTheme.dp(this, 58), 1));
        LinearLayout.LayoutParams noParams = new LinearLayout.LayoutParams(0, JFTheme.dp(this, 58), 1);
        noParams.leftMargin = JFTheme.dp(this, 10);
        buttons.addView(haveNot, noParams);
        pageRoot.addView(buttons, spaced(-1, -2, 0, 6));
        TextView hint = label("选择“我没有”会在结算时熄灭一根手指", 12, JFTheme.SUBTEXT, Typeface.NORMAL);
        hint.setGravity(Gravity.CENTER);
        pageRoot.addView(hint, spaced(-1, -2, 0, 11));
    }

    private void renderResult(Player speaker) {
        pageRoot.addView(statementPanel(speaker, true), spaced(-1, -2, 0, 12));
    }

    private LinearLayout statementPanel(Player speaker, boolean showResult) {
        LinearLayout panel = surface();
        panel.addView(label((speaker == null ? "当前玩家" : speaker.name) + " 说", 12, JFTheme.SUBTEXT, Typeface.BOLD));
        panel.addView(label(statement.isEmpty() ? "等待发言…" : statement, 23, JFTheme.TEXT, Typeface.BOLD), spaced(-1, -2, 5, 0));
        if (showResult) {
            String result;
            int color;
            if (resultNoPeerIds.isEmpty()) {
                result = "大家都有，所有人的手指都保留";
                color = JFTheme.ACCENT;
            } else {
                ArrayList<String> names = new ArrayList<>();
                for (Player player : players) if (resultNoPeerIds.contains(player.peerId)) names.add(player.name);
                result = android.text.TextUtils.join("、", names) + " 选择了“我没有”，各熄灭一根";
                color = JFTheme.WARNING;
            }
            panel.addView(label(result, 14, color, Typeface.BOLD), spaced(-1, -2, 10, 0));
        }
        return panel;
    }

    private void renderWinner() {
        Player winner = null;
        for (Player player : players) if (player.fingers > 0) { winner = player; break; }
        LinearLayout panel = surface();
        panel.setBackground(JFTheme.outlined(this, JFTheme.blend(JFTheme.CARD_SOLID, JFTheme.ACCENT, 0.14f), JFTheme.ACCENT));
        TextView crown = label("♛", 42, JFTheme.ACCENT, Typeface.BOLD);
        crown.setGravity(Gravity.CENTER);
        panel.addView(crown);
        TextView title = label(winner == null ? "本局结束" : winner.name + " 留到了最后", 22, JFTheme.TEXT, Typeface.BOLD);
        title.setGravity(Gravity.CENTER);
        panel.addView(title);
        pageRoot.addView(panel, spaced(-1, -2, 0, 13));
    }

    private void addPlayers() {
        pageRoot.addView(label("玩家状态 · " + players.size() + " 人", 18, JFTheme.TEXT, Typeface.BOLD), spaced(-1, -2, 2, 8));
        if (players.isEmpty()) {
            pageRoot.addView(label("正在同步房间成员…", 14, JFTheme.SUBTEXT, Typeface.NORMAL));
            return;
        }
        for (Player player : players) pageRoot.addView(playerRow(player), spaced(-1, -2, 0, 9));
    }

    private LinearLayout playerRow(Player player) {
        LinearLayout row = surface();
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        if (player.peerId.equals(speakerPeerId) && !PHASE_FINISHED.equals(phase)) {
            row.setBackground(JFTheme.outlined(this, JFTheme.blend(JFTheme.CARD_SOLID, JFTheme.ACCENT, 0.08f), JFTheme.ACCENT));
        } else if (PHASE_RESULT.equals(phase) && resultNoPeerIds.contains(player.peerId)) {
            row.setBackground(JFTheme.outlined(this, JFTheme.blend(JFTheme.CARD_SOLID, JFTheme.WARNING, 0.09f), JFTheme.WARNING));
        }

        TextView avatar = label(initial(player.name), 17, JFTheme.TEXT, Typeface.BOLD);
        avatar.setGravity(Gravity.CENTER);
        avatar.setBackground(JFTheme.outlined(this, JFTheme.blend(JFTheme.CARD_SOLID, JFTheme.ACCENT, 0.16f), 0x22ffffff));
        row.addView(avatar, new LinearLayout.LayoutParams(JFTheme.dp(this, 42), JFTheme.dp(this, 42)));

        LinearLayout copy = new LinearLayout(this);
        copy.setOrientation(LinearLayout.VERTICAL);
        String name = player.name;
        if (player.peerId.equals(selfPeerId)) name += "（我）";
        if (player.peerId.equals(hostPeerId)) name += " · 房主";
        copy.addView(label(name, 15, player.fingers > 0 ? JFTheme.TEXT : JFTheme.SUBTEXT, Typeface.BOLD));
        copy.addView(label(statusFor(player), 12, statusColorFor(player), Typeface.NORMAL));
        LinearLayout.LayoutParams copyParams = new LinearLayout.LayoutParams(0, -2, 1);
        copyParams.leftMargin = JFTheme.dp(this, 10);
        row.addView(copy, copyParams);

        FingerHandView hand = new FingerHandView(this);
        hand.setActiveCount(player.fingers);
        hand.setLosingFinger(PHASE_RESULT.equals(phase) && resultNoPeerIds.contains(player.peerId));
        row.addView(hand, new LinearLayout.LayoutParams(JFTheme.dp(this, 88), JFTheme.dp(this, 62)));
        TextView count = label(String.valueOf(player.fingers), 18, player.fingers > 0 ? JFTheme.TEXT : JFTheme.SUBTEXT, Typeface.BOLD);
        count.setGravity(Gravity.END | Gravity.CENTER_VERTICAL);
        row.addView(count, new LinearLayout.LayoutParams(JFTheme.dp(this, 24), JFTheme.dp(this, 62)));
        return row;
    }

    private String statusFor(Player player) {
        if (player.fingers <= 0) return "手指已全部熄灭";
        if (PHASE_LOBBY.equals(phase)) return "已加入 · 剩余 5 根";
        if (PHASE_FINISHED.equals(phase)) return "本局胜者";
        if (player.peerId.equals(speakerPeerId)) return "本轮发言者";
        if (PHASE_VOTING.equals(phase)) {
            if (votes.containsKey(player.peerId)) return "已投票";
            if (player.peerId.equals(selfPeerId) && pendingVote != null) return "正在提交投票";
            return "等待投票";
        }
        if (PHASE_RESULT.equals(phase)) {
            if (resultNoPeerIds.contains(player.peerId)) return "我没有 · 熄灭 1 根";
            if (Boolean.TRUE.equals(votes.get(player.peerId))) return "我有 · 保留手指";
        }
        return "剩余 " + player.fingers + " 根";
    }

    private int statusColorFor(Player player) {
        if (player.fingers <= 0) return JFTheme.SUBTEXT;
        if (PHASE_FINISHED.equals(phase)) return JFTheme.ACCENT;
        if (player.peerId.equals(speakerPeerId)) return JFTheme.ACCENT;
        if (resultNoPeerIds.contains(player.peerId)) return JFTheme.WARNING;
        if (votes.containsKey(player.peerId)) return JFTheme.ACCENT;
        return JFTheme.SUBTEXT;
    }

    private void reportResultIfNeeded() {
        if (!PHASE_FINISHED.equals(phase) || resultReported) return;
        resultReported = true;
        Player local = playerForId(selfPeerId);
        int score = (local == null ? 0 : local.fingers * 100) + Math.min(round, 99);
        try {
            JSONObject body = new JSONObject();
            body.put("kind", KIND);
            body.put("score", score);
            body.put("win", local != null && local.fingers > 0);
            JFApiClient.post("/games/records", body, (json, error) -> {
            });
        } catch (Exception ignored) {
        }
    }

    private Player playerForId(String peerId) {
        if (peerId == null || peerId.isEmpty()) return null;
        for (Player player : players) if (peerId.equals(player.peerId)) return player;
        return null;
    }

    private int indexOfPlayer(String peerId) {
        for (int index = 0; index < players.size(); index++) if (players.get(index).peerId.equals(peerId)) return index;
        return 0;
    }

    private int activePlayerCount() {
        int count = 0;
        for (Player player : players) if (player.fingers > 0) count++;
        return count;
    }

    private int requiredVoterCount() {
        int count = 0;
        for (Player player : players) if (player.fingers > 0 && !player.peerId.equals(speakerPeerId)) count++;
        return count;
    }

    private int submittedVoteCount() {
        int count = 0;
        for (Player player : players) {
            if (player.fingers > 0 && !player.peerId.equals(speakerPeerId) && votes.containsKey(player.peerId)) count++;
        }
        return count;
    }

    private void copyRoomCode() {
        ClipboardManager clipboard = (ClipboardManager) getSystemService(CLIPBOARD_SERVICE);
        if (clipboard != null) clipboard.setPrimaryClip(ClipData.newPlainText("房间码", roomId));
        Toast.makeText(this, "房间码已复制", Toast.LENGTH_SHORT).show();
    }

    private void showRules() {
        String rules = "1. 每位玩家用自己的手机加入同一房间，从五根手指开始。\n\n"
            + "2. 按房间顺序轮流发言。轮到你时，说一件自己有、但别人可能没有的事。\n\n"
            + "3. 除发言者外，所有仍有手指的玩家选择“我有”或“我没有”。\n\n"
            + "4. 选择“我没有”的玩家熄灭一根。全员投完后自动结算并轮到下一位。\n\n"
            + "5. 手指归零后不再参与发言和投票，最后仍有手指的玩家获胜。";
        new AlertDialog.Builder(this)
            .setTitle("我有你没有怎么玩")
            .setMessage(rules)
            .setPositiveButton("知道了", null)
            .show();
    }

    private void showConnectionError(String message) {
        new AlertDialog.Builder(this)
            .setTitle("房间连接失败")
            .setMessage(message)
            .setNegativeButton("返回", (dialog, which) -> finish())
            .setPositiveButton("重选", (dialog, which) -> showModeMenu())
            .show();
    }

    private String messageFrom(JSONObject json, String fallback) {
        if (json == null) return fallback;
        Object raw = json.opt("message");
        if (raw instanceof String && !((String) raw).isEmpty()) return (String) raw;
        return fallback;
    }

    private void dismissKeyboard() {
        View focused = getCurrentFocus();
        if (focused == null) return;
        InputMethodManager manager = (InputMethodManager) getSystemService(INPUT_METHOD_SERVICE);
        if (manager != null) manager.hideSoftInputFromWindow(focused.getWindowToken(), 0);
        focused.clearFocus();
    }

    private String initial(String name) {
        if (name == null || name.isEmpty()) return "玩";
        int end = name.offsetByCodePoints(0, 1);
        return name.substring(0, end);
    }

    private LinearLayout surface() {
        LinearLayout view = new LinearLayout(this);
        view.setOrientation(LinearLayout.VERTICAL);
        view.setBackground(JFTheme.outlined(this, JFTheme.CARD_SOLID, 0x22ffffff));
        JFTheme.pad(view, 14, 13, 14, 13);
        return view;
    }

    private TextView label(String text, float size, int color, int style) {
        TextView label = JFTheme.label(this, text, size, color, style);
        label.setMaxLines(5);
        return label;
    }

    private LinearLayout.LayoutParams spaced(int width, int height, int top, int bottom) {
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(width, height);
        params.topMargin = JFTheme.dp(this, top);
        params.bottomMargin = JFTheme.dp(this, bottom);
        return params;
    }

    static final class FingerHandView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private int activeCount = 5;
        private boolean losingFinger;

        FingerHandView(Context context) {
            super(context);
            setLayerType(View.LAYER_TYPE_SOFTWARE, null);
        }

        void setActiveCount(int count) {
            activeCount = Math.max(0, Math.min(5, count));
            invalidate();
        }

        void setLosingFinger(boolean losing) {
            losingFinger = losing;
            invalidate();
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            float width = getWidth();
            float height = getHeight();
            if (width <= 0 || height <= 0) return;
            float gap = Math.max(2f, width * 0.025f);
            float padding = width * 0.08f;
            float fingerWidth = (width - padding * 2f - gap * 4f) / 5f;
            float baseY = height * 0.72f;
            float[] factors = {0.48f, 0.67f, 0.78f, 0.68f, 0.52f};

            paint.setStyle(Paint.Style.FILL);
            paint.setColor(JFTheme.blend(JFTheme.PRIMARY, 0x00000000, activeCount > 0 ? 0.58f : 0.82f));
            RectF palm = new RectF(padding + fingerWidth * 0.34f, baseY - 2f,
                width - padding - fingerWidth * 0.34f, height * 0.95f);
            canvas.drawRoundRect(palm, Math.min(10f, palm.height() * 0.35f), Math.min(10f, palm.height() * 0.35f), paint);

            for (int index = 0; index < 5; index++) {
                boolean active = index < activeCount;
                boolean losing = losingFinger && active && index == activeCount - 1;
                float fingerHeight = height * factors[index];
                float left = padding + index * (fingerWidth + gap);
                RectF finger = new RectF(left, baseY - fingerHeight, left + fingerWidth, baseY + height * 0.07f);
                int color = losing ? JFTheme.WARNING : (active ? JFTheme.ACCENT : 0x334d586b);
                paint.setColor(color);
                paint.setShadowLayer(active ? (losing ? 7f : 5f) : 0f, 0f, 2f, color);
                canvas.drawRoundRect(finger, fingerWidth / 2f, fingerWidth / 2f, paint);
                paint.clearShadowLayer();
            }
        }
    }
}
