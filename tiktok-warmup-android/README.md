# Warmup (Android)

An Android port of [l-portet/tiktok-warmup-bot](https://github.com/l-portet/tiktok-warmup-bot).

The original is a Node script that runs **on a Mac** and plays MP3 files out of the
laptop speakers; an iPhone sitting next to it picks them up through iOS Voice Control
and performs the gestures. That design needs a computer. This port doesn't — it runs
entirely on the phone, dispatching the same gestures through Android's
`AccessibilityService.dispatchGesture()`.

The action table, intervals and pause formula are taken verbatim from upstream's
`index.js`.

## Install

1. Copy `tiktok-warmup.apk` to the phone.
2. Open it. Android will ask you to allow installing from unknown sources — this is a
   self-signed debug build, so that prompt is expected.
3. Open the **Warmup** app.
4. Tap **Open accessibility settings**, find *Warmup* under Installed apps /
   Downloaded services, and enable it. Nothing works until this is on.
5. Back in the app: set a duration, press **Start**, and switch to TikTok. There's a
   5-second grace period before the first gesture.

**Stop it** by reopening Warmup and pressing Stop, or by turning the accessibility
service off. Turning the screen off also halts it.

## Action table

Straight from upstream `VOICE_ACTIONS`:

| Action | Duration | Interval (swipes) | Gesture |
|---|---|---|---|
| `swipeNext` | 5000 ms | every swipe | swipe up |
| `swipePrevious` | 5000 ms | 4–7 | swipe down |
| `likePost` | 1500 ms | 4–7 | double-tap centre |
| `savePost` | 5000 ms | 4–7 | tap bookmark |
| `openComments` | 7000 ms | 4–7 | tap comments, then back |
| `openProfile` | 7000 ms | 10–15 | tap avatar, then back |
| `openShop` | 15000 ms | 30–35 | tap shop, then back |
| `openInbox` | 15000 ms | 30–35 | tap inbox, then back |

After each action the bot waits `duration + random(1000, 4000)` ms, as upstream does.
That works out to roughly 200 swipes in a 30-minute session.

## The upstream bug

`generateThresholds()` re-rolls **every** action's threshold whenever **any** action
fires, and thresholds are matched with strict `===`. Four actions sit at interval 4–7,
so one of them always fires first and resets the counters. Nothing with a longer
interval is ever reachable:

```
upstream  (per 200 swipes, mean of 3000 trials)
  swipePrevious    17.72
  likePost         12.36
  savePost          8.86
  openComments      6.35
  openProfile       0.00   <-- never fires
  openShop          0.00   <-- never fires
  openInbox         0.00   <-- never fires
```

Three of the eight actions are dead code in the original. This port re-rolls only the
action that fired and matches with `>=`, which is what the interval table clearly
intends:

```
fixed
  swipePrevious    35.93
  likePost         34.84
  savePost         33.27
  openComments     31.20
  openProfile      13.75
  openShop          5.11
  openInbox         5.04
```

The **Faithful mode** checkbox restores upstream's behaviour exactly, dead actions
included. It's off by default.

## Calibration

Tap targets are stored as fractions of screen width/height so they survive a change of
device, but the defaults are only estimates of TikTok's layout. If saves or comments
land on the wrong thing, adjust the fractions in section 3 of the app and restart the
session. `likePost` uses a centre double-tap, so it needs no calibration.

## Building

Needs a JDK and the Android SDK (build-tools 35, platform 35). No Gradle, no AndroidX —
the app is framework-only, so the raw toolchain is enough.

```sh
ANDROID_HOME=/path/to/android-sdk ./build.sh
```

Produces a signed `tiktok-warmup.apk`. The signing key is generated on first run into
`keystore.jks` (password `android`) and is gitignored.

## What this does not do

There's no attempt to evade TikTok's automation detection, and randomised gesture
paths shouldn't be mistaken for it. TikTok's detection is overwhelmingly server-side —
device attestation, network and session signals, and behavioural models over the whole
interaction history. What flags a warmup bot is the macro pattern: sustained sessions
with no app-switching, no pauses, and watch-time distributions no human produces. None
of that is addressable from inside the gesture layer.

Automated activity is against TikTok's Terms of Service. Upstream's own README says
*"100% safety is not guaranteed. Use at your own risk."* That applies here too — don't
run it on an account you'd mind losing.
