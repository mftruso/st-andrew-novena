package com.miketruso.standrewnovena;

import android.app.Notification;
import android.app.NotificationManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.util.Log;

import java.util.Calendar;

public class NotificationPublisher extends BroadcastReceiver {

    public static String NOTIFICATION_ID = "notification-id";
    public static String NOTIFICATION = "notification";

    private static final String MY_PREFERENCES = "STANDREWSHAREDPREFERENCES";
    private static final String COUNT_KEY = "dailyPrayerCount";
    private static final String TAG = "NotificationPublisher";

    public void onReceive(Context context, Intent intent) {

        NotificationManager notificationManager = (NotificationManager)context.getSystemService(Context.NOTIFICATION_SERVICE);

        Notification notification = intent.getParcelableExtra(NOTIFICATION);
        Log.d("NotificationPublisher", "receiving notification: " + notification.toString());
        int id = intent.getIntExtra(NOTIFICATION_ID, 0);
        if(showNotification(context)){
            notificationManager.notify(id, notification);
        }
    }

    /**
     * Check if the user has completed 15 recitations of the prayer or if its after hours.
     *
     * @param context
     * @return boolean
     */
    private boolean showNotification(Context context){
        boolean showNotification = true;

        Calendar endTime = Calendar.getInstance();
        endTime.setTimeInMillis(System.currentTimeMillis());
        endTime.set(Calendar.HOUR_OF_DAY, 19);
        endTime.set(Calendar.MINUTE, 0);

        if(readDailyPrayerCount(context) >= 15 ||
                Calendar.getInstance().getTimeInMillis() > endTime.getTimeInMillis()){
            showNotification = false;
            Log.d(TAG, "No need to show the notification right now.");
        }

        return showNotification;
    }

    private int readDailyPrayerCount(Context context){
        SharedPreferences sharedPref = context.getSharedPreferences(MY_PREFERENCES, Context.MODE_PRIVATE);
        int dailyPrayerCount = sharedPref.getInt(COUNT_KEY, 0);
        Log.d(TAG, "Current prayer count: " + dailyPrayerCount);
        return dailyPrayerCount;
    }
}
