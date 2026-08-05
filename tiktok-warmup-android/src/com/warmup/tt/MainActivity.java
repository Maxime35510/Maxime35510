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

    private static final int START_DELAY_SECONDS = 4;

    private Prefs prefs;
    private final Handler ui = new Handler(Looper.getMainLooper());

    private TextView bigButton, statusLine, subStatus, feedView, researchView,
                     statsView, serviceWarn, levelLabel, levelDesc, rateSummary,
                     nicheStatus, durationNote, diagView;
    private EditText durationInput, nicheInput;
    private SeekBar levelBar;
    private final Map<String, EditText> rateInputs = new LinkedHashMap<String, EditText>();
    private boolean suppressRateWatch = false;

    private final Runnable poll = new Runnable() {
        @Override public void run() {
            refresh();
            ui.postDelayed(this, 1200L);
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
        int p = Theme.dp(this, 18);
        root.setPadding(p, Theme.dp(this, 26), p, Theme.dp(this, 44));
        scroll.addView(root, new ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        buildHeader(root);
        buildServiceWarning(root);
        buildControl(root);
        buildNiche(root);
        buildLevel(root);
        buildRates(root);
        buildSession(root);
        buildOptions(root);
        buildLiveFeed(root);
        buildDiagnostics(root);
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
        t.setTextSize(32f);
        t.setTextColor(Theme.TEXT);
        t.setTypeface(t.getTypeface(), Typeface.BOLD);
        root.addView(t);

        TextView s = new TextView(this);
        s.setText("Niche-targeted feed training");
        Theme.style(s, 13f, Theme.MUTED, false);
        s.setPadding(0, Theme.dp(this, 2), 0, Theme.dp(this, 16));
        root.addView(s);
    }

    private void buildServiceWarning(LinearLayout root) {
        serviceWarn = new TextView(this);
        serviceWarn.setText("Accessibility service is off  —  tap to enable");
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
        Theme.style(bigButton, 19f, 0xFF07131A, true);
        bigButton.setBackground(Theme.pressable(Theme.accentCircle(this)));
        int d = Theme.dp(this, 150);
        LinearLayout.LayoutParams blp = new LinearLayout.LayoutParams(d, d);
        blp.topMargin = Theme.dp(this, 4);
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
        subStatus.setPadding(0, Theme.dp(this, 6), 0, 0);
        card.addView(subStatus, fill());
    }

    private void toggleSession() {
        WarmupService svc = WarmupService.instance;
        if (svc == null) {
            toast("Enable the accessibility service first");
            startActivity(new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS));
            return;
        }
        if (svc.isRunning()) { svc.stopSession("user"); refresh(); return; }
        persist();
        svc.arm();
        toast("Open TikTok, then tap the pill");
        moveTaskToBack(true);
        refresh();
    }

    // ----------------------------------------------------------------- niche

    private void buildNiche(LinearLayout root) {
        LinearLayout card = card(root, "Your niche");

        TextView intro = new TextView(this);
        intro.setText("Everything keys off this. Videos matching these words get watched "
                + "properly and engaged with; everything else is skipped in a second and "
                + "touched by nothing.\n\nEngagement that isn't niche-matched teaches "
                + "TikTok your account is interested in something else — which is worse "
                + "than doing nothing. Edit these and it retargets immediately.");
        Theme.style(intro, 11f, Theme.FAINT, false);
        intro.setPadding(0, 0, 0, Theme.dp(this, 10));
        card.addView(intro, fill());

        nicheInput = input(prefs.nicheRaw(),
                InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE);
        nicheInput.setMinLines(5);
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
                if (svc != null) svc.reload();       // retarget live
                updateNicheStatus();
            }
        });
        updateNicheStatus();
    }

    private void updateNicheStatus() {
        Niche n = new Niche(nicheInput.getText().toString());
        if (n.isEmpty()) {
            nicheStatus.setTextColor(Theme.WARN);
            nicheStatus.setText("No keywords — everything counts as a match, which "
                    + "defeats the point. Add a few terms.");
            return;
        }
        StringBuilder sb = new StringBuilder("Matching on " + n.size() + " keywords: ");
        List<String> k = n.keywords();
        for (int i = 0; i < k.size() && i < 10; i++) {
            if (i > 0) sb.append(", ");
            sb.append(k.get(i));
        }
        if (k.size() > 10) sb.append(", +").append(k.size() - 10);
        nicheStatus.setTextColor(Theme.ACCENT_A);
        nicheStatus.setText(sb.toString());
    }

    // ----------------------------------------------------------------- level

    private void buildLevel(LinearLayout root) {
        LinearLayout card = card(root, "Boost level");

        levelLabel = new TextView(this);
        Theme.style(levelLabel, 30f, Theme.TEXT, true);
        card.addView(levelLabel, fill());

        levelBar = new SeekBar(this);
        levelBar.setMax(99);
        levelBar.setProgress(Math.max(0, prefs.level() - 1));
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            levelBar.setProgressTintList(
                    android.content.res.ColorStateList.valueOf(Theme.ACCENT_A));
            levelBar.setThumbTintList(
                    android.content.res.ColorStateList.valueOf(Theme.ACCENT_B));
        }
        LinearLayout.LayoutParams slp = fill();
        slp.topMargin = Theme.dp(this, 6);
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
        if (lvl <= 10)      band = "barely there — a lurker who almost never taps";
        else if (lvl <= 25) band = "around the published human average";
        else if (lvl <= 50) band = "an engaged regular in this niche";
        else if (lvl <= 75) band = "a fan account — very active";
        else                band = "superfan — likes most of what it sees";

        levelDesc.setText(band + "\nper 100 niche videos: " + r.like + " likes, "
                + r.save + " saves, " + r.commentOpen + " comment sections, "
                + r.repost + " reposts, " + r.follow + " follows");
    }

    // ----------------------------------------------------------------- rates

    private void buildRates(LinearLayout root) {
        LinearLayout card = card(root, "Fine tuning");

        TextView intro = new TextView(this);
        intro.setText("Per 100 videos that match your niche. The slider fills these in — "
                + "change any number and it becomes Custom.");
        Theme.style(intro, 11f, Theme.FAINT, false);
        intro.setPadding(0, 0, 0, Theme.dp(this, 4));
        card.addView(intro, fill());

        addRate(card, "Likes",             Prefs.R_LIKE,    "after 5s watched · max 92");
        addRate(card, "Saves",             Prefs.R_SAVE,    "after 12s · max 66");
        addRate(card, "Comment sections",  Prefs.R_COMMENT, "after 4s · max 96");
        addRate(card, "Comment likes",     Prefs.R_CLIKE,   "while a sheet is open");
        addRate(card, "Creator profiles",  Prefs.R_PROFILE, "after 8s · max 81");
        addRate(card, "Follows",           Prefs.R_FOLLOW,  "after 15s · strong signal, keep low");
        addRate(card, "Reposts",           Prefs.R_REPOST,  "posts to your followers");
        addRate(card, "Re-watches",        Prefs.R_REWATCH, "swipe back and watch again");

        rateSummary = new TextView(this);
        Theme.style(rateSummary, 11f, Theme.ACCENT_A, false);
        rateSummary.setPadding(0, Theme.dp(this, 14), 0, 0);
        card.addView(rateSummary, fill());

        TextView reset = new TextView(this);
        reset.setText("Reset to slider");
        reset.setGravity(Gravity.CENTER);
        Theme.style(reset, 12f, Theme.MUTED, true);
        reset.setPadding(0, Theme.dp(this, 11), 0, Theme.dp(this, 11));
        reset.setBackground(Theme.pressable(Theme.card(this, Theme.CARD_HI, 10)));
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
        card.addView(reset, rlp);
    }

    private void addRate(LinearLayout card, String title, final String key, String hint) {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(0, Theme.dp(this, 11), 0, 0);

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
                Theme.dp(this, 68), ViewGroup.LayoutParams.WRAP_CONTENT));

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
        // Matched videos are watched properly, so a session covers fewer of them.
        int videos = (int) (mins * 60 / 11.0);
        Behavior.Rates r = prefs.rates();
        rateSummary.setText("A " + mins + " min session covers roughly " + videos
                + " videos. Of the ones that match your niche: ~"
                + Math.round(r.like / 100f * videos) + " likes, ~"
                + Math.round(r.commentOpen / 100f * videos) + " comment sections, ~"
                + Math.round(r.follow / 100f * videos) + " follows.");
    }

    // --------------------------------------------------------------- session

    private void buildSession(LinearLayout root) {
        LinearLayout card = card(root, "Session");

        card.addView(label("Duration (minutes)"));
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
        updateRateSummary();

        card.addView(toggle("Auto sessions", "When one finishes, wait 8–42 minutes and "
                + "run another by itself. Several short visits a day is the human "
                + "pattern; one long block isn't.", Prefs.AUTO, true));
    }

    private void updateDurationNote() {
        int d = parseInt(durationInput.getText().toString(), 25);
        durationNote.setText("Example: set " + d + " and it actually runs "
                + Math.round(d * 0.75) + "–" + Math.round(d * 1.25)
                + " min, picked at start. People don't stop on a round number.");
    }

    // --------------------------------------------------------------- options

    private void buildOptions(LinearLayout root) {
        LinearLayout card = card(root, "Behaviour");
        card.addView(toggle("Niche search", "Periodically searches one of your terms and "
                + "browses the results. Search intent is a strong signal — it's the "
                + "fastest way to pull the For You page toward your niche.",
                Prefs.NICHE_ENABLED, true));
        card.addView(toggle("Track my own stats", "Visits your profile once a session and "
                + "records each video's view count. Read-only. TikTok keeps no history, "
                + "so this builds it.", Prefs.SELF_STATS, true));
        card.addView(toggle("Research log", "Records creators, hashtags, sounds and their "
                + "like counts, then ranks them.", Prefs.RESEARCH, true));
        card.addView(toggle("Follow niche creators", "A lasting interest signal. Kept low "
                + "on purpose — bulk following is a spam pattern.", Prefs.FOLLOW, true));
        card.addView(toggle("Like comments", "Occasionally likes a comment while a sheet "
                + "is open.", Prefs.LIKE_COMMENTS, true));
        card.addView(toggle("Repost", "Off by default. Pushes a video to your followers "
                + "under your name, picked by something that can't see it.",
                Prefs.REPOST, false));
        card.addView(toggle("Floating panel", "Draggable control on the left edge, where "
                + "the bot's own taps never reach.", Prefs.OVERLAY, true));
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

    // ----------------------------------------------------------- diagnostics

    /**
     * Shows the text the service is actually reading off each video. When matching
     * silently failed, every video scored zero and the app did nothing at all with no
     * way to see why - this makes that visible.
     */
    private void buildDiagnostics(LinearLayout root) {
        LinearLayout card = card(root, "What it's reading");
        diagView = new TextView(this);
        Theme.style(diagView, 11f, Theme.MUTED, false);
        diagView.setTypeface(Typeface.MONOSPACE);
        diagView.setLineSpacing(0f, 1.25f);
        card.addView(diagView, fill());

        TextView note = new TextView(this);
        note.setText("If the niche match rate stays at 0% and the text below is empty, "
                + "it can't read captions on your device — tell me and I'll widen it. "
                + "Videos it can't read are marked \"unsure\": watched a medium amount, "
                + "engaged with at 30% of your rates rather than skipped entirely.");
        Theme.style(note, 10f, Theme.FAINT, false);
        note.setPadding(0, Theme.dp(this, 10), 0, 0);
        card.addView(note, fill());
    }

    // ------------------------------------------------------------ own stats

    private void buildStats(LinearLayout root) {
        LinearLayout card = card(root, "Your account");
        statsView = new TextView(this);
        Theme.style(statsView, 12f, Theme.TEXT, false);
        statsView.setLineSpacing(0f, 1.35f);
        card.addView(statsView, fill());

        TextView note = new TextView(this);
        note.setText("This is the feedback loop. Nothing the bot does moves these numbers "
                + "directly — content and posting volume do. Use it to tell whether a "
                + "change you made actually worked.");
        Theme.style(note, 10f, Theme.FAINT, false);
        note.setPadding(0, Theme.dp(this, 10), 0, 0);
        card.addView(note, fill());
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
                i.putExtra(Intent.EXTRA_SUBJECT, "Niche research");
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
                toast("Research log cleared");
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

    private TextView actionBtn(String text, int colour) {
        TextView t = new TextView(this);
        t.setText(text);
        t.setGravity(Gravity.CENTER);
        Theme.style(t, 13f, colour, true);
        t.setPadding(0, Theme.dp(this, 12), 0, Theme.dp(this, 12));
        t.setBackground(Theme.pressable(Theme.card(this, Theme.CARD_HI, 10)));
        return t;
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
        int q = Theme.dp(this, 13);
        t.setPadding(q, q, q, q);
        t.setBackground(Theme.pressable(Theme.card(this, Theme.CARD_HI, 10)));
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

    // ----------------------------------------------------------------- state

    private void refresh() {
        WarmupService svc = WarmupService.instance;
        boolean connected = svc != null;
        serviceWarn.setVisibility(connected ? View.GONE : View.VISIBLE);

        boolean running = connected && svc.isRunning();
        bigButton.setText(running ? "STOP"
                : (connected && svc.isArmed() ? "ARMED" : "START"));
        bigButton.setBackground(Theme.pressable(
                running ? Theme.dangerCircle(this) : Theme.accentCircle(this)));

        if (!connected) {
            statusLine.setText("Service not enabled");
            subStatus.setText("Boost needs the accessibility service to read the screen");
        } else if (!running) {
            boolean armed = svc.isArmed();
            statusLine.setText(armed ? "Armed" : "Ready");
            subStatus.setText(armed
                    ? "Open TikTok and tap the pill.\nLong-press it to hide."
                    : ActionLog.summary());
        } else {
            long s = svc.remainingMs() / 1000;
            statusLine.setText((svc.isPaused() ? "Paused · " : "")
                    + String.format("%d:%02d", s / 60, s % 60) + " left");
            subStatus.setText(svc.videoCount() + " videos · " + svc.matchedPercent()
                    + "% niche\n" + svc.detectedScreen().toLowerCase()
                    + " · " + svc.lastAction());
        }

        StringBuilder sb = new StringBuilder();
        List<ActionLog.Entry> es = ActionLog.recent(14);
        for (int i = es.size() - 1; i >= 0; i--) {
            ActionLog.Entry e = es.get(i);
            sb.append(ActionLog.clock(e.time)).append("  ").append(e.action);
            if (e.detail.length() > 0) sb.append("  ").append(e.detail);
            sb.append('\n');
        }
        feedView.setText(sb.length() == 0 ? "nothing yet" : sb.toString().trim());

        if (svc == null) {
            diagView.setText("service not running");
        } else {
            String t = svc.lastText();
            diagView.setText("last caption read:\n"
                    + (t == null || t.length() == 0 ? "(nothing)" : t)
                    + "\n\nunreadable in a row: " + svc.unreadableRun()
                    + "\nniche match rate: " + svc.matchedPercent() + "%");
        }

        statsView.setText(new SelfStats(this).summary());

        ResearchLog r = new ResearchLog(this);
        StringBuilder rb = new StringBuilder();
        rb.append(r.size()).append(" videos seen · ")
          .append(r.matchedPercent()).append("% matched your niche\n");
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
        t.setPadding(0, Theme.dp(this, 8), 0, Theme.dp(this, 6));
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
