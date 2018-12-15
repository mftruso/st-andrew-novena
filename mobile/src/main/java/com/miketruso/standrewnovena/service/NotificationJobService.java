package com.miketruso.standrewnovena.service;


import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.util.Log;

import com.firebase.jobdispatcher.JobParameters;
import com.firebase.jobdispatcher.JobService;
import com.miketruso.standrewnovena.R;
import com.miketruso.standrewnovena.activity.MainActivity;

import java.util.Calendar;


public class NotificationJobService extends JobService {

    private static final String TAG = "NotificationJobService";
    private static final String MY_PREFERENCES = "STANDREWSHAREDPREFERENCES";
    private static final String COUNT_KEY = "dailyPrayerCount";
    private static final String NOTIFICATION_CHANNEL_ID = "st_andrew_notifications";
    public static final int NOTIFICATION_ID = 1;

    static final long[] DEFAULT_VIBRATE_PATTERN = {0, 250, 250};

    NotificationManager notificationManager;

    SharedPreferencesService sharedPreferencesService = new SharedPreferencesService();

    @Override
    public boolean onStartJob(JobParameters params) {
        Log.d(TAG, "NotificationJobService started");
        notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        Notification notification = getNotification(getString(R.string.oremus));
        if(showNotification(this)){
            notificationManager.notify(NOTIFICATION_ID, notification);
        }
        return false;
    }

    @Override
    public boolean onStopJob(JobParameters params) {
        Log.d(TAG, "NotificationJobService stopped");
        return false;
    }

    private Notification getNotification(String content) {
        Notification.Builder builder = new Notification.Builder(this);
        builder.setContentTitle(getString(R.string.notification_content_title));
        builder.setContentText(content);
        builder.setSmallIcon(R.drawable.ic_notifications_white_18dp);
        builder.setVibrate(DEFAULT_VIBRATE_PATTERN);
        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannel();
            builder.setChannelId(NOTIFICATION_CHANNEL_ID);
        }

        Intent intent = new Intent(this, MainActivity.class);
        builder.setContentIntent(PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT));
        builder.setAutoCancel(true);
        return builder.build();
    }

    private void createNotificationChannel() {
        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            CharSequence name = getString(R.string.notification_channel_title);
            String description = getString(R.string.notification_channel_description);
            int importance = NotificationManager.IMPORTANCE_HIGH;
            NotificationChannel mChannel = new NotificationChannel(NOTIFICATION_CHANNEL_ID, name, importance);
            mChannel.setDescription(description);
            mChannel.enableLights(true);
            mChannel.enableVibration(true);
            mChannel.setVibrationPattern(DEFAULT_VIBRATE_PATTERN);
            notificationManager.createNotificationChannel(mChannel);
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
        Calendar currentTime = Calendar.getInstance();
        Calendar endTime = Calendar.getInstance();
        endTime.setTimeInMillis(System.currentTimeMillis());
        endTime.set(Calendar.HOUR_OF_DAY, 19);
        endTime.set(Calendar.MINUTE, 0);

        if (sharedPreferencesService.needsReset()) {
            sharedPreferencesService.setDailyPrayerCount(0);
        }
        if (readDailyPrayerCount(context) >= 15
                || currentTime.getTimeInMillis() > endTime.getTimeInMillis()){
            showNotification = false;
            Log.d(TAG,"Current time: " + currentTime.getTime() + " End Time: " + endTime.getTime());
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
