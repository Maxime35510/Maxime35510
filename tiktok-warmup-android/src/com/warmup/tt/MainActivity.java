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

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class MainActivity extends Activity {

    private static final String[] TABS = { "BOOST", "TUNE", "DATA", "ABOUT" };

    private Prefs prefs;
    private final Handler ui = new Handler(Looper.getMainLooper());

    private final List<TextView> tabViews = new ArrayList<TextView>();
    private final List<LinearLayout> pages = new ArrayList<LinearLayout>();
    private int tab = 0;

    private TextView bigButton, statusLine, subStatus, serviceWarn;
    private TextView nicheNow, nicheCaption, targetLabel;
    private View barFill, barRest;
    private SeekBar targetBar, levelBar;
    private TextView levelLabel, levelDesc, rateSummary, nicheStatus, durationNote, gapLabel;
    private SeekBar gapMinBar, gapMaxBar;
    private TextView feedView, diagView, statsView, researchView, actionReport,
                     suggestView, sessionView;
    private EditText durationInput, nicheInput;
    private final Map<String, EditText> rateInputs = new LinkedHashMap<String, EditText>();
    private boolean suppressRateWatch = false;

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

        LinearLayout shell = new LinearLayout(this);
        shell.setOrientation(LinearLayout.VERTICAL);
        shell.setBackgroundColor(Theme.BG);
        // Without this the first EditText grabs focus and the keyboard springs up.
        shell.setFocusableInTouchMode(true);

        shell.addView(buildTopBar());
        shell.addView(buildTabBar());

        ScrollView scroll = new ScrollView(this);
        LinearLayout body = new LinearLayout(this);
        body.setOrientation(LinearLayout.VERTICAL);
        int p = Theme.dp(this, 16);
        body.setPadding(p, p, p, Theme.dp(this, 48));
        scroll.addView(body, new ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        shell.addView(scroll, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));

        for (int i = 0; i < TABS.length; i++) {
            LinearLayout page = new LinearLayout(this);
            page.setOrientation(LinearLayout.VERTICAL);
            page.setVisibility(i == 0 ? View.VISIBLE : View.GONE);
            body.addView(page, new LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT));
            pages.add(page);
        }

        buildBoostPage(pages.get(0));
        buildTunePage(pages.get(1));
        buildDataPage(pages.get(2));
        buildAboutPage(pages.get(3));

        setContentView(shell);
        shell.requestFocus();
        Notifications.ensureChannel(this);
    }

    @Override protected void onResume() { super.onResume(); ui.post(poll); }
    @Override protected void onPause()  { super.onPause(); ui.removeCallbacks(poll); persist(); }

    // ------------------------------------------------------------ chrome

    private View buildTopBar() {
        LinearLayout bar = new LinearLayout(this);
        bar.setOrientation(LinearLayout.VERTICAL);
        int p = Theme.dp(this, 16);
        bar.setPadding(p, Theme.dp(this, 38), p, Theme.dp(this, 4));

        TextView t = new TextView(this);
        t.setText("TikTok Boost");
        t.setTextSize(26f);
        t.setTextColor(Theme.TEXT);
        t.setTypeface(t.getTypeface(), Typeface.BOLD);
        bar.addView(t);

        serviceWarn = new TextView(this);
        serviceWarn.setText("Accessibility service off — tap to set up");
        Theme.style(serviceWarn, 12f, 0xFF1A1200, true);
        serviceWarn.setBackground(Theme.solid(this, Theme.WARN, 10));
        int q = Theme.dp(this, 10);
        serviceWarn.setPadding(q, q, q, q);
        serviceWarn.setGravity(Gravity.CENTER);
        serviceWarn.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { showSetup(); }
        });
        LinearLayout.LayoutParams lp = fill();
        lp.topMargin = Theme.dp(this, 10);
        bar.addView(serviceWarn, lp);
        return bar;
    }

    private View buildTabBar() {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        int p = Theme.dp(this, 16);
        row.setPadding(p, Theme.dp(this, 10), p, Theme.dp(this, 10));

        for (int i = 0; i < TABS.length; i++) {
            final int idx = i;
            TextView t = new TextView(this);
            t.setText(TABS[i]);
            t.setGravity(Gravity.CENTER);
            t.setPadding(0, Theme.dp(this, 13), 0, Theme.dp(this, 13));
            Theme.style(t, 12f, Theme.MUTED, true);
            t.setLetterSpacing(0.08f);
            t.setOnClickListener(new View.OnClickListener() {
                @Override public void onClick(View v) { selectTab(idx); }
            });
            LinearLayout.LayoutParams lp =
                    new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
            lp.leftMargin = i == 0 ? 0 : Theme.dp(this, 6);
            row.addView(t, lp);
            tabViews.add(t);
        }
        selectTabStyle();
        return row;
    }

    private void selectTab(int i) {
        tab = i;
        for (int k = 0; k < pages.size(); k++) {
            pages.get(k).setVisibility(k == i ? View.VISIBLE : View.GONE);
        }
        selectTabStyle();
        refresh();
    }

    private void selectTabStyle() {
        for (int k = 0; k < tabViews.size(); k++) {
            TextView t = tabViews.get(k);
            boolean on = k == tab;
            t.setBackground(on ? Theme.accent(this, 9)
                               : Theme.card(this, Theme.CARD, 9));
            t.setTextColor(on ? 0xFF07131A : Theme.MUTED);
        }
    }

    // ------------------------------------------------------------ BOOST tab

    private void buildBoostPage(LinearLayout root) {
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

        LinearLayout track = new LinearLayout(this);
        track.setOrientation(LinearLayout.HORIZONTAL);
        track.setBackground(Theme.solid(this, Theme.CARD_HI, 6));
        barFill = new View(this);
        barFill.setBackground(Theme.accent(this, 6));
        barRest = new View(this);
        track.addView(barFill, new LinearLayout.LayoutParams(0, Theme.dp(this, 10), 0f));
        track.addView(barRest, new LinearLayout.LayoutParams(0, Theme.dp(this, 10), 100f));
        card.addView(track, fill());

        targetLabel = new TextView(this);
        Theme.style(targetLabel, 12f, Theme.MUTED, false);
        targetLabel.setPadding(0, Theme.dp(this, 14), 0, 0);
        card.addView(targetLabel, fill());

        targetBar = new SeekBar(this);
        targetBar.setMax(90);
        targetBar.setProgress(Math.max(0, prefs.nicheTarget() - 10));
        tint(targetBar);
        targetBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override public void onProgressChanged(SeekBar s, int v, boolean u) {
                if (!u) return;
                prefs.edit().putInt(Prefs.TARGET, v + 10).apply();
                reloadService();
                updateTargetLabel();
            }
            @Override public void onStartTrackingTouch(SeekBar s) { }
            @Override public void onStopTrackingTouch(SeekBar s) { }
        });
        card.addView(targetBar, fill());
        updateTargetLabel();

        LinearLayout ctl = card(root, null);
        ctl.setGravity(Gravity.CENTER_HORIZONTAL);
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
        ctl.addView(bigButton, blp);

        statusLine = new TextView(this);
        statusLine.setGravity(Gravity.CENTER);
        Theme.style(statusLine, 15f, Theme.TEXT, true);
        ctl.addView(statusLine, fill());

        subStatus = new TextView(this);
        subStatus.setGravity(Gravity.CENTER);
        Theme.style(subStatus, 12f, Theme.MUTED, false);
        subStatus.setPadding(0, Theme.dp(this, 6), 0, 0);
        ctl.addView(subStatus, fill());
    }

    private void updateTargetLabel() {
        targetLabel.setText("Target " + prefs.nicheTarget() + "% — below it, searches "
                + "more often and skips faster");
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

    /** Walk through enabling the service - the step everyone gets stuck on. */
    private void showSetup() {
        new android.app.AlertDialog.Builder(this)
            .setTitle("Enable TikTok Boost")
            .setMessage("Boost reads the screen to tell which videos are in your "
                    + "niche, and taps for you. Android puts that behind "
                    + "Accessibility.\n\n"
                    + "1.  Tap Open settings below\n"
                    + "2.  Find Installed apps  (or Downloaded services)\n"
                    + "3.  Choose TikTok Boost\n"
                    + "4.  Turn it on and confirm\n"
                    + "5.  Come back here\n\n"
                    + "Some phones also ask you to allow restricted settings — if "
                    + "the toggle is greyed out, open App info for TikTok Boost, tap "
                    + "the ⋮ menu, and choose Allow restricted settings.")
            .setPositiveButton("Open settings",
                    new android.content.DialogInterface.OnClickListener() {
                @Override public void onClick(android.content.DialogInterface d, int w) {
                    try {
                        startActivity(new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS));
                    } catch (Throwable t) { toast("Couldn't open settings"); }
                }
            })
            .setNegativeButton("Later", null)
            .show();
    }

    private void onBigButton() {
        WarmupService svc = WarmupService.instance;
        if (svc == null) {
            showSetup();
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

    // ------------------------------------------------------------- TUNE tab

    private void buildTunePage(LinearLayout root) {
        LinearLayout n = card(root, "Your niche");
        n.addView(hint("Matching videos get watched fully and engaged with. Everything "
                + "else is skipped. Edits apply immediately."));
        nicheInput = input(prefs.nicheRaw(),
                InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE);
        nicheInput.setMinLines(4);
        nicheInput.setGravity(Gravity.TOP);
        n.addView(nicheInput, fill());
        nicheStatus = new TextView(this);
        Theme.style(nicheStatus, 11f, Theme.ACCENT_A, false);
        nicheStatus.setPadding(0, Theme.dp(this, 8), 0, 0);
        n.addView(nicheStatus, fill());
        nicheInput.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence c,int a,int b,int d) { }
            @Override public void onTextChanged(CharSequence c,int a,int b,int d) { }
            @Override public void afterTextChanged(Editable e) {
                prefs.edit().putString(Prefs.NICHE_TERMS, e.toString()).apply();
                reloadService();
                updateNicheStatus();
            }
        });
        updateNicheStatus();

        LinearLayout lv = card(root, "Boost level");
        levelLabel = new TextView(this);
        Theme.style(levelLabel, 28f, Theme.TEXT, true);
        lv.addView(levelLabel, fill());
        levelBar = new SeekBar(this);
        levelBar.setMax(99);
        levelBar.setProgress(Math.max(0, prefs.level() - 1));
        tint(levelBar);
        lv.addView(levelBar, fill());
        levelDesc = new TextView(this);
        Theme.style(levelDesc, 11f, Theme.FAINT, false);
        levelDesc.setPadding(0, Theme.dp(this, 8), 0, 0);
        lv.addView(levelDesc, fill());
        levelBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override public void onProgressChanged(SeekBar s, int v, boolean u) {
                if (!u) return;
                prefs.applyLevel(v + 1);
                loadRateInputs();
                updateLevelText();
            }
            @Override public void onStartTrackingTouch(SeekBar s) { }
            @Override public void onStopTrackingTouch(SeekBar s) { }
        });
        updateLevelText();

        LinearLayout se = card(root, "Session");
        se.addView(label("Minutes"));
        durationInput = input(String.valueOf(prefs.duration()), InputType.TYPE_CLASS_NUMBER);
        se.addView(durationInput, fill());
        durationNote = new TextView(this);
        Theme.style(durationNote, 11f, Theme.FAINT, false);
        durationNote.setPadding(0, Theme.dp(this, 6), 0, 0);
        se.addView(durationNote, fill());
        durationInput.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence c,int a,int b,int d) { }
            @Override public void onTextChanged(CharSequence c,int a,int b,int d) { }
            @Override public void afterTextChanged(Editable e) {
                updateDurationNote(); updateRateSummary();
            }
        });
        updateDurationNote();

        se.addView(toggle("Auto sessions",
                "Runs again by itself after the break below.", Prefs.AUTO, true));

        gapLabel = new TextView(this);
        Theme.style(gapLabel, 12f, Theme.MUTED, false);
        gapLabel.setPadding(0, Theme.dp(this, 12), 0, Theme.dp(this, 4));
        se.addView(gapLabel, fill());

        gapMinBar = new SeekBar(this);
        gapMinBar.setMax(119);
        gapMinBar.setProgress(Math.max(0, prefs.gapMin() - 1));
        tint(gapMinBar);
        se.addView(gapMinBar, fill());

        gapMaxBar = new SeekBar(this);
        gapMaxBar.setMax(119);
        gapMaxBar.setProgress(Math.max(0, prefs.gapMax() - 1));
        tint(gapMaxBar);
        se.addView(gapMaxBar, fill());

        SeekBar.OnSeekBarChangeListener gapWatch = new SeekBar.OnSeekBarChangeListener() {
            @Override public void onProgressChanged(SeekBar s, int v, boolean u) {
                if (!u) return;
                int lo = gapMinBar.getProgress() + 1, hi = gapMaxBar.getProgress() + 1;
                if (hi < lo) { hi = lo; gapMaxBar.setProgress(hi - 1); }
                prefs.edit().putInt(Prefs.GAP_MIN, lo).putInt(Prefs.GAP_MAX, hi).apply();
                reloadService();
                updateGapLabel();
            }
            @Override public void onStartTrackingTouch(SeekBar s) { }
            @Override public void onStopTrackingTouch(SeekBar s) { }
        };
        gapMinBar.setOnSeekBarChangeListener(gapWatch);
        gapMaxBar.setOnSeekBarChangeListener(gapWatch);
        updateGapLabel();

        LinearLayout rt = card(root, "Rates per 100 niche videos");
        addRate(rt, "Likes",            Prefs.R_LIKE,    "after 5s · max 92");
        addRate(rt, "Saves",            Prefs.R_SAVE,    "after 12s · max 66");
        addRate(rt, "Comment sections", Prefs.R_COMMENT, "after 4s · max 96");
        addRate(rt, "Comment likes",    Prefs.R_CLIKE,   "while open");
        addRate(rt, "Creator profiles", Prefs.R_PROFILE, "after 8s · max 81");
        addRate(rt, "Follows",          Prefs.R_FOLLOW,  "strong signal, keep low");
        addRate(rt, "Reposts",          Prefs.R_REPOST,  "posts to your followers");
        addRate(rt, "Re-watches",       Prefs.R_REWATCH, "swipe back");
        rateSummary = new TextView(this);
        Theme.style(rateSummary, 11f, Theme.ACCENT_A, false);
        rateSummary.setPadding(0, Theme.dp(this, 12), 0, 0);
        rt.addView(rateSummary, fill());
        updateRateSummary();
        TextView reset = actionBtn("Reset to slider", Theme.MUTED);
        reset.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                prefs.applyLevel(prefs.level());
                loadRateInputs(); updateLevelText(); toast("Back on the slider");
            }
        });
        LinearLayout.LayoutParams rlp = fill();
        rlp.topMargin = Theme.dp(this, 12);
        rt.addView(reset, rlp);

        LinearLayout bh = card(root, "Behaviour");
        bh.addView(toggle("Niche search",
                "Searches your terms and works the results.", Prefs.NICHE_ENABLED, true));
        bh.addView(toggle("Track my own stats",
                "Read-only view counts from your profile.", Prefs.SELF_STATS, true));
        bh.addView(toggle("Research log", "", Prefs.RESEARCH, true));
        bh.addView(toggle("Follow niche creators", "", Prefs.FOLLOW, true));
        bh.addView(toggle("Like comments", "", Prefs.LIKE_COMMENTS, true));
        bh.addView(toggle("Repost",
                "Posts to your followers, unreviewed.", Prefs.REPOST, false));
        bh.addView(toggle("Floating bubble", "", Prefs.OVERLAY, true));
    }

    private void updateGapLabel() {
        gapLabel.setText("Break between sessions: " + prefs.gapMin() + "–"
                + prefs.gapMax() + " min   (min / max)");
    }

    private void updateNicheStatus() {
        Niche n = new Niche(nicheInput.getText().toString());
        if (n.isEmpty()) {
            nicheStatus.setTextColor(Theme.WARN);
            nicheStatus.setText("No keywords — everything counts as a match.");
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
        levelDesc.setText(band + " · " + r.like + " likes, " + r.save + " saves, "
                + r.commentOpen + " comments, " + r.follow + " follows, "
                + r.repost + " reposts");
    }

    private void updateDurationNote() {
        int d = parseInt(durationInput.getText().toString(), 25);
        durationNote.setText("Each run lands anywhere in " + Math.round(d * 0.75) + "–"
                + Math.round(d * 1.25) + " min, picked at start — real sessions don't "
                + "end on a round number.");
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
                updateLevelText(); updateRateSummary();
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
        rateSummary.setText("~" + videos + " videos a session · of the niche ones, ~"
                + Math.round(r.like / 100f * videos) + " likes, ~"
                + Math.round(r.follow / 100f * videos) + " follows.");
    }

    // ------------------------------------------------------------- DATA tab

    private void buildDataPage(LinearLayout root) {
        LinearLayout lv = card(root, "Live");
        feedView = new TextView(this);
        Theme.style(feedView, 12f, Theme.MUTED, false);
        feedView.setTypeface(Typeface.MONOSPACE);
        feedView.setLineSpacing(0f, 1.25f);
        lv.addView(feedView, fill());

        LinearLayout ar = card(root, "Does it actually work?");
        ar.addView(hint("Every action needs to find a button in TikTok's accessibility "
                + "tree, and that can fail silently. This counts both outcomes — if "
                + "something never works on your phone, turn it off."));
        actionReport = new TextView(this);
        Theme.style(actionReport, 12f, Theme.TEXT, false);
        actionReport.setTypeface(Typeface.MONOSPACE);
        actionReport.setLineSpacing(0f, 1.3f);
        ar.addView(actionReport, fill());

        LinearLayout sh = card(root, "Sessions");
        sh.addView(hint("Whether this climbs across sessions is the only real evidence "
                + "the feed is retraining."));
        sessionView = new TextView(this);
        Theme.style(sessionView, 12f, Theme.TEXT, false);
        sessionView.setTypeface(Typeface.MONOSPACE);
        sessionView.setLineSpacing(0f, 1.3f);
        sh.addView(sessionView, fill());

        LinearLayout st = card(root, "Your account");
        statsView = new TextView(this);
        Theme.style(statsView, 12f, Theme.TEXT, false);
        statsView.setLineSpacing(0f, 1.35f);
        st.addView(statsView, fill());
        st.addView(hint("Content and posting volume move these, not the bot."));

        LinearLayout sg = card(root, "Suggested terms");
        sg.addView(hint("Hashtags that keep appearing on your niche videos but aren't "
                + "in your terms. Adding them widens what counts as a match."));
        suggestView = new TextView(this);
        Theme.style(suggestView, 13f, Theme.ACCENT_A, false);
        sg.addView(suggestView, fill());
        TextView add = actionBtn("Add all to my niche", Theme.ACCENT_A);
        add.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { addSuggestions(); }
        });
        LinearLayout.LayoutParams alp = fill();
        alp.topMargin = Theme.dp(this, 12);
        sg.addView(add, alp);

        LinearLayout rs = card(root, "Niche research");
        researchView = new TextView(this);
        Theme.style(researchView, 12f, Theme.MUTED, false);
        researchView.setLineSpacing(0f, 1.3f);
        rs.addView(researchView, fill());
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        TextView share = actionBtn("Share", Theme.ACCENT_A);
        TextView clear = actionBtn("Clear", Theme.DANGER);
        share.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                Intent i = new Intent(Intent.ACTION_SEND);
                i.setType("text/plain");
                i.putExtra(Intent.EXTRA_TEXT, researchView.getText() + "\n\n"
                        + statsView.getText() + "\n\n" + actionReport.getText());
                try { startActivity(Intent.createChooser(i, "Share")); }
                catch (Throwable t) { toast("Nothing to share with"); }
            }
        });
        clear.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                new ResearchLog(MainActivity.this).clear(); refresh(); toast("Cleared");
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
        rs.addView(row, rlp);
    }

    private void addSuggestions() {
        List<String> s = new ResearchLog(this)
                .suggestedTerms(new Niche(nicheInput.getText().toString()), 8);
        if (s.isEmpty()) { toast("Nothing to add yet"); return; }
        StringBuilder sb = new StringBuilder(nicheInput.getText().toString());
        for (String t : s) sb.append('\n').append(t);
        nicheInput.setText(sb.toString());
        prefs.edit().putString(Prefs.NICHE_TERMS, sb.toString()).apply();
        reloadService();
        updateNicheStatus();
        toast("Added " + s.size() + " terms");
    }

    // ------------------------------------------------------------ ABOUT tab

    private void buildAboutPage(LinearLayout root) {
        LinearLayout dg = card(root, "What it's reading");
        dg.addView(hint("The caption text captured from the last video. If this stays "
                + "empty and the niche score stays at 0%, matching can't see captions "
                + "on your device."));
        diagView = new TextView(this);
        Theme.style(diagView, 11f, Theme.MUTED, false);
        diagView.setTypeface(Typeface.MONOSPACE);
        dg.addView(diagView, fill());

        LinearLayout cr = card(root, "Credits");
        TextView who = new TextView(this);
        who.setText("Maxime35");
        Theme.style(who, 17f, Theme.TEXT, true);
        cr.addView(who, fill());
        cr.addView(hint("Cybersecurity graduate, software & bot developer"));
        cr.addView(link("Website", "https://louming.dastot.net"));
        cr.addView(link("LinkedIn", "https://www.linkedin.com/in/lou-ming-dastot/"));
        cr.addView(link("GitHub", "https://github.com/Maxime35510"));
    }

    // ----------------------------------------------------------------- state

    private void refresh() {
        WarmupService svc = WarmupService.instance;
        boolean connected = svc != null;
        serviceWarn.setVisibility(connected ? View.GONE : View.VISIBLE);

        boolean running = connected && svc.isRunning();
        boolean armed = connected && svc.isArmed();
        boolean paused = running && svc.isPaused();
        int target = prefs.nicheTarget();

        if (tab == 0) {
            // Three different things used to land in this slot: the live score, the
            // lifetime research figure, and nothing at all. Now it always says which.
            if (running && !svc.scoreReady()) {
                nicheNow.setTextSize(30f);
                nicheNow.setText("scoring");
                nicheNow.setTextColor(Theme.MUTED);
                nicheCaption.setText(svc.scoreSample() + " of "
                        + WarmupService.MIN_SAMPLE + " For You videos needed");
                setBar(0, target);
            } else if (running) {
                int now = svc.rollingPercent();
                nicheNow.setTextSize(52f);
                nicheNow.setText(now + "%");
                nicheNow.setTextColor(now >= target ? Theme.OK : Theme.TEXT);
                nicheCaption.setText("live · last " + svc.scoreSample()
                        + " For You videos");
                setBar(now, target);
            } else {
                int last = new SessionLog(this).lastScore();
                if (last >= 0) {
                    nicheNow.setTextSize(52f);
                    nicheNow.setText(last + "%");
                    nicheNow.setTextColor(last >= target ? Theme.OK : Theme.TEXT);
                    nicheCaption.setText("last finished session");
                    setBar(last, target);
                } else {
                    nicheNow.setTextSize(26f);
                    nicheNow.setText("Not measured yet");
                    nicheNow.setTextColor(Theme.MUTED);
                    nicheCaption.setText("run a session to score your For You page");
                    setBar(0, target);
                }
            }

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
                        + svc.plannedMinutes() + " min session\n"
                        + (paused ? "tap RESUME on the bubble in TikTok"
                                  : "tap here to stop and remove the bubble"));
            } else if (armed) {
                bigButton.setText("ARMED");
                bigButton.setBackground(Theme.pressable(
                        Theme.solid(this, Theme.WARN, 999)));
                statusLine.setText("Waiting");
                subStatus.setText("Open TikTok and tap the bubble\n"
                        + "drag it onto the ✕ to close, or tap here");
            } else {
                bigButton.setText("START");
                bigButton.setBackground(Theme.pressable(Theme.accentCircle(this)));
                statusLine.setText("Ready");
                subStatus.setText(ActionLog.summary());
            }
        }

        if (tab == 2) {
            StringBuilder sb = new StringBuilder();
            List<ActionLog.Entry> es = ActionLog.recent(14);
            for (int i = es.size() - 1; i >= 0; i--) {
                ActionLog.Entry en = es.get(i);
                sb.append(ActionLog.clock(en.time)).append("  ").append(en.action);
                if (en.detail.length() > 0) sb.append("  ").append(en.detail);
                sb.append('\n');
            }
            feedView.setText(sb.length() == 0 ? "nothing yet" : sb.toString().trim());
            actionReport.setText(ActionStats.report());
            sessionView.setText(new SessionLog(this).summary(6));
            statsView.setText(new SelfStats(this).summary());

            ResearchLog r = new ResearchLog(this);
            List<String> sug = r.suggestedTerms(
                    new Niche(nicheInput.getText().toString()), 8);
            suggestView.setText(sug.isEmpty() ? "nothing yet — needs a few sessions"
                                              : join(sug));
            StringBuilder rb = new StringBuilder();
            int life = r.matchedPercent();
            rb.append(r.size()).append(" logged · ").append(r.scoredCount())
              .append(" scored from For You");
            if (life >= 0) rb.append(" · ").append(life).append("% matched");
            rb.append('\n');
            appendList(rb, "Hashtags on the best niche videos", r.topHashtags(6));
            appendList(rb, "Sounds", r.topSounds(4));
            appendList(rb, "Creators worth studying", r.topAuthors(4));
            researchView.setText(rb.toString().trim());
        }

        if (tab == 3) {
            if (svc == null) diagView.setText("service not running");
            else {
                String t = svc.lastText();
                diagView.setText((t == null || t.length() == 0 ? "(nothing)" : t)
                        + "\n\nunreadable run: " + svc.unreadableRun());
            }
        }
    }

    private static String join(List<String> l) {
        StringBuilder sb = new StringBuilder();
        for (String s : l) { if (sb.length() > 0) sb.append(",  "); sb.append(s); }
        return sb.toString();
    }

    private static void appendList(StringBuilder sb, String title, List<String> items) {
        sb.append('\n').append(title).append('\n');
        if (items.isEmpty()) { sb.append("  —\n"); return; }
        for (String s : items) sb.append("  ").append(s).append('\n');
    }

    private void reloadService() {
        WarmupService svc = WarmupService.instance;
        if (svc != null) svc.reload();
    }

    private void persist() {
        if (durationInput == null) return;
        SharedPreferences.Editor ed = prefs.edit();
        ed.putInt(Prefs.DURATION, parseInt(durationInput.getText().toString(), 25));
        ed.putString(Prefs.NICHE_TERMS, nicheInput.getText().toString());
        ed.apply();
        reloadService();
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
        t.setPadding(0, Theme.dp(this, 2), 0, Theme.dp(this, 10));
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
                reloadService();
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
        t.setPadding(0, Theme.dp(this, 10), 0, Theme.dp(this, 4));
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
