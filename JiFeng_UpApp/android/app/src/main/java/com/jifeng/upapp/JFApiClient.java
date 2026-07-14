package com.jifeng.upapp;

import android.content.Context;
import android.provider.Settings;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

final class JFApiClient {
    interface Callback {
        void done(JSONObject json, Exception error);
    }

    private static final ExecutorService IO = Executors.newSingleThreadExecutor();
    private static final String BASE_URL = "https://zy-fbdy.com/jifeng-api";
    private static String accessToken;

    static void ensureGuest(Context context, Callback cb) {
        if (accessToken != null) {
            cb.done(new JSONObject(), null);
            return;
        }
        try {
            JSONObject body = new JSONObject();
            String id = Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ANDROID_ID);
            body.put("deviceId", id == null ? "android-device" : id);
            body.put("deviceName", android.os.Build.MODEL);
            post("/auth/guest", body, (json, error) -> {
                if (json != null) accessToken = json.optString("accessToken", null);
                cb.done(json, error);
            });
        } catch (Exception e) {
            cb.done(null, e);
        }
    }

    static void get(String path, Callback cb) {
        request("GET", path, null, cb);
    }

    static void post(String path, JSONObject body, Callback cb) {
        request("POST", path, body, cb);
    }

    private static void request(String method, String path, JSONObject body, Callback cb) {
        IO.execute(() -> {
            HttpURLConnection conn = null;
            try {
                conn = (HttpURLConnection) new URL(BASE_URL + path).openConnection();
                conn.setRequestMethod(method);
                conn.setConnectTimeout(6000);
                conn.setReadTimeout(6000);
                conn.setRequestProperty("Accept", "application/json");
                if (accessToken != null) conn.setRequestProperty("Authorization", "Bearer " + accessToken);
                if (body != null) {
                    byte[] bytes = body.toString().getBytes(StandardCharsets.UTF_8);
                    conn.setDoOutput(true);
                    conn.setRequestProperty("Content-Type", "application/json; charset=utf-8");
                    conn.setFixedLengthStreamingMode(bytes.length);
                    try (OutputStream os = conn.getOutputStream()) {
                        os.write(bytes);
                    }
                }
                int code = conn.getResponseCode();
                InputStream stream = code >= 200 && code < 400 ? conn.getInputStream() : conn.getErrorStream();
                String text = readAll(stream).trim();
                if (text.isEmpty()) {
                    cb.done(new JSONObject(), null);
                } else if (text.startsWith("[")) {
                    cb.done(new JSONObject().put("data", new JSONArray(text)), null);
                } else {
                    cb.done(new JSONObject(text), null);
                }
            } catch (Exception e) {
                cb.done(null, e);
            } finally {
                if (conn != null) conn.disconnect();
            }
        });
    }

    private static String readAll(InputStream stream) throws Exception {
        if (stream == null) return "";
        StringBuilder out = new StringBuilder();
        try (BufferedReader br = new BufferedReader(new InputStreamReader(stream, StandardCharsets.UTF_8))) {
            String line;
            while ((line = br.readLine()) != null) out.append(line);
        }
        return out.toString();
    }
}
