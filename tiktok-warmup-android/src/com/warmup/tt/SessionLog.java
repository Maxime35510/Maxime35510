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
 * One row per finished session: when, how long, how many videos, and the For You
 * niche score it ended on.
 *
 * The single number that matters is whether that score is climbing across sessions.
 * A live percentage tells you nothing on its own - the trend is the evidence that the
 * feed is actually retraining.
 */
public final class SessionLog {

    private static final String FILE = "sessions.tsv";

    public static final class Row {
        public long time;
        public int minutes, videos, score, likes, follows;
    }

    private final File file;

    public SessionLog(Context ctx) {
        file = new File(ctx.getFilesDir(), FILE);
    }

    public void record(int minutes, int videos, int score, int likes, int follows) {
        if (videos <= 0) return;
        String line = System.currentTimeMillis() + "\t" + minutes + "\t" + videos
                + "\t" + score + "\t" + likes + "\t" + follows + "\n";
        FileOutputStream out = null;
        try {
            out = new FileOutputStream(file, true);
            out.write(line.getBytes("UTF-8"));
        } catch (Throwable ignored) {
        } finally {
            if (out != null) try { out.close(); } catch (Throwable ignored) { }
        }
    }

    public List<Row> rows() {
        List<Row> out = new ArrayList<Row>();
        BufferedReader r = null;
        try {
            if (!file.exists()) return out;
            r = new BufferedReader(new FileReader(file));
            String line;
            while ((line = r.readLine()) != null) {
                String[] p = line.split("\t", -1);
                if (p.length < 6) continue;
                Row row = new Row();
                row.time    = lng(p[0]);
                row.minutes = (int) lng(p[1]);
                row.videos  = (int) lng(p[2]);
                row.score   = (int) lng(p[3]);
                row.likes   = (int) lng(p[4]);
                row.follows = (int) lng(p[5]);
                out.add(row);
            }
        } catch (Throwable ignored) {
        } finally {
            if (r != null) try { r.close(); } catch (Throwable ignored) { }
        }
        return out;
    }

    private static long lng(String s) {
        try { return Long.parseLong(s.trim()); } catch (Exception e) { return 0; }
    }

    /** Score of the most recent finished session, or -1 if there isn't one. */
    public int lastScore() {
        List<Row> r = rows();
        return r.isEmpty() ? -1 : r.get(r.size() - 1).score;
    }

    private static final SimpleDateFormat WHEN =
            new SimpleDateFormat("d MMM HH:mm", Locale.US);

    public String summary(int limit) {
        List<Row> r = rows();
        if (r.isEmpty()) return "No finished sessions yet.";

        StringBuilder sb = new StringBuilder();
        StringBuilder trend = new StringBuilder();
        int from = Math.max(0, r.size() - limit);
        for (int i = from; i < r.size(); i++) {
            Row row = r.get(i);
            sb.append(WHEN.format(new Date(row.time)))
              .append("   ").append(row.score).append("% niche")
              .append("   ").append(row.videos).append(" videos")
              .append("   ").append(row.minutes).append("m\n");
        }
        int show = Math.min(6, r.size());
        for (int i = r.size() - show; i < r.size(); i++) {
            if (trend.length() > 0) trend.append(" → ");
            trend.append(r.get(i).score).append('%');
        }
        sb.append("\ntrend: ").append(trend);

        if (r.size() >= 2) {
            int delta = r.get(r.size() - 1).score - r.get(0).score;
            sb.append(delta >= 0 ? "\nup " : "\ndown ").append(Math.abs(delta))
              .append(" points since the first session");
        }
        return sb.toString();
    }

    public void clear() {
        try { file.delete(); } catch (Throwable ignored) { }
    }
}
