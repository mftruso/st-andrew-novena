package com.miketruso.standrewnovena.receiver;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.util.Log;

import com.miketruso.standrewnovena.service.SharedPreferencesService;

public class StartNotificationServiceAtBootReceiver extends BroadcastReceiver {

    private static final String TAG = "StartNotifyServiceBoot";
    private static final String NOTIFY_DEFAULT = "DEFAULT";
    SharedPreferencesService sharedPreferencesService = new SharedPreferencesService();


    @Override
    public void onReceive(Context context, Intent intent) {
        if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
            if(NOTIFY_DEFAULT.equals(sharedPreferencesService.getNotificationType())){
                Log.d(TAG, "Restarting notification job.");
                //TODO
            }
        }
    }
}
