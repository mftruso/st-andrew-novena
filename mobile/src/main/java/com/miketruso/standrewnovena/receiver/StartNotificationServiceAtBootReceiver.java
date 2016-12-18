package com.miketruso.standrewnovena.receiver;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.util.Log;

import com.miketruso.standrewnovena.service.NotificationService;

import java.util.Calendar;

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
                Calendar startTime = Calendar.getInstance();
                startTime.setTimeInMillis(System.currentTimeMillis());
                startTime.set(Calendar.HOUR_OF_DAY, 7);
                startTime.set(Calendar.MINUTE,0);

                Intent serviceIntent = new Intent(context, NotificationService.class);
                serviceIntent.putExtra("NOTIFICATION_START_TIME", startTime.getTimeInMillis());
                context.startService(serviceIntent);
            }
        }
    }

    private String getNotificationType(Context context){
        SharedPreferences sharedPref = context.getSharedPreferences(MY_PREFERENCES,Context.MODE_PRIVATE);
        return sharedPref.getString(NOTIFY_KEY, NOTIFY_NONE);
    }

}
