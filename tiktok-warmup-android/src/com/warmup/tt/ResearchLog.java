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
 * What actually came across the feed: authors, hashtags, sounds.
 *
 * This is the part of the app with genuine value for growing an account - it turns a
 * warmup session into a survey of what is circulating in the niche.
 */
public final class ResearchLog {

    private static final String FILE = "research.tsv";
    private static final int MAX_LINES = 4000;

    private final File file;

    public ResearchLog(Context ctx) {
        file = new File(ctx.getFilesDir(), FILE);
    }

    public void record(String author, String caption, String sound) {
        if (author.length() == 0 && caption.length() == 0 && sound.length() == 0) return;
        String line = System.currentTimeMillis() + "\t"
                + clean(author) + "\t" + clean(caption) + "\t" + clean(sound) + "\n";
        FileOutputStream out = null;
        try {
            out = new FileOutputStream(file, true);
            out.write(line.getBytes("UTF-8"));
        } catch (Throwable ignored) {
        } finally {
            if (out != null) try { out.close(); } catch (Throwable ignored) { }
        }
    }

    private static String clean(String s) {
        return s == null ? "" : s.replace('\t', ' ').replace('\n', ' ').trim();
    }

    public int size() {
        return readLines().size();
    }

    public void clear() {
        try { file.delete(); } catch (Throwable ignored) { }
    }

    private List<String[]> readLines() {
        List<String[]> rows = new ArrayList<String[]>();
        if (!file.exists()) return rows;
        BufferedReader r = null;
        try {
            r = new BufferedReader(new FileReader(file));
            String line;
            while ((line = r.readLine()) != null && rows.size() < MAX_LINES) {
                String[] p = line.split("\t", -1);
                if (p.length >= 4) rows.add(p);
            }
        } catch (Throwable ignored) {
        } finally {
            if (r != null) try { r.close(); } catch (Throwable ignored) { }
        }
        return rows;
    }

    /** Most frequent hashtags across everything seen. */
    public List<String> topHashtags(int n) {
        Map<String, Integer> freq = new HashMap<String, Integer>();
        for (String[] row : readLines()) {
            for (String tag : extractTags(row[2])) {
                Integer p = freq.get(tag);
                freq.put(tag, (p == null ? 0 : p) + 1);
            }
        }
        return top(freq, n);
    }

    public List<String> topSounds(int n) {
        Map<String, Integer> freq = new HashMap<String, Integer>();
        for (String[] row : readLines()) {
            String s = row[3];
            if (s.length() == 0) continue;
            Integer p = freq.get(s);
            freq.put(s, (p == null ? 0 : p) + 1);
        }
        return top(freq, n);
    }

    public List<String> topAuthors(int n) {
        Map<String, Integer> freq = new HashMap<String, Integer>();
        for (String[] row : readLines()) {
            String s = row[1];
            if (s.length() == 0) continue;
            Integer p = freq.get(s);
            freq.put(s, (p == null ? 0 : p) + 1);
        }
        return top(freq, n);
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
                if (j > i + 1) out.add(caption.substring(i, j).toLowerCase());
                i = j;
            } else i++;
        }
        return out;
    }

    private static List<String> top(Map<String, Integer> freq, int n) {
        List<Map.Entry<String, Integer>> es =
                new ArrayList<Map.Entry<String, Integer>>(freq.entrySet());
        Collections.sort(es, new Comparator<Map.Entry<String, Integer>>() {
            @Override public int compare(Map.Entry<String, Integer> a,
                                         Map.Entry<String, Integer> b) {
                return b.getValue() - a.getValue();
            }
        });
        List<String> out = new ArrayList<String>();
        for (int i = 0; i < es.size() && i < n; i++) {
            out.add(es.get(i).getKey() + "  x" + es.get(i).getValue());
        }
        return out;
    }
}
