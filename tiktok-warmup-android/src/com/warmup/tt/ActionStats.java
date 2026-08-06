package com.warmup.tt;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Did each action actually fire, or was its button never found?
 *
 * Every action here depends on locating a control in TikTok's accessibility tree, and
 * that can silently fail - the bot carries on, the log says "skipped", and from the
 * outside it looks like the feature works. This counts both outcomes per action so the
 * app can answer "does repost/save/follow really work on my device" with evidence
 * instead of a claim.
 */
public final class ActionStats {

    /** {done, notFound} */
    private static final Map<String, int[]> stats = new LinkedHashMap<String, int[]>();

    private static int[] slot(String action) {
        int[] v = stats.get(action);
        if (v == null) { v = new int[2]; stats.put(action, v); }
        return v;
    }

    public static synchronized void done(String action)     { slot(action)[0]++; }
    public static synchronized void notFound(String action) { slot(action)[1]++; }

    public static synchronized void reset() { stats.clear(); }

    public static synchronized Map<String, int[]> snapshot() {
        return new LinkedHashMap<String, int[]>(stats);
    }

    /** Human-readable, ordered so the unreliable ones stand out. */
    public static synchronized String report() {
        if (stats.isEmpty()) return "No actions attempted yet.";
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<String, int[]> e : stats.entrySet()) {
            int done = e.getValue()[0], missing = e.getValue()[1];
            int total = done + missing;
            if (total == 0) continue;
            sb.append(e.getKey()).append("  ").append(done).append(" done");
            if (missing > 0) {
                sb.append(", ").append(missing).append(" not found");
                sb.append(done == 0 ? "   <- never worked" : "");
            }
            sb.append('\n');
        }
        return sb.length() == 0 ? "No actions attempted yet." : sb.toString().trim();
    }

    /** True when an action has been tried a few times and never once succeeded. */
    public static synchronized boolean broken(String action) {
        int[] v = stats.get(action);
        return v != null && v[0] == 0 && v[1] >= 3;
    }

    private ActionStats() { }
}
