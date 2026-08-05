# Warmup (Android)

An Android port of [l-portet/tiktok-warmup-bot](https://github.com/l-portet/tiktok-warmup-bot),
rebuilt around a measured model of how people actually watch short-form video.

The original is a Node script that runs **on a Mac** and plays MP3s out of the laptop
speakers; an iPhone next to it picks them up through iOS Voice Control and performs the
gestures. That needs a computer. This runs entirely on the phone.

## Install

1. Copy `tiktok-warmup.apk` to the phone and open it. Allow installing from unknown
   sources — it's a self-signed build.
2. Open **Warmup**, tap the amber banner, and enable the service under
   Installed apps / Downloaded services.
3. **Turn on Dry run and watch one session before trusting it with anything.**
4. Set a duration and press START. TikTok is opened for you after a six-second
   grace period — no need to switch apps yourself.

Stop it by tapping the floating bubble, the notification's Stop action, or reopening
the app. It also stops itself if it can't find its way back to the feed.

## v2.1 - the crash loop

Reported symptom: it kept exiting TikTok. The Live log showed why:

```
23:37:45  session  start, ~39m
23:37:51  recover  on COMMENTS, pressing back
23:37:52  recover  on COMMENTS, pressing back
23:37:53  paused   TikTok not in foreground (launcher)
```

It was on the feed the entire time. Two classifier rules both fired on ordinary
feed frames:

- `anyText("comments")` matched the **rail's own comment button**, whose content
  description reads e.g. *"read or add comments, 418 comments"*
- `anyText("following")` matched the feed's **Following tab** in the top nav

So every feed frame was read as an open comment sheet or a profile, recovery pressed
BACK on the feed, and BACK on the feed exits TikTok.

Fixes:

- **The feed is now tested positively and first** - a rail of 3+ small clickable icons
  pinned right, with nothing editable on screen
- Comments require an actual **composer** field low on screen; profile requires
  *followers* (never *following*) **and** no rail; word matching is whole-word
- **BACK only fires on a screen with something genuinely stacked to dismiss.** An
  unrecognised screen is no longer backed out of - swiping on the wrong screen is
  recoverable, exiting the app is not
- If BACK ever does drop out of TikTok, that proves the screen was misread: the app
  says so, relaunches TikTok, and disables BACK for the rest of the session
- **TikTok is launched for you on START**, and relaunched if it disappears
- Session stops below 15% battery when unplugged

`tools/classify.js` checks the old and new logic against the frame from that log.

## What changed in v2

### It looks at the screen now

v1 tapped fixed screen fractions with no idea what was in front of it. Opening the
comment sheet left it blind: taps hit the composer, the keyboard came up, characters
got typed, and a single BACK only dismissed the keyboard — so it carried on "swiping"
inside a comment list it thought was a feed. A stray tap on the send button would have
posted that text to a stranger's video.

The service now reads the accessibility node tree every cycle and:

- **classifies the screen** — feed, comments, profile, search, not-TikTok
- **finds real buttons** instead of guessing pixels. Content descriptions first
  (localised, several languages), then the geometry of the right-hand rail as a
  fallback: a vertical stack of clickable icons pinned to the right edge, ordered
  avatar → like → comment → bookmark → share
- **verifies dismissals** rather than firing one BACK and hoping
- **pauses when TikTok isn't in front.** v1 would happily keep tapping into whatever
  app was foreground

The calibration screen is gone. Nothing to tune.

### Behaviour is modelled on real data, not invented

Upstream's interval table ("every 4–7 swipes") was guessed, and it isn't close. What
v1 actually did versus what people actually do:

| | v1 shipped | humans | v2 normal |
|---|---|---|---|
| like rate | 17.4% | 3.4–4% | 3.7% |
| save rate | 16.6% | <1% | 0.5% |
| comment opens | 15.6% | ~5–8% | 6.2% |
| watch time | flat 6–9s | 8.4s mean, right-skewed | 8.1s mean |
| full watches | never | ~10% | 9.3% |

Two structural changes get there:

**Watch time is a three-mode mixture** — ~38% instant skips (1.2–3.2s), a log-normal
bulk around 8.5s, and ~10% full watches that sometimes loop 2–3×. The median lands at
4.2s, which is low by design: it's what "most viewers watch ~30% before scrolling"
actually looks like. A flat 6–9s box is a histogram no person produces.

**Engagement is gated on dwell.** Upstream fires likes off a swipe counter, entirely
independent of watch time — so statistically it likes videos it skipped in two seconds
as often as ones it watched. Here every decision needs a minimum dwell first (5s for a
like, 12s for a save, 15s for a repost), then rolls a probability tuned so the emitted
rate matches the benchmark.

Attention also decays across a session — skip probability climbs and watch times
compress toward the end — and session length is jittered 0.75–1.25× so it never ends on
a round number.

Sources: [Sprout Social](https://sproutsocial.com/insights/tiktok-stats/) ·
[Rival IQ](https://www.rivaliq.com/blog/good-engagement-rate-tiktok/) ·
[Socialinsider](https://www.socialinsider.io/social-media-benchmarks/tiktok) ·
[Marketing LTB](https://marketingltb.com/blog/statistics/tiktok-videos-statistics/)

### New features

- **Dry run** — decides and logs everything, taps nothing
- **Niche search** — periodically searches one of your terms and browses results,
  pulling the For You page toward the niche. Editable, one term per line
- **Research log** — records authors, hashtags and sounds it scrolls past, and
  summarises the most frequent. The most genuinely useful thing here for growing an
  account
- **Floating stop button** — `TYPE_ACCESSIBILITY_OVERLAY`, so no extra permission
  prompt. Parked on the left edge, where the bot's own targets never reach
- **Notification with Stop action** as a fallback kill switch
- **Live action feed** in the app
- Light / Normal / Heavy presets scaling every engagement probability
- Dark themed interface, credits

Likes are always a centre double-tap, never the heart icon — double-tap only ever
likes, while the heart toggles and would un-like an already-liked video.

Repost is off by default. It pushes a video to your followers under your name, picked
by something that cannot see the video.

## The upstream bug

`generateThresholds()` re-rolls **every** action's threshold whenever **any** action
fires, and matches with strict `===`. Four actions sit at interval 4–7, so one always
fires first and resets the counters — nothing with a longer interval is reachable.
Simulated over 3000 trials:

```
upstream  (per 200 swipes)
  swipePrevious  17.72    openProfile  0.00   <-- never fires
  likePost       12.36    openShop     0.00   <-- never fires
  savePost        8.86    openInbox    0.00   <-- never fires
  openComments    6.35
```

Three of eight actions are dead code in the original. v2's scheduler replaces the
threshold system entirely, so the bug is gone by construction.

## What this does not do

No attempt to evade TikTok's automation detection. The behaviour model exists to make
the bot *correct* — to stop it liking videos it skipped, typing into comment boxes, and
tapping other apps. Better modelling doesn't touch device attestation, network
signals, or account-level heuristics.

It also **won't grow an audience**. Your own scrolling doesn't affect who sees your
posts. Warmup sets your account's interest graph, which matters most in an account's
first days — it isn't a distribution lever. Use the research log; that's the part that
helps.

Automated activity is against TikTok's Terms of Service. Upstream's README says
*"100% safety is not guaranteed. Use at your own risk."* Same here.

## Building

JDK plus Android SDK (build-tools 35, platform 35). Framework-only — no Gradle, no
AndroidX.

```sh
ANDROID_HOME=/path/to/android-sdk ./build.sh
```

## Credits

**Maxime35** — [website](https://louming.dastot.net) ·
[LinkedIn](https://www.linkedin.com/in/lou-ming-dastot/) ·
[GitHub](https://github.com/Maxime35510)

Origin note: v1 of this repo was a direct port of l-portet/tiktok-warmup-bot. v2
replaced the scheduler, gesture layer, screen handling and UI, so no upstream code
remains and the ISC notice no longer applies. The comparison sections above are kept
because they document why the current design is what it is.
