package com.miketruso.standrewnovena.receiver;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.util.Log;

import com.miketruso.standrewnovena.service.NotificationService;

public class StartNotificationServiceAtBootReceiver extends BroadcastReceiver {

    private static final String TAG = "StartNotifyServiceBoot";
    private static final String NOTIFY_DEFAULT = "DEFAULT";
    private static final String NOTIFY_NONE = "NONE";
    private static final String NOTIFY_KEY = "NOTIFICATION_TYPE";
    private static final String MY_PREFERENCES = "STANDREWSHAREDPREFERENCES";


    @Override
    public void onReceive(Context context, Intent intent) {
        if ("android.intent.action.BOOT_COMPLETED".equals(intent.getAction())) {
            if(NOTIFY_DEFAULT.equals(getNotificationType(context))){
                Log.d(TAG, "Restarting notification alarm.");
                Intent serviceIntent = new Intent(context, NotificationService.class);
                context.startService(serviceIntent);
            }
        }
    }

    private String getNotificationType(Context context){
        SharedPreferences sharedPref = context.getSharedPreferences(MY_PREFERENCES,Context.MODE_PRIVATE);
        return sharedPref.getString(NOTIFY_KEY, NOTIFY_NONE);
    }

}
