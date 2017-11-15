package com.miketruso.standrewnovena.service;

import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;
import android.widget.Toast;

import com.miketruso.standrewnovena.activity.MainActivity;
import com.miketruso.standrewnovena.receiver.NotificationPublisher;
import com.miketruso.standrewnovena.R;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Locale;

public class NotificationService extends Service {

    private static final String TAG = "NotificationService";
    private static final String NOTIFICATION_CHANNEL_ID = "st_andrew_notifications";
    static final long[] DEFAULT_VIBRATE_PATTERN = {0, 250, 250};
    AlarmManager alarmManager;

    @Override
    public IBinder onBind(Intent arg0) {
        // TODO Auto-generated method stub
        return null;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "Start command received.");
        scheduleNotification();
        return START_NOT_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        alarmManager.cancel(assembleNotificationPendingIntent(getNotification("Oremus")));
        Log.d(TAG, "Existing alarms cancelled");
        Toast.makeText(this, "Notifications disabled", Toast.LENGTH_LONG).show();
    }

    /**
     * Default notification behavior: 7am to 7pm
     */
    public void scheduleNotification(){
        PendingIntent pendingIntent = assembleNotificationPendingIntent(getNotification("Oremus"));

        Calendar startTime = getStartTime();
        Calendar endTime = getEndTime(startTime);

        Log.d(TAG, "StartTime: " + startTime.getTime());
        Log.d(TAG, "EndTime: " + endTime.getTime());

        alarmManager = (AlarmManager)getSystemService(Context.ALARM_SERVICE);
        alarmManager.setRepeating(AlarmManager.RTC_WAKEUP, startTime.getTimeInMillis(),
                calculateNotificationInterval(startTime, endTime), pendingIntent);
        displayStartTimeToast(startTime);
    }

    private PendingIntent assembleNotificationPendingIntent(Notification notification){
        Log.d(TAG, "notification: " + notification.toString());
        Intent notificationIntent = new Intent(this, NotificationPublisher.class);
        notificationIntent.putExtra(NotificationPublisher.NOTIFICATION_ID, 1);
        notificationIntent.putExtra(NotificationPublisher.NOTIFICATION, notification);

        return PendingIntent.getBroadcast(this, 0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT);
    }

    private Notification getNotification(String content) {
        Notification.Builder builder = new Notification.Builder(this);
        builder.setContentTitle("Pray the St. Andrew Novena");
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
            NotificationManager mNotificationManager =
                    (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
            CharSequence name = getString(R.string.notification_channel_title);
            String description = getString(R.string.notification_channel_description);
            int importance = NotificationManager.IMPORTANCE_HIGH;
            NotificationChannel mChannel = new NotificationChannel(NOTIFICATION_CHANNEL_ID, name, importance);
            mChannel.setDescription(description);
            mChannel.enableLights(true);
            mChannel.enableVibration(true);
            mChannel.setVibrationPattern(DEFAULT_VIBRATE_PATTERN);
            mNotificationManager.createNotificationChannel(mChannel);
        }
    }

    private static Calendar getStartTime() {
        Calendar startTime = Calendar.getInstance();
        startTime.setTimeInMillis(System.currentTimeMillis());
        startTime.set(Calendar.HOUR_OF_DAY, 7);
        startTime.set(Calendar.MINUTE,0);
        return startTime;
    }

    private static Calendar getEndTime(Calendar startTime) {
        Calendar endTime = Calendar.getInstance();
        endTime.set(Calendar.HOUR_OF_DAY, startTime.get(Calendar.HOUR_OF_DAY));
        endTime.set(Calendar.MINUTE, startTime.get(Calendar.MINUTE));
        endTime.add(Calendar.HOUR, 12);
        return endTime;
    }

    private static long calculateNotificationInterval(Calendar startTime, Calendar endTime){
        long timeSpanMilis = endTime.getTimeInMillis() - startTime.getTimeInMillis();
        long interval = timeSpanMilis/15;
        Log.d(TAG, "Time Interval: " + interval);
        return interval;
    }

    private void displayStartTimeToast(Calendar startTime) {
        if(isCurrentTimeAfterEndTime(startTime)){
            startTime.add(Calendar.DAY_OF_YEAR, 1);
            Log.d(TAG, "Start Tomorrow at " + startTime.getTime());
        }
        String dateString = new SimpleDateFormat("E MMM dd HH:mm aa", Locale.getDefault()).format(startTime.getTime());
        Toast.makeText(this, "Notifications scheduled to start at " + dateString, Toast.LENGTH_LONG).show();
    }

    /**
     * Check if the current time is after end time.
     *
     * @return boolean
     */
    private static boolean isCurrentTimeAfterEndTime(Calendar startTime) {
        Calendar endTime = getEndTime(startTime);
        Calendar currentTime = Calendar.getInstance();
        Log.d(TAG, "CurrentTime: " + currentTime.getTime());
        if(currentTime.getTimeInMillis() > endTime.getTimeInMillis()){
            return true;
        }
        return false;
    }

}
