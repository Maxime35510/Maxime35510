package com.warmup.tt;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.Typeface;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.text.InputType;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.List;

public class MainActivity extends Activity {

    private static final int START_DELAY_SECONDS = 6;

    private Prefs prefs;
    private final Handler ui = new Handler(Looper.getMainLooper());

    private TextView bigButton, statusLine, subStatus, feedView, researchView, serviceWarn;
    private TextView durationNote, presetDesc;
    private EditText durationInput, nicheInput;
    private final List<TextView> presetChips = new ArrayList<TextView>();
    private int preset;

    private final Runnable poll = new Runnable() {
        @Override public void run() {
            refresh();
            ui.postDelayed(this, 1000L);
        }
    };

    @Override
    protected void onCreate(Bundle saved) {
        super.onCreate(saved);
        prefs = new Prefs(this);
        preset = prefs.preset();

        ScrollView scroll = new ScrollView(this);
        scroll.setBackgroundColor(Theme.BG);
        scroll.setFillViewport(true);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        int p = Theme.dp(this, 18);
        root.setPadding(p, Theme.dp(this, 28), p, Theme.dp(this, 40));
        scroll.addView(root, new ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        buildHeader(root);
        buildServiceWarning(root);
        buildControl(root);
        buildSession(root);
        buildNiche(root);
        buildOptions(root);
        buildLiveFeed(root);
        buildResearch(root);
        buildCredits(root);

        setContentView(scroll);
        Notifications.ensureChannel(this);
    }

    @Override protected void onResume() { super.onResume(); ui.post(poll); }
    @Override protected void onPause()  { super.onPause(); ui.removeCallbacks(poll); persist(); }

    // ---------------------------------------------------------------- header

    private void buildHeader(LinearLayout root) {
        TextView t = new TextView(this);
        t.setText("Warmup");
        t.setTextSize(34f);
        t.setTextColor(Theme.TEXT);
        t.setTypeface(t.getTypeface(), Typeface.BOLD);
        root.addView(t);

        TextView s = new TextView(this);
        s.setText("Human-modelled TikTok warmup");
        Theme.style(s, 13f, Theme.MUTED, false);
        s.setPadding(0, Theme.dp(this, 2), 0, Theme.dp(this, 18));
        root.addView(s);
    }

    private void buildServiceWarning(LinearLayout root) {
        serviceWarn = new TextView(this);
        serviceWarn.setText("Accessibility service is off  -  tap to enable");
        Theme.style(serviceWarn, 13f, 0xFF1A1200, true);
        serviceWarn.setBackground(Theme.solid(this, Theme.WARN, 12));
        int q = Theme.dp(this, 14);
        serviceWarn.setPadding(q, q, q, q);
        serviceWarn.setGravity(Gravity.CENTER);
        serviceWarn.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                startActivity(new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS));
            }
        });
        LinearLayout.LayoutParams lp = fill();
        lp.bottomMargin = Theme.dp(this, 14);
        root.addView(serviceWarn, lp);
    }

    // --------------------------------------------------------------- control

    private void buildControl(LinearLayout root) {
        LinearLayout card = card(root, null);
        card.setGravity(Gravity.CENTER_HORIZONTAL);

        bigButton = new TextView(this);
        bigButton.setText("START");
        bigButton.setGravity(Gravity.CENTER);
        Theme.style(bigButton, 20f, 0xFF07131A, true);
        bigButton.setBackground(Theme.pressable(Theme.accentCircle(this)));
        int d = Theme.dp(this, 148);
        LinearLayout.LayoutParams blp = new LinearLayout.LayoutParams(d, d);
        blp.topMargin = Theme.dp(this, 6);
        blp.bottomMargin = Theme.dp(this, 16);
        bigButton.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { toggleSession(); }
        });
        card.addView(bigButton, blp);

        statusLine = new TextView(this);
        statusLine.setGravity(Gravity.CENTER);
        Theme.style(statusLine, 15f, Theme.TEXT, true);
        card.addView(statusLine, fill());

        subStatus = new TextView(this);
        subStatus.setGravity(Gravity.CENTER);
        Theme.style(subStatus, 12f, Theme.MUTED, false);
        subStatus.setPadding(0, Theme.dp(this, 4), 0, 0);
        card.addView(subStatus, fill());
    }

    private void toggleSession() {
        WarmupService svc = WarmupService.instance;
        if (svc == null) {
            toast("Enable the accessibility service first");
            startActivity(new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS));
            return;
        }
        if (svc.isRunning()) {
            svc.stopSession("user");
            refresh();
            return;
        }
        persist();
        svc.startSession(parseInt(durationInput.getText().toString(), 30),
                START_DELAY_SECONDS);
        toast(prefs.dryRun()
                ? "Dry run - watching only, nothing will be tapped"
                : "Opening TikTok...");
        refresh();
    }

    // --------------------------------------------------------------- session

    private void buildSession(LinearLayout root) {
        LinearLayout card = card(root, "Session");

        card.addView(label("Duration (minutes)"));
        durationInput = input(String.valueOf(prefs.duration()),
                InputType.TYPE_CLASS_NUMBER);
        card.addView(durationInput, fill());

        durationNote = new TextView(this);
        Theme.style(durationNote, 11f, Theme.FAINT, false);
        durationNote.setPadding(0, Theme.dp(this, 6), 0, Theme.dp(this, 14));
        card.addView(durationNote, fill());
        updateDurationNote();
        durationInput.addTextChangedListener(new android.text.TextWatcher() {
            @Override public void beforeTextChanged(CharSequence c,int a,int b,int d) { }
            @Override public void onTextChanged(CharSequence c,int a,int b,int d) { }
            @Override public void afterTextChanged(android.text.Editable e) {
                updateDurationNote();
            }
        });

        card.addView(label("Activity level"));
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        String[] names = { "Light", "Normal", "Heavy" };
        for (int i = 0; i < 3; i++) {
            final int idx = i;
            TextView chip = new TextView(this);
            chip.setText(names[i]);
            chip.setGravity(Gravity.CENTER);
            chip.setPadding(0, Theme.dp(this, 11), 0, Theme.dp(this, 11));
            chip.setOnClickListener(new View.OnClickListener() {
                @Override public void onClick(View v) {
                    preset = idx;
                    paintChips();
                    prefs.edit().putInt(Prefs.PRESET, preset).apply();
                }
            });
            LinearLayout.LayoutParams clp =
                    new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
            clp.leftMargin = i == 0 ? 0 : Theme.dp(this, 8);
            row.addView(chip, clp);
            presetChips.add(chip);
        }
        LinearLayout.LayoutParams rlp = fill();
        rlp.topMargin = Theme.dp(this, 6);
        card.addView(row, rlp);
        paintChips();

        presetDesc = new TextView(this);
        Theme.style(presetDesc, 11f, Theme.FAINT, false);
        presetDesc.setPadding(0, Theme.dp(this, 10), 0, 0);
        card.addView(presetDesc, fill());
        paintChips();

        card.addView(toggle("Dry run", "Decide and log everything, tap nothing. "
                + "Watch one session before trusting it.", Prefs.DRY_RUN, false));
    }

    private void updateDurationNote() {
        if (durationNote == null) return;
        int d = parseInt(durationInput.getText().toString(), 30);
        int lo = (int) Math.round(d * 0.75), hi = (int) Math.round(d * 1.25);
        durationNote.setText("Example: set " + d + " and the session actually runs "
                + lo + "-" + hi + " min. The exact length is picked when you press "
                + "START. People don't stop watching on a round number, so neither "
                + "does this.");
    }

    private String presetText(int p) {
        if (p == Prefs.PRESET_LIGHT) {
            return "LIGHT - per 100 videos: ~2 likes, ~3 comment opens, almost no saves.\n"
                 + "Quieter than a real person. Use it if you want minimal footprint.";
        }
        if (p == Prefs.PRESET_HEAVY) {
            return "HEAVY - per 100 videos: ~7 likes, ~11 comment opens, ~1 save.\n"
                 + "Roughly twice as active as a real person. Trains the feed faster, "
                 + "but the engagement rate stops looking typical.";
        }
        return "NORMAL - per 100 videos: ~4 likes, ~6 comment opens, ~1 save.\n"
             + "This is the measured human average (3.4-4% of views get a like). "
             + "Recommended.";
    }

    private void paintChips() {
        if (presetDesc != null) presetDesc.setText(presetText(preset));
        for (int i = 0; i < presetChips.size(); i++) {
            TextView c = presetChips.get(i);
            boolean on = i == preset;
            c.setBackground(on ? Theme.accent(this, 10) : Theme.card(this, Theme.CARD_HI, 10));
            c.setTextColor(on ? 0xFF07131A : Theme.MUTED);
            c.setTypeface(c.getTypeface(), on ? Typeface.BOLD : Typeface.NORMAL);
        }
    }

    // ----------------------------------------------------------------- niche

    private void buildNiche(LinearLayout root) {
        LinearLayout card = card(root, "Niche");

        card.addView(toggle("Search my niche", "Periodically searches a term and browses "
                + "the results, which pulls your For You page toward the niche.",
                Prefs.NICHE_ENABLED, true));

        card.addView(label("Search terms, one per line"));
        nicheInput = input(prefs.nicheRaw(),
                InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE);
        nicheInput.setMinLines(4);
        nicheInput.setGravity(Gravity.TOP);
        card.addView(nicheInput, fill());
    }

    // --------------------------------------------------------------- options

    private void buildOptions(LinearLayout root) {
        LinearLayout card = card(root, "Behaviour");
        card.addView(toggle("Floating stop button",
                "Draggable overlay, parked left where the bot never taps.",
                Prefs.OVERLAY, true));
        card.addView(toggle("Research log",
                "Records authors, hashtags and sounds it scrolls past.",
                Prefs.RESEARCH, true));
        card.addView(toggle("Like comments",
                "Occasionally likes a comment while the sheet is open.",
                Prefs.LIKE_COMMENTS, true));
        card.addView(toggle("Repost",
                "Off by default. Reposts push a video to your followers under your "
                + "name, chosen by something that cannot see the video.",
                Prefs.REPOST, false));
    }

    // ------------------------------------------------------------- live feed

    private void buildLiveFeed(LinearLayout root) {
        LinearLayout card = card(root, "Live");
        feedView = new TextView(this);
        Theme.style(feedView, 12f, Theme.MUTED, false);
        feedView.setTypeface(Typeface.MONOSPACE);
        feedView.setLineSpacing(0f, 1.25f);
        card.addView(feedView, fill());
    }

    // -------------------------------------------------------------- research

    private void buildResearch(LinearLayout root) {
        LinearLayout card = card(root, "Niche research");
        researchView = new TextView(this);
        Theme.style(researchView, 12f, Theme.MUTED, false);
        researchView.setLineSpacing(0f, 1.3f);
        card.addView(researchView, fill());

        TextView export = new TextView(this);
        export.setText("Share research summary");
        export.setGravity(Gravity.CENTER);
        Theme.style(export, 13f, Theme.ACCENT_A, true);
        export.setPadding(0, Theme.dp(this, 12), 0, Theme.dp(this, 12));
        export.setBackground(Theme.pressable(Theme.card(this, Theme.CARD_HI, 10)));
        export.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                Intent i = new Intent(Intent.ACTION_SEND);
                i.setType("text/plain");
                i.putExtra(Intent.EXTRA_SUBJECT, "Niche research");
                i.putExtra(Intent.EXTRA_TEXT, researchView.getText().toString());
                try {
                    startActivity(Intent.createChooser(i, "Share research"));
                } catch (Throwable t) { toast("Nothing to share with"); }
            }
        });
        LinearLayout.LayoutParams elp = fill();
        elp.topMargin = Theme.dp(this, 12);
        card.addView(export, elp);

        TextView clear = new TextView(this);
        clear.setText("Clear log");
        clear.setGravity(Gravity.CENTER);
        Theme.style(clear, 13f, Theme.DANGER, true);
        clear.setPadding(0, Theme.dp(this, 12), 0, Theme.dp(this, 12));
        clear.setBackground(Theme.card(this, Theme.CARD_HI, 10));
        clear.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                new ResearchLog(MainActivity.this).clear();
                refresh();
                toast("Research log cleared");
            }
        });
        LinearLayout.LayoutParams lp = fill();
        lp.topMargin = Theme.dp(this, 12);
        card.addView(clear, lp);
    }

    // --------------------------------------------------------------- credits

    private void buildCredits(LinearLayout root) {
        LinearLayout card = card(root, "Credits");

        TextView who = new TextView(this);
        who.setText("Maxime35");
        Theme.style(who, 17f, Theme.TEXT, true);
        card.addView(who, fill());

        TextView role = new TextView(this);
        role.setText("Cybersecurity graduate, software & bot developer");
        Theme.style(role, 12f, Theme.MUTED, false);
        role.setPadding(0, Theme.dp(this, 2), 0, Theme.dp(this, 12));
        card.addView(role, fill());

        card.addView(link("Website", "https://louming.dastot.net"));
        card.addView(link("LinkedIn", "https://www.linkedin.com/in/lou-ming-dastot/"));
        card.addView(link("GitHub", "https://github.com/Maxime35510"));
    }

    private TextView link(String text, final String url) {
        TextView t = new TextView(this);
        t.setText(text);
        Theme.style(t, 14f, Theme.ACCENT_A, true);
        t.setPadding(Theme.dp(this, 14), Theme.dp(this, 12),
                     Theme.dp(this, 14), Theme.dp(this, 12));
        t.setBackground(Theme.pressable(Theme.card(this, Theme.CARD_HI, 10)));
        t.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                try {
                    startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url)));
                } catch (Throwable t2) { toast("No browser found"); }
            }
        });
        LinearLayout.LayoutParams lp = fill();
        lp.topMargin = Theme.dp(this, 8);
        t.setLayoutParams(lp);
        return t;
    }

    // ----------------------------------------------------------------- state

    private void refresh() {
        WarmupService svc = WarmupService.instance;
        boolean connected = svc != null;
        serviceWarn.setVisibility(connected ? View.GONE : View.VISIBLE);

        boolean running = connected && svc.isRunning();
        bigButton.setText(running ? "STOP" : "START");
        bigButton.setBackground(Theme.pressable(
                running ? Theme.dangerCircle(this) : Theme.accentCircle(this)));

        if (!connected) {
            statusLine.setText("Service not enabled");
            subStatus.setText("Warmup needs the accessibility service to read the screen");
        } else if (!running) {
            statusLine.setText("Ready");
            subStatus.setText(ActionLog.summary());
        } else {
            long s = svc.remainingMs() / 1000;
            statusLine.setText((svc.isPaused() ? "Paused  -  " : "")
                    + String.format("%d:%02d", s / 60, s % 60) + " left");
            subStatus.setText("video " + svc.videoCount() + "   ·   " + svc.lastAction()
                    + (svc.dryRun() ? "   ·   DRY RUN" : ""));
        }

        StringBuilder sb = new StringBuilder();
        List<ActionLog.Entry> es = ActionLog.recent(14);
        for (int i = es.size() - 1; i >= 0; i--) {
            ActionLog.Entry e = es.get(i);
            sb.append(ActionLog.clock(e.time)).append("  ").append(e.action);
            if (e.detail.length() > 0) sb.append("  ").append(e.detail);
            if (e.skipped) sb.append("  (skipped)");
            sb.append('\n');
        }
        feedView.setText(sb.length() == 0 ? "nothing yet" : sb.toString().trim());

        ResearchLog r = new ResearchLog(this);
        StringBuilder rb = new StringBuilder();
        rb.append(r.size()).append(" videos logged\n");
        appendList(rb, "Top hashtags", r.topHashtags(6));
        appendList(rb, "Top sounds", r.topSounds(4));
        appendList(rb, "Recurring creators", r.topAuthors(4));
        researchView.setText(rb.toString().trim());
    }

    private static void appendList(StringBuilder sb, String title, List<String> items) {
        sb.append('\n').append(title).append('\n');
        if (items.isEmpty()) { sb.append("  -\n"); return; }
        for (String s : items) sb.append("  ").append(s).append('\n');
    }

    private void persist() {
        if (durationInput == null) return;
        SharedPreferences.Editor ed = prefs.edit();
        ed.putInt(Prefs.DURATION, parseInt(durationInput.getText().toString(), 30));
        ed.putInt(Prefs.PRESET, preset);
        ed.putString(Prefs.NICHE_TERMS, nicheInput.getText().toString());
        ed.apply();
    }

    // ----------------------------------------------------------------- views

    private LinearLayout card(LinearLayout parent, String title) {
        LinearLayout c = new LinearLayout(this);
        c.setOrientation(LinearLayout.VERTICAL);
        c.setBackground(Theme.card(this, Theme.CARD, 18));
        int q = Theme.dp(this, 18);
        c.setPadding(q, q, q, q);

        if (title != null) {
            TextView t = new TextView(this);
            t.setText(title.toUpperCase());
            Theme.style(t, 11f, Theme.FAINT, true);
            t.setLetterSpacing(0.14f);
            t.setPadding(0, 0, 0, Theme.dp(this, 12));
            c.addView(t);
        }
        LinearLayout.LayoutParams lp = fill();
        lp.bottomMargin = Theme.dp(this, 14);
        parent.addView(c, lp);
        return c;
    }

    private View toggle(String title, String desc, final String key, boolean def) {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.VERTICAL);
        row.setPadding(0, Theme.dp(this, 12), 0, 0);

        LinearLayout top = new LinearLayout(this);
        top.setOrientation(LinearLayout.HORIZONTAL);
        top.setGravity(Gravity.CENTER_VERTICAL);

        TextView t = new TextView(this);
        t.setText(title);
        Theme.style(t, 14f, Theme.TEXT, false);
        top.addView(t, new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));

        Switch sw = new Switch(this);
        sw.setChecked(prefs.raw().getBoolean(key, def));
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            sw.setThumbTintList(android.content.res.ColorStateList.valueOf(Theme.ACCENT_A));
        }
        sw.setOnCheckedChangeListener(new android.widget.CompoundButton.OnCheckedChangeListener() {
            @Override public void onCheckedChanged(
                    android.widget.CompoundButton b, boolean on) {
                prefs.edit().putBoolean(key, on).apply();
            }
        });
        top.addView(sw);
        row.addView(top, fill());

        if (desc != null) {
            TextView d = new TextView(this);
            d.setText(desc);
            Theme.style(d, 11f, Theme.FAINT, false);
            d.setPadding(0, Theme.dp(this, 2), Theme.dp(this, 48), 0);
            row.addView(d, fill());
        }
        return row;
    }

    private TextView label(String text) {
        TextView t = new TextView(this);
        t.setText(text);
        Theme.style(t, 12f, Theme.MUTED, false);
        t.setPadding(0, Theme.dp(this, 10), 0, Theme.dp(this, 6));
        return t;
    }

    private EditText input(String value, int type) {
        EditText e = new EditText(this);
        e.setText(value);
        e.setInputType(type);
        e.setTextColor(Theme.TEXT);
        e.setTextSize(15f);
        e.setBackground(Theme.card(this, Theme.CARD_HI, 10));
        int q = Theme.dp(this, 12);
        e.setPadding(q, q, q, q);
        return e;
    }

    private LinearLayout.LayoutParams fill() {
        return new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
    }

    private void toast(String m) { Toast.makeText(this, m, Toast.LENGTH_LONG).show(); }

    private static int parseInt(String s, int def) {
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return def; }
    }
}
