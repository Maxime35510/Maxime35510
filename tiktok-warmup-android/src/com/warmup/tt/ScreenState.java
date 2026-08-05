package com.warmup.tt;

import android.accessibilityservice.AccessibilityService;
import android.graphics.Rect;
import android.view.accessibility.AccessibilityNodeInfo;
import android.view.accessibility.AccessibilityWindowInfo;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

/**
 * A snapshot of what is actually on screen.
 *
 * The previous build tapped fixed screen fractions with no idea what was in front of
 * it. Opening the comment sheet left it blind: taps landed on the composer, the
 * keyboard came up, characters got typed, and a single BACK only dismissed the
 * keyboard - so it carried on "swiping" inside a comment list it didn't know was open.
 *
 * Everything here is captured into plain data and the nodes released immediately, so
 * no AccessibilityNodeInfo is held across the async gesture callbacks.
 */
public final class ScreenState {

    public static final String[] TIKTOK_PACKAGES = {
        "com.zhiliaoapp.musically",   // global
        "com.ss.android.ugc.trill",   // lite / regional
        "com.ss.android.ugc.aweme",   // douyin
    };

    public enum Screen { FEED, COMMENTS, PROFILE, SEARCH, OTHER_TIKTOK, NOT_TIKTOK }

    /** One on-screen element, flattened. */
    public static final class Item {
        public final Rect bounds;
        public final String desc;
        public final String text;
        public final String cls;
        public final boolean clickable;
        public final boolean editable;

        Item(Rect b, String d, String t, String c, boolean click, boolean edit) {
            bounds = b; desc = d; text = t; cls = c; clickable = click; editable = edit;
        }
        public int cx() { return bounds.centerX(); }
        public int cy() { return bounds.centerY(); }
    }

    public final String pkg;
    public final List<Item> items;
    public final boolean keyboardOpen;
    public final int width, height;
    public final Screen screen;

    private ScreenState(String pkg, List<Item> items, boolean kb, int w, int h) {
        this.pkg = pkg; this.items = items; this.keyboardOpen = kb;
        this.width = w; this.height = h;
        this.screen = classify();
    }

    // ------------------------------------------------------------- capture

    public static ScreenState capture(AccessibilityService svc, int w, int h) {
        List<Item> out = new ArrayList<Item>();
        String pkg = "";
        AccessibilityNodeInfo root = null;
        try {
            root = svc.getRootInActiveWindow();
            if (root != null) {
                CharSequence p = root.getPackageName();
                if (p != null) pkg = p.toString();
                collect(root, out, 0);
            }
        } catch (Throwable ignored) {
        } finally {
            if (root != null) { try { root.recycle(); } catch (Throwable ignored) { } }
        }
        return new ScreenState(pkg, out, keyboardVisible(svc), w, h);
    }

    private static void collect(AccessibilityNodeInfo node, List<Item> out, int depth) {
        if (node == null || depth > 40 || out.size() > 900) return;
        try {
            Rect b = new Rect();
            node.getBoundsInScreen(b);
            if (b.width() > 0 && b.height() > 0) {
                out.add(new Item(
                        b,
                        low(node.getContentDescription()),
                        low(node.getText()),
                        low(node.getClassName()),
                        node.isClickable(),
                        node.isEditable()));
            }
            for (int i = 0; i < node.getChildCount(); i++) {
                AccessibilityNodeInfo child = node.getChild(i);
                if (child == null) continue;
                collect(child, out, depth + 1);
                try { child.recycle(); } catch (Throwable ignored) { }
            }
        } catch (Throwable ignored) { }
    }

    private static boolean keyboardVisible(AccessibilityService svc) {
        try {
            List<AccessibilityWindowInfo> ws = svc.getWindows();
            if (ws == null) return false;
            for (AccessibilityWindowInfo w : ws) {
                if (w != null && w.getType() == AccessibilityWindowInfo.TYPE_INPUT_METHOD) {
                    return true;
                }
            }
        } catch (Throwable ignored) { }
        return false;
    }

    private static String low(CharSequence cs) {
        return cs == null ? "" : cs.toString().toLowerCase();
    }

    // ------------------------------------------------------------ classify

    public boolean isTikTok() {
        for (String p : TIKTOK_PACKAGES) if (p.equals(pkg)) return true;
        return false;
    }

    /**
     * Order matters, and the feed is tested positively and first.
     *
     * The previous classifier asked "does any text contain 'comments'?" - which the
     * rail's own comment button answers yes to on every single feed frame - and "does
     * any text contain 'following'?", which the feed's top nav tab also answers yes to.
     * So the feed was permanently misread as a comment sheet or a profile, and the
     * recovery path pressed BACK on the feed until TikTok exited to the launcher.
     *
     * Text is only trusted now when a structural signal agrees with it.
     */
    private Screen classify() {
        if (!isTikTok()) return Screen.NOT_TIKTOK;

        boolean editableLow = false, editableHigh = false, hasEditable = false;
        for (Item it : items) {
            if (!it.editable) continue;
            hasEditable = true;
            if (it.cy() > height * 0.60) editableLow = true;
            if (it.cy() < height * 0.22) editableHigh = true;
        }

        boolean hasRail = rail().size() >= 3;

        // The rail is the feed's signature: a stack of small clickable icons pinned
        // right, with nothing to type into.
        if (hasRail && !hasEditable) return Screen.FEED;

        // A comment sheet always carries a composer near the bottom.
        if (editableLow) return Screen.COMMENTS;
        if (editableHigh) return Screen.SEARCH;
        if (hasEditable && keyboardOpen) return Screen.COMMENTS;

        // A profile has follower counts and no rail.
        if (!hasRail && hasWord(Words.FOLLOWERS)) return Screen.PROFILE;

        // Unknown. Deliberately NOT treated as something to back out of - swiping on
        // the wrong screen is recoverable, exiting the app is not.
        return Screen.OTHER_TIKTOK;
    }

    /** True only when the word appears as its own label, not inside a longer one. */
    private boolean hasWord(String[] needles) {
        for (Item it : items) {
            for (String n : needles) {
                if (it.text.equals(n) || it.text.startsWith(n + " ")
                        || it.text.endsWith(" " + n)) return true;
            }
        }
        return false;
    }

    /** BACK is only safe where there is genuinely something stacked to dismiss. */
    public boolean isDismissable() {
        return screen == Screen.COMMENTS
                || screen == Screen.PROFILE
                || screen == Screen.SEARCH;
    }

    // ---------------------------------------------------------- rail lookup

    /**
     * The right-hand action rail, top to bottom: avatar, like, comment, bookmark,
     * share. Geometry beats content descriptions here - descriptions are localised
     * and TikTok renames them between releases, but the rail is always a vertical
     * stack of clickable icons pinned to the right edge.
     */
    public List<Item> rail() {
        List<Item> r = new ArrayList<Item>();
        for (Item it : items) {
            if (!it.clickable) continue;
            if (it.cx() < width * 0.78) continue;
            if (it.cy() < height * 0.12 || it.cy() > height * 0.88) continue;
            if (it.bounds.width() > width * 0.35) continue;   // not a full-width row
            r.add(it);
        }
        Collections.sort(r, new Comparator<Item>() {
            @Override public int compare(Item a, Item b) { return a.cy() - b.cy(); }
        });
        // Drop near-duplicates (a button and its wrapper both report clickable).
        List<Item> dedup = new ArrayList<Item>();
        for (Item it : r) {
            boolean dup = false;
            for (Item k : dedup) if (Math.abs(k.cy() - it.cy()) < height * 0.025) dup = true;
            if (!dup) dedup.add(it);
        }
        return dedup;
    }

    /** Match by content description first, fall back to the rail's ordinal position. */
    public Item findAction(String[] needles, int railIndex) {
        for (Item it : items) {
            if (!it.clickable && it.desc.length() == 0) continue;
            for (String n : needles) {
                if (it.desc.contains(n)) return it;
            }
        }
        List<Item> r = rail();
        if (railIndex >= 0 && railIndex < r.size()) return r.get(railIndex);
        return null;
    }

    public Item like()     { return findAction(Words.LIKE,     1); }
    public Item comment()  { return findAction(Words.COMMENT,  2); }
    public Item bookmark() { return findAction(Words.BOOKMARK, 3); }
    public Item share()    { return findAction(Words.SHARE,    4); }
    public Item avatar()   { return findAction(Words.PROFILE,  0); }

    public Item search() {
        for (Item it : items) {
            if (it.cy() > height * 0.20) continue;
            for (String n : Words.SEARCH) if (it.desc.contains(n) || it.text.contains(n)) return it;
        }
        return null;
    }

    public Item editable() {
        for (Item it : items) if (it.editable) return it;
        return null;
    }

    /** Roughly how many comments the sheet is showing, for dwell scaling. */
    public int commentCount() {
        for (Item it : items) {
            String s = it.text.length() > 0 ? it.text : it.desc;
            if (s.contains("comment") || s.contains("commentaire")) {
                int n = firstInt(s);
                if (n > 0) return n;
            }
        }
        return 0;
    }

    private static int firstInt(String s) {
        int i = 0, n = s.length();
        while (i < n && !Character.isDigit(s.charAt(i))) i++;
        int v = 0, seen = 0;
        while (i < n && Character.isDigit(s.charAt(i)) && seen < 6) {
            v = v * 10 + (s.charAt(i) - '0'); i++; seen++;
        }
        return seen == 0 ? 0 : v;
    }

    // ------------------------------------------------------- research data

    /** Author handle, caption/hashtags and sound name, when they can be read. */
    public String[] researchRow() {
        String author = "", caption = "", sound = "";
        for (Item it : items) {
            String s = it.text;
            if (s.length() == 0) continue;
            if (author.length() == 0 && s.startsWith("@")) author = s;
            if (caption.length() == 0 && s.contains("#")) caption = s;
            if (sound.length() == 0
                    && (it.desc.contains("sound") || it.desc.contains("music")
                        || it.desc.contains("son") || it.desc.contains("musique"))) {
                sound = s;
            }
        }
        return new String[]{ author, caption, sound };
    }

    /** Localised needles. TikTok's descriptions follow the device language. */
    static final class Words {
        static final String[] LIKE      = {"like", "j'aime", "jaime", "aimer", "me gusta"};
        static final String[] COMMENT   = {"comment", "commentaire", "comentario"};
        static final String[] BOOKMARK  = {"favorite", "bookmark", "save", "favoris",
                                           "enregistrer", "guardar"};
        static final String[] SHARE     = {"share", "partager", "compartir", "repost"};
        static final String[] PROFILE   = {"profile", "avatar", "profil"};
        static final String[] SEARCH    = {"search", "rechercher", "recherche", "buscar"};
        /**
         * Followers only - never "following". TikTok's feed has a Following tab in the
         * top nav, so matching it turned every feed frame into a false profile.
         */
        static final String[] FOLLOWERS = {"followers", "abonnés", "seguidores"};
    }
}
