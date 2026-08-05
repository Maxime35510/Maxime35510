package com.warmup.tt;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

/** Ongoing notification with a Stop action - the fallback kill switch. */
public final class Notifications {

    public static final String CHANNEL = "warmup_session";
    public static final int ID = 1001;
    public static final String ACTION_STOP = "com.warmup.tt.STOP";

    public static void ensureChannel(Context ctx) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return;
        NotificationManager nm =
                (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm == null) return;
        NotificationChannel ch = new NotificationChannel(
                CHANNEL, "Warmup session", NotificationManager.IMPORTANCE_LOW);
        ch.setDescription("Shows while a session is running");
        ch.setShowBadge(false);
        nm.createNotificationChannel(ch);
    }

    public static void show(Context ctx, String title, String text) {
        ensureChannel(ctx);
        NotificationManager nm =
                (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm == null) return;

        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags |= PendingIntent.FLAG_IMMUTABLE;
        }
        PendingIntent stop = PendingIntent.getBroadcast(
                ctx, 0, new Intent(ctx, StopReceiver.class).setAction(ACTION_STOP), flags);
        PendingIntent open = PendingIntent.getActivity(
                ctx, 1, new Intent(ctx, MainActivity.class), flags);

        Notification.Builder b;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            b = new Notification.Builder(ctx, CHANNEL);
        } else {
            b = new Notification.Builder(ctx);
        }
        b.setSmallIcon(android.R.drawable.ic_media_play)
         .setContentTitle(title)
         .setContentText(text)
         .setOngoing(true)
         .setOnlyAlertOnce(true)
         .setContentIntent(open)
         .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", stop);

        try { nm.notify(ID, b.build()); } catch (Throwable ignored) { }
    }

    public static void clear(Context ctx) {
        NotificationManager nm =
                (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm != null) try { nm.cancel(ID); } catch (Throwable ignored) { }
    }

    private Notifications() { }
}
