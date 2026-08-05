package com.warmup.tt;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Decides whether a video belongs to the account's niche.
 *
 * This is the centre of the app. Engagement that isn't gated on niche match trains
 * the interest graph toward whatever the For You page happens to serve - which, on an
 * untuned feed, is mostly not your niche. Liking those is worse than doing nothing:
 * it teaches TikTok the account is interested in something else.
 *
 * Edit the terms in the app and everything downstream retargets immediately: what
 * gets watched to the end, what gets liked, what gets searched, what gets logged.
 */
public final class Niche {

    private static final Set<String> STOP = new HashSet<String>(Arrays.asList(
            "the","and","for","with","my","of","in","on","a","an","to","at","is","it",
            "this","that","les","des","une","pour","avec","sur","dans","le","la","du"));

    private final List<String> keywords = new ArrayList<String>();

    public Niche(String raw) {
        if (raw == null) return;
        Set<String> seen = new HashSet<String>();
        StringBuilder tok = new StringBuilder();
        String lower = raw.toLowerCase();
        for (int i = 0; i <= lower.length(); i++) {
            char c = i < lower.length() ? lower.charAt(i) : ' ';
            if (Character.isLetterOrDigit(c)) {
                tok.append(c);
                continue;
            }
            if (tok.length() >= 3) {
                String t = tok.toString();
                if (!STOP.contains(t) && seen.add(t)) keywords.add(t);
            }
            tok.setLength(0);
        }
    }

    public boolean isEmpty() { return keywords.isEmpty(); }

    public int size() { return keywords.size(); }

    public List<String> keywords() { return keywords; }

    /**
     * How many distinct niche keywords appear across the supplied fields (caption,
     * hashtags, sound name, author handle).
     */
    public int score(String... fields) {
        if (keywords.isEmpty()) return 0;
        StringBuilder sb = new StringBuilder();
        for (String f : fields) {
            if (f != null) sb.append(f.toLowerCase()).append(' ');
        }
        String hay = sb.toString();
        int n = 0;
        for (String k : keywords) if (hay.contains(k)) n++;
        return n;
    }

    /** One keyword hit is enough - captions are short and hashtags are sparse. */
    public boolean matches(String... fields) { return score(fields) >= 1; }
}
