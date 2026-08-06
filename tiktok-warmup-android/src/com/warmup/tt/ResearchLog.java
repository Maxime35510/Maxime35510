package com.warmup.tt;

import android.content.Context;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * What came across the feed, and how well it did.
 *
 * Recording what you saw is a tally; recording what performed is a content decision.
 * Like counts are read off the rail, so hashtags and sounds can be ranked by the
 * engagement of the videos carrying them rather than by raw frequency - "these two
 * sounds appear on the highest-performing videos in your niche" beats "this hashtag
 * appeared a lot".
 *
 * Aggregates are cached in memory and only recomputed after a write. The previous
 * version re-read and re-parsed the whole file four times a second from the UI poll,
 * which is why the app got slower the longer a session ran.
 */
public final class ResearchLog {

    private static final String FILE = "research.tsv";
    private static final int MAX_LINES = 6000;

    // Cached across instances - the UI creates a new one on every refresh.
    private static List<String[]> cache;
    private static long cacheStamp = -1;

    private final File file;

    public ResearchLog(Context ctx) {
        file = new File(ctx.getFilesDir(), FILE);
    }

    /** time, author, caption, sound, likes, matched */
    public void record(String author, String caption, String sound,
                       long likes, boolean matched) {
        if (author.length() == 0 && caption.length() == 0 && sound.length() == 0) return;
        String line = System.currentTimeMillis() + "\t"
                + clean(author) + "\t" + clean(caption) + "\t" + clean(sound) + "\t"
                + likes + "\t" + (matched ? "1" : "0") + "\n";
        FileOutputStream out = null;
        try {
            out = new FileOutputStream(file, true);
            out.write(line.getBytes("UTF-8"));
            invalidate();
        } catch (Throwable ignored) {
        } finally {
            if (out != null) try { out.close(); } catch (Throwable ignored) { }
        }
    }

    private static synchronized void invalidate() { cache = null; cacheStamp = -1; }

    private static String clean(String s) {
        return s == null ? "" : s.replace('\t', ' ').replace('\n', ' ').trim();
    }

    public void clear() {
        try { file.delete(); } catch (Throwable ignored) { }
        invalidate();
    }

    private synchronized List<String[]> rows() {
        long stamp = file.exists() ? file.lastModified() + file.length() : 0;
        if (cache != null && cacheStamp == stamp) return cache;

        List<String[]> out = new ArrayList<String[]>();
        BufferedReader r = null;
        try {
            if (file.exists()) {
                r = new BufferedReader(new FileReader(file));
                String line;
                while ((line = r.readLine()) != null && out.size() < MAX_LINES) {
                    String[] p = line.split("\t", -1);
                    if (p.length >= 4) out.add(p);
                }
            }
        } catch (Throwable ignored) {
        } finally {
            if (r != null) try { r.close(); } catch (Throwable ignored) { }
        }
        cache = out;
        cacheStamp = stamp;
        return out;
    }

    public int size() { return rows().size(); }

    public int matchedCount() {
        int n = 0;
        for (String[] r : rows()) if (r.length >= 6 && "1".equals(r[5])) n++;
        return n;
    }

    /** Share of the feed that is actually your niche - the number to watch. */
    public int matchedPercent() {
        int total = size();
        return total == 0 ? 0 : (int) Math.round(matchedCount() * 100.0 / total);
    }

    private static long likesOf(String[] r) {
        if (r.length < 5) return 0;
        try { return Long.parseLong(r[4]); } catch (Exception e) { return 0; }
    }

    /** Hashtags ranked by the median likes of the videos carrying them. */
    public List<String> topHashtags(int n) {
        Map<String, List<Long>> byTag = new HashMap<String, List<Long>>();
        for (String[] r : rows()) {
            if (r.length >= 6 && !"1".equals(r[5])) continue;   // niche only
            long likes = likesOf(r);
            for (String tag : extractTags(r[2])) {
                List<Long> l = byTag.get(tag);
                if (l == null) { l = new ArrayList<Long>(); byTag.put(tag, l); }
                l.add(likes);
            }
        }
        return rank(byTag, n, "likes");
    }

    public List<String> topSounds(int n) {
        Map<String, List<Long>> bySound = new HashMap<String, List<Long>>();
        for (String[] r : rows()) {
            if (r.length >= 6 && !"1".equals(r[5])) continue;
            String s = r[3];
            if (s.length() == 0) continue;
            List<Long> l = bySound.get(s);
            if (l == null) { l = new ArrayList<Long>(); bySound.put(s, l); }
            l.add(likesOf(r));
        }
        return rank(bySound, n, "likes");
    }

    public List<String> topAuthors(int n) {
        Map<String, List<Long>> byAuthor = new HashMap<String, List<Long>>();
        for (String[] r : rows()) {
            if (r.length >= 6 && !"1".equals(r[5])) continue;
            String s = r[1];
            if (s.length() == 0) continue;
            List<Long> l = byAuthor.get(s);
            if (l == null) { l = new ArrayList<Long>(); byAuthor.put(s, l); }
            l.add(likesOf(r));
        }
        return rank(byAuthor, n, "likes");
    }

    /**
     * Sorted by median likes, with frequency as the tie-break. Median rather than mean
     * so one runaway video doesn't crown a tag that otherwise does nothing.
     */
    private static List<String> rank(Map<String, List<Long>> data, int n, String unit) {
        List<Map.Entry<String, List<Long>>> es =
                new ArrayList<Map.Entry<String, List<Long>>>(data.entrySet());
        Collections.sort(es, new Comparator<Map.Entry<String, List<Long>>>() {
            @Override public int compare(Map.Entry<String, List<Long>> a,
                                         Map.Entry<String, List<Long>> b) {
                long ma = median(a.getValue()), mb = median(b.getValue());
                if (ma != mb) return mb > ma ? 1 : -1;
                return b.getValue().size() - a.getValue().size();
            }
        });
        List<String> out = new ArrayList<String>();
        for (int i = 0; i < es.size() && i < n; i++) {
            Map.Entry<String, List<Long>> e = es.get(i);
            long m = median(e.getValue());
            out.add(e.getKey() + "   " + human(m) + " " + unit
                    + "  (x" + e.getValue().size() + ")");
        }
        return out;
    }

    private static long median(List<Long> v) {
        if (v.isEmpty()) return 0;
        List<Long> c = new ArrayList<Long>(v);
        Collections.sort(c);
        return c.get(c.size() / 2);
    }

    static String human(long v) {
        if (v >= 1000000) return String.format("%.1fM", v / 1000000.0);
        if (v >= 1000) return String.format("%.1fk", v / 1000.0);
        return String.valueOf(v);
    }

    private static List<String> extractTags(String caption) {
        List<String> out = new ArrayList<String>();
        int i = 0;
        while (i < caption.length()) {
            if (caption.charAt(i) == '#') {
                int j = i + 1;
                while (j < caption.length()
                        && (Character.isLetterOrDigit(caption.charAt(j))
                            || caption.charAt(j) == '_')) j++;
                // "#a" is noise - require a real word
                if (j - i >= 4) out.add(caption.substring(i, j).toLowerCase());
                i = j;
            } else i++;
        }
        return out;
    }
}
