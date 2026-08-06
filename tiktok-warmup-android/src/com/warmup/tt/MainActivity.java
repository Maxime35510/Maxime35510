package com.warmup.tt;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Typeface;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.text.Editable;
import android.text.InputType;
import android.text.TextWatcher;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.SeekBar;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.Toast;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class MainActivity extends Activity {

    private Prefs prefs;
    private final Handler ui = new Handler(Looper.getMainLooper());

    private TextView bigButton, statusLine, subStatus, serviceWarn;
    private TextView nicheNow, nicheCaption, targetLabel;
    private View barFill, barRest;
    private SeekBar targetBar, levelBar;
    private TextView levelLabel, levelDesc, rateSummary, nicheStatus, durationNote;
    private TextView feedView, diagView, statsView, researchView;
    private EditText durationInput, nicheInput;
    private LinearLayout advancedBody;
    private TextView advancedToggle;
    private final Map<String, EditText> rateInputs = new LinkedHashMap<String, EditText>();
    private boolean suppressRateWatch = false, advancedOpen = false;

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

        ScrollView scroll = new ScrollView(this);
        scroll.setBackgroundColor(Theme.BG);
        scroll.setFillViewport(true);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        int p = Theme.dp(this, 16);
        root.setPadding(p, Theme.dp(this, 24), p, Theme.dp(this, 44));
        scroll.addView(root, new ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        buildHeader(root);
        buildServiceWarning(root);
        buildProgress(root);
        buildControl(root);
        buildNiche(root);
        buildLevel(root);
        buildSession(root);
        buildAdvanced(root);
        buildLiveFeed(root);
        buildStats(root);
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
        t.setText("TikTok Boost");
        t.setTextSize(30f);
        t.setTextColor(Theme.TEXT);
        t.setTypeface(t.getTypeface(), Typeface.BOLD);
        t.setPadding(0, 0, 0, Theme.dp(this, 14));
        root.addView(t);
    }

    private void buildServiceWarning(LinearLayout root) {
        serviceWarn = new TextView(this);
        serviceWarn.setText("Accessibility service off — tap to enable");
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
        lp.bottomMargin = Theme.dp(this, 12);
        root.addView(serviceWarn, lp);
    }

    // -------------------------------------------------------- niche progress

    /** The number that matters: how much of the feed is now your niche. */
    private void buildProgress(LinearLayout root) {
        LinearLayout card = card(root, null);

        nicheNow = new TextView(this);
        nicheNow.setText("—");
        nicheNow.setTextSize(52f);
        nicheNow.setTextColor(Theme.TEXT);
        nicheNow.setTypeface(nicheNow.getTypeface(), Typeface.BOLD);
        card.addView(nicheNow, fill());

        nicheCaption = new TextView(this);
        Theme.style(nicheCaption, 12f, Theme.MUTED, false);
        nicheCaption.setPadding(0, 0, 0, Theme.dp(this, 14));
        card.addView(nicheCaption, fill());

        // Progress track: two weighted views, filled + remainder.
        LinearLayout track = new LinearLayout(this);
        track.setOrientation(LinearLayout.HORIZONTAL);
        track.setBackground(Theme.solid(this, Theme.CARD_HI, 6));
        barFill = new View(this);
        barFill.setBackground(Theme.accent(this, 6));
        barRest = new View(this);
        track.addView(barFill, new LinearLayout.LayoutParams(0,
                Theme.dp(this, 10), 0f));
        track.addView(barRest, new LinearLayout.LayoutParams(0,
                Theme.dp(this, 10), 100f));
        card.addView(track, fill());

        targetLabel = new TextView(this);
        Theme.style(targetLabel, 12f, Theme.MUTED, false);
        targetLabel.setPadding(0, Theme.dp(this, 14), 0, Theme.dp(this, 2));
        card.addView(targetLabel, fill());

        targetBar = new SeekBar(this);
        targetBar.setMax(90);
        targetBar.setProgress(Math.max(0, prefs.nicheTarget() - 10));
        tint(targetBar);
        targetBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override public void onProgressChanged(SeekBar s, int v, boolean fromUser) {
                if (!fromUser) return;
                prefs.edit().putInt(Prefs.TARGET, v + 10).apply();
                WarmupService svc = WarmupService.instance;
                if (svc != null) svc.reload();
                updateTargetLabel();
            }
            @Override public void onStartTrackingTouch(SeekBar s) { }
            @Override public void onStopTrackingTouch(SeekBar s) { }
        });
        card.addView(targetBar, fill());
        updateTargetLabel();
    }

    private void updateTargetLabel() {
        targetLabel.setText("Target  " + prefs.nicheTarget() + "%   —  below this it "
                + "searches more, skips faster and stays in results longer");
    }

    private void setBar(int pct, int target) {
        int p = pct < 0 ? 0 : (pct > 100 ? 100 : pct);
        ((LinearLayout.LayoutParams) barFill.getLayoutParams()).weight = p;
        ((LinearLayout.LayoutParams) barRest.getLayoutParams()).weight = 100 - p;
        barFill.setBackground(p >= target
                ? Theme.solid(this, Theme.OK, 6) : Theme.accent(this, 6));
        barFill.requestLayout();
        barRest.requestLayout();
    }

    // --------------------------------------------------------------- control

    private void buildControl(LinearLayout root) {
        LinearLayout card = card(root, null);
        card.setGravity(Gravity.CENTER_HORIZONTAL);

        bigButton = new TextView(this);
        bigButton.setText("START");
        bigButton.setGravity(Gravity.CENTER);
        Theme.style(bigButton, 22f, 0xFF07131A, true);
        bigButton.setBackground(Theme.pressable(Theme.accentCircle(this)));
        int d = Theme.dp(this, 146);
        LinearLayout.LayoutParams blp = new LinearLayout.LayoutParams(d, d);
        blp.bottomMargin = Theme.dp(this, 14);
        bigButton.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { onBigButton(); }
        });
        card.addView(bigButton, blp);

        statusLine = new TextView(this);
        statusLine.setGravity(Gravity.CENTER);
        Theme.style(statusLine, 15f, Theme.TEXT, true);
        card.addView(statusLine, fill());

        subStatus = new TextView(this);
        subStatus.setGravity(Gravity.CENTER);
        Theme.style(subStatus, 12f, Theme.MUTED, false);
        subStatus.setPadding(0, Theme.dp(this, 6), 0, 0);
        card.addView(subStatus, fill());
    }

    /** Start arms the bubble; while armed or running, this stops everything. */
    private void onBigButton() {
        WarmupService svc = WarmupService.instance;
        if (svc == null) {
            toast("Enable the accessibility service first");
            startActivity(new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS));
            return;
        }
        if (svc.isRunning() || svc.isArmed()) {
            svc.stopAll("stopped from the app");
            toast("Stopped — bubble removed");
            refresh();
            return;
        }
        persist();
        svc.arm();
        toast("Open TikTok, then tap the bubble");
        moveTaskToBack(true);
        refresh();
    }

    // ----------------------------------------------------------------- niche

    private void buildNiche(LinearLayout root) {
        LinearLayout card = card(root, "Your niche");
        card.addView(hint("Videos matching these get watched fully and engaged with. "
                + "Everything else is skipped. Edits apply immediately."));

        nicheInput = input(prefs.nicheRaw(),
                InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE);
        nicheInput.setMinLines(4);
        nicheInput.setGravity(Gravity.TOP);
        card.addView(nicheInput, fill());

        nicheStatus = new TextView(this);
        Theme.style(nicheStatus, 11f, Theme.ACCENT_A, false);
        nicheStatus.setPadding(0, Theme.dp(this, 8), 0, 0);
        card.addView(nicheStatus, fill());

        nicheInput.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence c,int a,int b,int d) { }
            @Override public void onTextChanged(CharSequence c,int a,int b,int d) { }
            @Override public void afterTextChanged(Editable e) {
                prefs.edit().putString(Prefs.NICHE_TERMS, e.toString()).apply();
                WarmupService svc = WarmupService.instance;
                if (svc != null) svc.reload();
                updateNicheStatus();
            }
        });
        updateNicheStatus();
    }

    private void updateNicheStatus() {
        Niche n = new Niche(nicheInput.getText().toString());
        if (n.isEmpty()) {
            nicheStatus.setTextColor(Theme.WARN);
            nicheStatus.setText("No keywords — everything counts as a match. Add terms.");
            return;
        }
        StringBuilder sb = new StringBuilder(n.size() + " keywords: ");
        List<String> k = n.keywords();
        for (int i = 0; i < k.size() && i < 8; i++) {
            if (i > 0) sb.append(", ");
            sb.append(k.get(i));
        }
        if (k.size() > 8) sb.append(" +").append(k.size() - 8);
        nicheStatus.setTextColor(Theme.ACCENT_A);
        nicheStatus.setText(sb.toString());
    }

    // ----------------------------------------------------------------- level

    private void buildLevel(LinearLayout root) {
        LinearLayout card = card(root, "Boost level");

        levelLabel = new TextView(this);
        Theme.style(levelLabel, 28f, Theme.TEXT, true);
        card.addView(levelLabel, fill());

        levelBar = new SeekBar(this);
        levelBar.setMax(99);
        levelBar.setProgress(Math.max(0, prefs.level() - 1));
        tint(levelBar);
        LinearLayout.LayoutParams slp = fill();
        slp.topMargin = Theme.dp(this, 4);
        card.addView(levelBar, slp);

        levelDesc = new TextView(this);
        Theme.style(levelDesc, 11f, Theme.FAINT, false);
        levelDesc.setPadding(0, Theme.dp(this, 8), 0, 0);
        card.addView(levelDesc, fill());

        levelBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override public void onProgressChanged(SeekBar s, int v, boolean fromUser) {
                if (!fromUser) return;
                prefs.applyLevel(v + 1);
                loadRateInputs();
                updateLevelText();
            }
            @Override public void onStartTrackingTouch(SeekBar s) { }
            @Override public void onStopTrackingTouch(SeekBar s) { }
        });
        updateLevelText();
    }

    private void updateLevelText() {
        int lvl = prefs.level();
        Behavior.Rates r = prefs.rates();
        levelLabel.setText(prefs.custom() ? "Custom" : String.valueOf(lvl));
        String band;
        if (lvl <= 10)      band = "lurker";
        else if (lvl <= 25) band = "around the human average";
        else if (lvl <= 50) band = "engaged regular";
        else if (lvl <= 75) band = "fan account";
        else                band = "superfan";
        levelDesc.setText(band + " · per 100 niche videos: " + r.like + " likes, "
                + r.save + " saves, " + r.commentOpen + " comments, "
                + r.follow + " follows, " + r.repost + " reposts");
    }

    // --------------------------------------------------------------- session

    private void buildSession(LinearLayout root) {
        LinearLayout card = card(root, "Session");
        card.addView(label("Minutes"));
        durationInput = input(String.valueOf(prefs.duration()), InputType.TYPE_CLASS_NUMBER);
        card.addView(durationInput, fill());

        durationNote = new TextView(this);
        Theme.style(durationNote, 11f, Theme.FAINT, false);
        durationNote.setPadding(0, Theme.dp(this, 6), 0, 0);
        card.addView(durationNote, fill());
        durationInput.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence c,int a,int b,int d) { }
            @Override public void onTextChanged(CharSequence c,int a,int b,int d) { }
            @Override public void afterTextChanged(Editable e) {
                updateDurationNote(); updateRateSummary();
            }
        });
        updateDurationNote();

        card.addView(toggle("Auto sessions",
                "Runs again by itself after 8–42 minutes.", Prefs.AUTO, true));
    }

    private void updateDurationNote() {
        int d = parseInt(durationInput.getText().toString(), 25);
        durationNote.setText("Runs " + Math.round(d * 0.75) + "–" + Math.round(d * 1.25)
                + " min — never a round number.");
    }

    // -------------------------------------------------------------- advanced

    private void buildAdvanced(LinearLayout root) {
        LinearLayout card = card(root, null);

        advancedToggle = new TextView(this);
        Theme.style(advancedToggle, 13f, Theme.MUTED, true);
        advancedToggle.setText("ADVANCED  ▾");
        advancedToggle.setLetterSpacing(0.1f);
        advancedToggle.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                advancedOpen = !advancedOpen;
                advancedBody.setVisibility(advancedOpen ? View.VISIBLE : View.GONE);
                advancedToggle.setText(advancedOpen ? "ADVANCED  ▴" : "ADVANCED  ▾");
            }
        });
        card.addView(advancedToggle, fill());

        advancedBody = new LinearLayout(this);
        advancedBody.setOrientation(LinearLayout.VERTICAL);
        advancedBody.setVisibility(View.GONE);
        advancedBody.setPadding(0, Theme.dp(this, 8), 0, 0);
        card.addView(advancedBody, fill());

        advancedBody.addView(label("Rates per 100 niche videos"));
        addRate(advancedBody, "Likes",            Prefs.R_LIKE,    "after 5s · max 92");
        addRate(advancedBody, "Saves",            Prefs.R_SAVE,    "after 12s · max 66");
        addRate(advancedBody, "Comment sections", Prefs.R_COMMENT, "after 4s · max 96");
        addRate(advancedBody, "Comment likes",    Prefs.R_CLIKE,   "while open");
        addRate(advancedBody, "Creator profiles", Prefs.R_PROFILE, "after 8s · max 81");
        addRate(advancedBody, "Follows",          Prefs.R_FOLLOW,  "strong signal, keep low");
        addRate(advancedBody, "Reposts",          Prefs.R_REPOST,  "posts to your followers");
        addRate(advancedBody, "Re-watches",       Prefs.R_REWATCH, "swipe back");

        rateSummary = new TextView(this);
        Theme.style(rateSummary, 11f, Theme.ACCENT_A, false);
        rateSummary.setPadding(0, Theme.dp(this, 12), 0, 0);
        advancedBody.addView(rateSummary, fill());
        updateRateSummary();

        TextView reset = actionBtn("Reset to slider", Theme.MUTED);
        reset.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                prefs.applyLevel(prefs.level());
                loadRateInputs();
                updateLevelText();
                toast("Back on the slider");
            }
        });
        LinearLayout.LayoutParams rlp = fill();
        rlp.topMargin = Theme.dp(this, 12);
        advancedBody.addView(reset, rlp);

        advancedBody.addView(label("Behaviour"));
        advancedBody.addView(toggle("Niche search",
                "Searches your terms and works the results.", Prefs.NICHE_ENABLED, true));
        advancedBody.addView(toggle("Track my own stats",
                "Read-only view counts from your profile.", Prefs.SELF_STATS, true));
        advancedBody.addView(toggle("Research log",
                "Ranks hashtags and sounds by performance.", Prefs.RESEARCH, true));
        advancedBody.addView(toggle("Follow niche creators",
                "Lasting interest signal. Kept low.", Prefs.FOLLOW, true));
        advancedBody.addView(toggle("Like comments", "", Prefs.LIKE_COMMENTS, true));
        advancedBody.addView(toggle("Repost",
                "Posts to your followers, unreviewed.", Prefs.REPOST, false));
        advancedBody.addView(toggle("Floating bubble", "", Prefs.OVERLAY, true));

        advancedBody.addView(label("What it's reading"));
        diagView = new TextView(this);
        Theme.style(diagView, 11f, Theme.MUTED, false);
        diagView.setTypeface(Typeface.MONOSPACE);
        advancedBody.addView(diagView, fill());
    }

    private void addRate(LinearLayout card, String title, final String key, String hint) {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(0, Theme.dp(this, 10), 0, 0);

        LinearLayout left = new LinearLayout(this);
        left.setOrientation(LinearLayout.VERTICAL);
        TextView t = new TextView(this);
        t.setText(title);
        Theme.style(t, 14f, Theme.TEXT, false);
        left.addView(t);
        TextView h = new TextView(this);
        h.setText(hint);
        Theme.style(h, 10f, Theme.FAINT, false);
        left.addView(h);
        row.addView(left, new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));

        EditText e = new EditText(this);
        e.setInputType(InputType.TYPE_CLASS_NUMBER);
        e.setText(String.valueOf(prefs.rate(key)));
        e.setTextColor(Theme.TEXT);
        e.setTextSize(16f);
        e.setGravity(Gravity.CENTER);
        e.setBackground(Theme.card(this, Theme.CARD_HI, 10));
        int q = Theme.dp(this, 8);
        e.setPadding(q, q, q, q);
        e.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence c,int a,int b,int d) { }
            @Override public void onTextChanged(CharSequence c,int a,int b,int d) { }
            @Override public void afterTextChanged(Editable ed) {
                if (suppressRateWatch) return;
                prefs.edit().putInt(key, parseInt(ed.toString(), 0))
                            .putBoolean(Prefs.CUSTOM, true).apply();
                updateLevelText();
                updateRateSummary();
            }
        });
        row.addView(e, new LinearLayout.LayoutParams(
                Theme.dp(this, 66), ViewGroup.LayoutParams.WRAP_CONTENT));
        rateInputs.put(key, e);
        card.addView(row, fill());
    }

    private void loadRateInputs() {
        suppressRateWatch = true;
        for (Map.Entry<String, EditText> en : rateInputs.entrySet()) {
            en.getValue().setText(String.valueOf(prefs.rate(en.getKey())));
        }
        suppressRateWatch = false;
        updateRateSummary();
    }

    private void updateRateSummary() {
        if (rateSummary == null || durationInput == null) return;
        int mins = parseInt(durationInput.getText().toString(), 25);
        int videos = (int) (mins * 60 / 11.0);
        Behavior.Rates r = prefs.rates();
        rateSummary.setText("~" + videos + " videos this session · of the niche ones, ~"
                + Math.round(r.like / 100f * videos) + " likes, ~"
                + Math.round(r.follow / 100f * videos) + " follows.");
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

    // ------------------------------------------------------------ own stats

    private void buildStats(LinearLayout root) {
        LinearLayout card = card(root, "Your account");
        statsView = new TextView(this);
        Theme.style(statsView, 12f, Theme.TEXT, false);
        statsView.setLineSpacing(0f, 1.35f);
        card.addView(statsView, fill());
        card.addView(hint("Content and posting volume move these, not the bot. "
                + "Use it to tell whether a change worked."));
    }

    // -------------------------------------------------------------- research

    private void buildResearch(LinearLayout root) {
        LinearLayout card = card(root, "Niche research");
        researchView = new TextView(this);
        Theme.style(researchView, 12f, Theme.MUTED, false);
        researchView.setLineSpacing(0f, 1.3f);
        card.addView(researchView, fill());

        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        TextView share = actionBtn("Share", Theme.ACCENT_A);
        TextView clear = actionBtn("Clear", Theme.DANGER);
        share.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                Intent i = new Intent(Intent.ACTION_SEND);
                i.setType("text/plain");
                i.putExtra(Intent.EXTRA_TEXT,
                        researchView.getText() + "\n\n" + statsView.getText());
                try { startActivity(Intent.createChooser(i, "Share")); }
                catch (Throwable t) { toast("Nothing to share with"); }
            }
        });
        clear.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                new ResearchLog(MainActivity.this).clear();
                refresh();
                toast("Cleared");
            }
        });
        LinearLayout.LayoutParams a = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        LinearLayout.LayoutParams b = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        b.leftMargin = Theme.dp(this, 8);
        row.addView(share, a);
        row.addView(clear, b);
        LinearLayout.LayoutParams rlp = fill();
        rlp.topMargin = Theme.dp(this, 12);
        card.addView(row, rlp);
    }

    // --------------------------------------------------------------- credits

    private void buildCredits(LinearLayout root) {
        LinearLayout card = card(root, "Credits");
        TextView who = new TextView(this);
        who.setText("Maxime35");
        Theme.style(who, 17f, Theme.TEXT, true);
        card.addView(who, fill());
        card.addView(hint("Cybersecurity graduate, software & bot developer"));
        card.addView(link("Website", "https://louming.dastot.net"));
        card.addView(link("LinkedIn", "https://www.linkedin.com/in/lou-ming-dastot/"));
        card.addView(link("GitHub", "https://github.com/Maxime35510"));
    }

    // ----------------------------------------------------------------- state

    private void refresh() {
        WarmupService svc = WarmupService.instance;
        boolean connected = svc != null;
        serviceWarn.setVisibility(connected ? View.GONE : View.VISIBLE);

        int target = prefs.nicheTarget();
        int now = connected && svc.isRunning() ? svc.rollingPercent()
                                              : new ResearchLog(this).matchedPercent();
        nicheNow.setText(now + "%");
        nicheNow.setTextColor(now >= target ? Theme.OK : Theme.TEXT);
        nicheCaption.setText(connected && svc.isRunning()
                ? "of the last 40 videos matched your niche"
                : "of everything seen so far matched your niche");
        setBar(now, target);

        boolean running = connected && svc.isRunning();
        boolean armed = connected && svc.isArmed();
        boolean paused = running && svc.isPaused();

        if (!connected) {
            bigButton.setText("START");
            bigButton.setBackground(Theme.pressable(Theme.accentCircle(this)));
            statusLine.setText("Service not enabled");
            subStatus.setText("Boost needs accessibility to read the screen");
        } else if (running) {
            long e = svc.elapsedMs() / 1000;
            bigButton.setText(String.format("%d:%02d", e / 60, e % 60));
            bigButton.setBackground(Theme.pressable(Theme.dangerCircle(this)));
            statusLine.setText(paused ? "Paused" : "Boosting");
            subStatus.setText(svc.videoCount() + " videos · "
                    + (svc.remainingMs() / 60000) + " min left\n"
                    + (paused ? "tap the bubble RESUME in TikTok"
                              : "tap here to stop and remove the bubble"));
        } else if (armed) {
            bigButton.setText("ARMED");
            bigButton.setBackground(Theme.pressable(Theme.dangerCircle(this)));
            statusLine.setText("Waiting");
            subStatus.setText("Open TikTok and tap the bubble\n"
                    + "tap here to stop and remove it");
        } else {
            bigButton.setText("START");
            bigButton.setBackground(Theme.pressable(Theme.accentCircle(this)));
            statusLine.setText("Ready");
            subStatus.setText(ActionLog.summary());
        }

        StringBuilder sb = new StringBuilder();
        List<ActionLog.Entry> es = ActionLog.recent(12);
        for (int i = es.size() - 1; i >= 0; i--) {
            ActionLog.Entry en = es.get(i);
            sb.append(ActionLog.clock(en.time)).append("  ").append(en.action);
            if (en.detail.length() > 0) sb.append("  ").append(en.detail);
            sb.append('\n');
        }
        feedView.setText(sb.length() == 0 ? "nothing yet" : sb.toString().trim());

        if (advancedOpen && diagView != null) {
            if (svc == null) diagView.setText("service not running");
            else {
                String t = svc.lastText();
                diagView.setText("caption read:\n"
                        + (t == null || t.length() == 0 ? "(nothing)" : t)
                        + "\nunreadable run: " + svc.unreadableRun());
            }
        }

        statsView.setText(new SelfStats(this).summary());

        ResearchLog r = new ResearchLog(this);
        StringBuilder rb = new StringBuilder();
        rb.append(r.size()).append(" videos seen · ")
          .append(r.matchedPercent()).append("% matched\n");
        appendList(rb, "Hashtags on the best niche videos", r.topHashtags(6));
        appendList(rb, "Sounds", r.topSounds(4));
        appendList(rb, "Creators worth studying", r.topAuthors(4));
        researchView.setText(rb.toString().trim());
    }

    private static void appendList(StringBuilder sb, String title, List<String> items) {
        sb.append('\n').append(title).append('\n');
        if (items.isEmpty()) { sb.append("  —\n"); return; }
        for (String s : items) sb.append("  ").append(s).append('\n');
    }

    private void persist() {
        if (durationInput == null) return;
        SharedPreferences.Editor ed = prefs.edit();
        ed.putInt(Prefs.DURATION, parseInt(durationInput.getText().toString(), 25));
        ed.putString(Prefs.NICHE_TERMS, nicheInput.getText().toString());
        ed.apply();
        WarmupService svc = WarmupService.instance;
        if (svc != null) svc.reload();
    }

    // ----------------------------------------------------------------- views

    private void tint(SeekBar b) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            b.setProgressTintList(
                    android.content.res.ColorStateList.valueOf(Theme.ACCENT_A));
            b.setThumbTintList(
                    android.content.res.ColorStateList.valueOf(Theme.ACCENT_B));
        }
    }

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
        lp.bottomMargin = Theme.dp(this, 12);
        parent.addView(c, lp);
        return c;
    }

    private TextView hint(String text) {
        TextView t = new TextView(this);
        t.setText(text);
        Theme.style(t, 11f, Theme.FAINT, false);
        t.setPadding(0, Theme.dp(this, 4), 0, Theme.dp(this, 10));
        t.setLayoutParams(fill());
        return t;
    }

    private View toggle(String title, String desc, final String key, boolean def) {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.VERTICAL);
        row.setPadding(0, Theme.dp(this, 10), 0, 0);

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
            sw.setThumbTintList(
                    android.content.res.ColorStateList.valueOf(Theme.ACCENT_A));
        }
        sw.setOnCheckedChangeListener(
                new android.widget.CompoundButton.OnCheckedChangeListener() {
            @Override public void onCheckedChanged(
                    android.widget.CompoundButton b, boolean on) {
                prefs.edit().putBoolean(key, on).apply();
                WarmupService svc = WarmupService.instance;
                if (svc != null) svc.reload();
            }
        });
        top.addView(sw);
        row.addView(top, fill());

        if (desc != null && desc.length() > 0) {
            TextView d = new TextView(this);
            d.setText(desc);
            Theme.style(d, 11f, Theme.FAINT, false);
            d.setPadding(0, Theme.dp(this, 1), Theme.dp(this, 48), 0);
            row.addView(d, fill());
        }
        return row;
    }

    private TextView actionBtn(String text, int colour) {
        TextView t = new TextView(this);
        t.setText(text);
        t.setGravity(Gravity.CENTER);
        Theme.style(t, 13f, colour, true);
        t.setPadding(0, Theme.dp(this, 12), 0, Theme.dp(this, 12));
        t.setBackground(Theme.pressable(Theme.card(this, Theme.CARD_HI, 10)));
        return t;
    }

    private TextView link(String text, final String url) {
        TextView t = actionBtn(text, Theme.ACCENT_A);
        t.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                try { startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url))); }
                catch (Throwable t2) { toast("No browser found"); }
            }
        });
        LinearLayout.LayoutParams lp = fill();
        lp.topMargin = Theme.dp(this, 8);
        t.setLayoutParams(lp);
        return t;
    }

    private TextView label(String text) {
        TextView t = new TextView(this);
        t.setText(text);
        Theme.style(t, 12f, Theme.MUTED, false);
        t.setPadding(0, Theme.dp(this, 12), 0, Theme.dp(this, 4));
        t.setLayoutParams(fill());
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

    private void toast(String m) { Toast.makeText(this, m, Toast.LENGTH_SHORT).show(); }

    private static int parseInt(String s, int def) {
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return def; }
    }
}
