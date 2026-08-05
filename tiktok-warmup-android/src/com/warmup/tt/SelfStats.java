package com.warmup.tt;

import android.content.Context;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;

/**
 * Snapshots of your own videos' view counts over time.
 *
 * TikTok shows current numbers but keeps no history, so there is no way to see whether
 * a change you made actually moved anything. Visiting your own profile once per
 * session and reading the play counts off the grid builds that history yourself.
 *
 * Read-only, on your own account. No engagement, no risk.
 */
public final class SelfStats {

    private static final String FILE = "selfstats.tsv";
    private static final long MIN_INTERVAL_MS = 6 * 60 * 60 * 1000L;   // 4x a day is plenty

    private final File file;

    public SelfStats(Context ctx) {
        file = new File(ctx.getFilesDir(), FILE);
    }

    /** One row per snapshot: timestamp, total, count, then each tile's views. */
    public void record(List<Long> counts) {
        if (counts == null || counts.isEmpty()) return;
        long total = 0;
        StringBuilder sb = new StringBuilder();
        sb.append(System.currentTimeMillis()).append('\t');
        for (Long c : counts) total += c;
        sb.append(total).append('\t').append(counts.size());
        for (Long c : counts) sb.append('\t').append(c);
        sb.append('\n');

        FileOutputStream out = null;
        try {
            out = new FileOutputStream(file, true);
            out.write(sb.toString().getBytes("UTF-8"));
        } catch (Throwable ignored) {
        } finally {
            if (out != null) try { out.close(); } catch (Throwable ignored) { }
        }
    }

    public boolean dueForSnapshot() {
        List<String[]> r = rows();
        if (r.isEmpty()) return true;
        try {
            long last = Long.parseLong(r.get(r.size() - 1)[0]);
            return System.currentTimeMillis() - last > MIN_INTERVAL_MS;
        } catch (Exception e) {
            return true;
        }
    }

    private List<String[]> rows() {
        List<String[]> out = new ArrayList<String[]>();
        BufferedReader r = null;
        try {
            if (!file.exists()) return out;
            r = new BufferedReader(new FileReader(file));
            String line;
            while ((line = r.readLine()) != null) {
                String[] p = line.split("\t", -1);
                if (p.length >= 3) out.add(p);
            }
        } catch (Throwable ignored) {
        } finally {
            if (r != null) try { r.close(); } catch (Throwable ignored) { }
        }
        return out;
    }

    private static final SimpleDateFormat DAY =
            new SimpleDateFormat("d MMM", Locale.US);

    /** Human summary: latest totals and the change since the first snapshot. */
    public String summary() {
        List<String[]> r = rows();
        if (r.isEmpty()) return "No snapshot yet.\nTaken automatically once per session.";

        String[] last = r.get(r.size() - 1);
        String[] first = r.get(0);
        long lastTotal = parse(last[1]), firstTotal = parse(first[1]);
        int videos = (int) parse(last[2]);

        StringBuilder sb = new StringBuilder();
        sb.append(videos).append(" videos, ")
          .append(ResearchLog.human(lastTotal)).append(" total views\n");

        if (r.size() > 1) {
            long delta = lastTotal - firstTotal;
            long days = Math.max(1,
                    (parse(last[0]) - parse(first[0])) / (24 * 60 * 60 * 1000L));
            sb.append(delta >= 0 ? "+" : "").append(ResearchLog.human(delta))
              .append(" views since ").append(DAY.format(new Date(parse(first[0]))))
              .append("  (~").append(delta / days).append("/day)\n");
        }
        sb.append(r.size()).append(" snapshots");

        // Per-video movement since the previous snapshot.
        if (r.size() > 1) {
            String[] prev = r.get(r.size() - 2);
            StringBuilder moves = new StringBuilder();
            int n = Math.min(last.length, prev.length);
            for (int i = 3; i < n && i < 13; i++) {
                long d = parse(last[i]) - parse(prev[i]);
                if (d > 0) {
                    if (moves.length() > 0) moves.append("  ");
                    moves.append("#").append(i - 2).append(" +").append(d);
                }
            }
            if (moves.length() > 0) sb.append("\nsince last: ").append(moves);
        }
        return sb.toString();
    }

    private static long parse(String s) {
        try { return Long.parseLong(s.trim()); } catch (Exception e) { return 0; }
    }

    public void clear() {
        try { file.delete(); } catch (Throwable ignored) { }
    }
}
