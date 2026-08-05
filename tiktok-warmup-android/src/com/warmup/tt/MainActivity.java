package com.warmup.tt;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.text.InputType;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import java.util.LinkedHashMap;
import java.util.Map;

public class MainActivity extends Activity {

    private static final int START_DELAY_SECONDS = 5;

    private TextView status;
    private EditText durationInput;
    private CheckBox faithfulBox;
    private final Map<String, EditText> fractionInputs = new LinkedHashMap<String, EditText>();
    private final Handler ui = new Handler(Looper.getMainLooper());
    private SharedPreferences sp;

    private final Runnable poll = new Runnable() {
        @Override public void run() {
            refreshStatus();
            ui.postDelayed(this, 1000L);
        }
    };

    @Override
    protected void onCreate(Bundle saved) {
        super.onCreate(saved);
        sp = getSharedPreferences(Prefs.NAME, Context.MODE_PRIVATE);

        ScrollView scroll = new ScrollView(this);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        int pad = dp(20);
        root.setPadding(pad, pad, pad, pad);
        scroll.addView(root, new ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        root.addView(heading("Warmup"));
        root.addView(body("Port of l-portet/tiktok-warmup-bot. Same action table and "
                + "intervals, driven by Android's accessibility gestures instead of iOS "
                + "Voice Control."));

        // -- step 1 -------------------------------------------------------
        root.addView(heading("1. Accessibility service"));
        root.addView(body("The service must be enabled before anything can run. "
                + "Find \"Warmup\" under Installed apps / Downloaded services."));
        Button openSettings = new Button(this);
        openSettings.setText("Open accessibility settings");
        openSettings.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                startActivity(new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS));
            }
        });
        root.addView(openSettings);

        // -- step 2 -------------------------------------------------------
        root.addView(heading("2. Session"));
        durationInput = new EditText(this);
        durationInput.setInputType(InputType.TYPE_CLASS_NUMBER);
        durationInput.setText(String.valueOf(sp.getInt(Prefs.DURATION, 30)));
        root.addView(label("Duration (minutes)"));
        root.addView(durationInput);

        faithfulBox = new CheckBox(this);
        faithfulBox.setText("Faithful mode (upstream bug included)");
        faithfulBox.setChecked(sp.getBoolean(Prefs.FAITHFUL, Prefs.D_FAITHFUL));
        root.addView(faithfulBox);
        root.addView(body("Upstream re-rolls every interval when any action fires, so "
                + "openProfile, openShop and openInbox never actually run. Leave this off "
                + "unless you want that behaviour reproduced exactly."));

        Button start = new Button(this);
        start.setText("Start");
        start.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { startWarmup(); }
        });
        root.addView(start);

        Button stop = new Button(this);
        stop.setText("Stop");
        stop.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { stopWarmup(); }
        });
        root.addView(stop);

        status = new TextView(this);
        status.setPadding(0, dp(12), 0, dp(12));
        status.setTextColor(Color.DKGRAY);
        root.addView(status);

        // -- step 3 -------------------------------------------------------
        root.addView(heading("3. Calibration"));
        root.addView(body("Tap targets as a fraction of screen size (0-1). The defaults "
                + "are estimates of TikTok's layout. If likes or saves miss, adjust these "
                + "and restart the session. likePost uses a double-tap in the centre, so "
                + "it needs no calibration."));

        addFraction(root, "Action rail X",  Prefs.RAIL_X,    Prefs.D_RAIL_X);
        addFraction(root, "Avatar Y",       Prefs.PROFILE_Y, Prefs.D_PROFILE_Y);
        addFraction(root, "Comments Y",     Prefs.COMMENT_Y, Prefs.D_COMMENT_Y);
        addFraction(root, "Bookmark Y",     Prefs.SAVE_Y,    Prefs.D_SAVE_Y);
        addFraction(root, "Bottom nav Y",   Prefs.NAV_Y,     Prefs.D_NAV_Y);
        addFraction(root, "Shop X",         Prefs.SHOP_X,    Prefs.D_SHOP_X);
        addFraction(root, "Inbox X",        Prefs.INBOX_X,   Prefs.D_INBOX_X);

        setContentView(scroll);
    }

    @Override protected void onResume() { super.onResume(); ui.post(poll); }
    @Override protected void onPause()  { super.onPause();  ui.removeCallbacks(poll); }

    // ------------------------------------------------------------- actions

    private void startWarmup() {
        WarmupService svc = WarmupService.instance;
        if (svc == null) {
            toast("Enable the accessibility service first (step 1).");
            return;
        }
        if (svc.isRunning()) {
            toast("Already running.");
            return;
        }

        saveSettings();
        int minutes = parseInt(durationInput.getText().toString(), 30);
        svc.startSession(minutes, START_DELAY_SECONDS);

        toast("Starting in " + START_DELAY_SECONDS + "s - open TikTok now");
        moveTaskToBack(true);
    }

    private void stopWarmup() {
        WarmupService svc = WarmupService.instance;
        if (svc == null) {
            toast("Service is not connected.");
            return;
        }
        svc.stopSession();
        toast("Stopped.");
        refreshStatus();
    }

    private void refreshStatus() {
        WarmupService svc = WarmupService.instance;
        if (svc == null) {
            status.setText("Service: not enabled");
            return;
        }
        if (!svc.isRunning()) {
            status.setText("Service: ready\nLast session: " + svc.getStatsLine());
            return;
        }
        long remaining = svc.getRemainingMs() / 1000L;
        status.setText("Running - " + (remaining / 60) + "m " + (remaining % 60) + "s left"
                + "\nSwipes: " + svc.getSwipeCount()
                + "\nLast: " + svc.getLastAction()
                + "\n" + svc.getStatsLine());
    }

    private void saveSettings() {
        SharedPreferences.Editor ed = sp.edit();
        ed.putInt(Prefs.DURATION, parseInt(durationInput.getText().toString(), 30));
        ed.putBoolean(Prefs.FAITHFUL, faithfulBox.isChecked());
        for (Map.Entry<String, EditText> e : fractionInputs.entrySet()) {
            float v = parseFloat(e.getValue().getText().toString(), Float.NaN);
            if (!Float.isNaN(v) && v >= 0f && v <= 1f) {
                ed.putFloat(e.getKey(), v);
            }
        }
        ed.apply();
    }

    // --------------------------------------------------------------- views

    private void addFraction(LinearLayout parent, String labelText, String key, float def) {
        EditText input = new EditText(this);
        input.setInputType(InputType.TYPE_CLASS_NUMBER | InputType.TYPE_NUMBER_FLAG_DECIMAL);
        input.setText(String.valueOf(sp.getFloat(key, def)));
        parent.addView(label(labelText));
        parent.addView(input);
        fractionInputs.put(key, input);
    }

    private TextView heading(String text) {
        TextView tv = new TextView(this);
        tv.setText(text);
        tv.setTextSize(20f);
        tv.setTextColor(Color.BLACK);
        tv.setPadding(0, dp(20), 0, dp(6));
        return tv;
    }

    private TextView body(String text) {
        TextView tv = new TextView(this);
        tv.setText(text);
        tv.setTextSize(14f);
        tv.setTextColor(Color.DKGRAY);
        tv.setPadding(0, 0, 0, dp(8));
        return tv;
    }

    private TextView label(String text) {
        TextView tv = new TextView(this);
        tv.setText(text);
        tv.setTextSize(13f);
        tv.setTextColor(Color.GRAY);
        tv.setPadding(0, dp(8), 0, 0);
        return tv;
    }

    private int dp(int v) {
        return (int) (v * getResources().getDisplayMetrics().density);
    }

    private void toast(String msg) {
        Toast.makeText(this, msg, Toast.LENGTH_LONG).show();
    }

    private static int parseInt(String s, int def) {
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return def; }
    }

    private static float parseFloat(String s, float def) {
        try { return Float.parseFloat(s.trim()); } catch (Exception e) { return def; }
    }
}
