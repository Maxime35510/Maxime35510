package com.warmup.tt;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/** Receives the notification's Stop action. */
public class StopReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context ctx, Intent intent) {
        WarmupService svc = WarmupService.instance;
        if (svc != null) svc.stopSession("notification");
        Notifications.clear(ctx);
    }
}
