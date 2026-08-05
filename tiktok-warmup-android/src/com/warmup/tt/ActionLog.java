package com.warmup.tt;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/** Rolling record of what the bot decided, shown live in the app. */
public final class ActionLog {

    public static final class Entry {
        public final long time;
        public final String action;
        public final String detail;
        public final boolean skipped;

        Entry(long t, String a, String d, boolean s) {
            time = t; action = a; detail = d; skipped = s;
        }
    }

    private static final int CAP = 300;
    private static final List<Entry> buf = new ArrayList<Entry>();
    private static final Map<String, Integer> counts = new LinkedHashMap<String, Integer>();

    public static synchronized void add(String action, String detail, boolean skipped) {
        buf.add(new Entry(System.currentTimeMillis(), action, detail, skipped));
        while (buf.size() > CAP) buf.remove(0);
        if (!skipped) {
            Integer p = counts.get(action);
            counts.put(action, (p == null ? 0 : p) + 1);
        }
    }

    public static synchronized List<Entry> recent(int n) {
        int from = buf.size() - n;
        if (from < 0) from = 0;
        return new ArrayList<Entry>(buf.subList(from, buf.size()));
    }

    public static synchronized Map<String, Integer> counts() {
        return new LinkedHashMap<String, Integer>(counts);
    }

    public static synchronized void reset() {
        buf.clear();
        counts.clear();
    }

    public static synchronized String summary() {
        if (counts.isEmpty()) return "no actions yet";
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<String, Integer> e : counts.entrySet()) {
            if (sb.length() > 0) sb.append("   ");
            sb.append(e.getKey()).append(' ').append(e.getValue());
        }
        return sb.toString();
    }

    private static final SimpleDateFormat FMT =
            new SimpleDateFormat("HH:mm:ss", Locale.US);

    public static String clock(long t) { return FMT.format(new Date(t)); }

    private ActionLog() { }
}
