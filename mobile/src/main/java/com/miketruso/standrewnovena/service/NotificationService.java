package com.miketruso.standrewnovena.service;

import android.app.AlarmManager;
import android.app.Notification;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
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

    @Override
    public IBinder onBind(Intent arg0) {
        // TODO Auto-generated method stub
        return null;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "Start command received.");
        Calendar cal = Calendar.getInstance();
        cal.setTimeInMillis(intent.getLongExtra("NOTIFICATION_START_TIME", cal.getTimeInMillis()));
        scheduleNotification(cal);
        return START_NOT_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        AlarmManager alarmManager = (AlarmManager)getSystemService(Context.ALARM_SERVICE);
        alarmManager.cancel(assembleNotificationPendingIntent(getNotification("Oremus")));
        Log.d(TAG, "Existing alarms cancelled");
        Toast.makeText(this, "Notifications disabled", Toast.LENGTH_LONG).show();
    }

    /**
     * Default notification behavior: 7am to 7pm
     */
    public void scheduleNotification(Calendar startTime){
        PendingIntent pendingIntent = assembleNotificationPendingIntent(getNotification("Oremus"));

        Calendar endTime = Calendar.getInstance();
        endTime.set(Calendar.HOUR_OF_DAY, startTime.get(Calendar.HOUR_OF_DAY));
        endTime.set(Calendar.MINUTE, startTime.get(Calendar.MINUTE));
        endTime.add(Calendar.HOUR, 12);

        Log.d(TAG, "CurrentTime: " + Calendar.getInstance().getTime());
        Log.d(TAG, "StartTime: " + startTime.getTime());
        Log.d(TAG, "EndTime: " + endTime.getTime());

        //check if current time is after end time
        if(endTime.getTimeInMillis() < Calendar.getInstance().getTimeInMillis()){
            startTime.add(Calendar.DAY_OF_YEAR, 1);
            endTime.add(Calendar.DAY_OF_YEAR, 1);
            Log.d(TAG, "Start Tomorrow at " + startTime.getTime());
        }

        AlarmManager alarmManager = (AlarmManager)getSystemService(Context.ALARM_SERVICE);
        alarmManager.setRepeating(AlarmManager.RTC_WAKEUP, startTime.getTimeInMillis(),
                calculateNotificationInterval(startTime, endTime), pendingIntent);
        String dateString = new SimpleDateFormat("E MMM dd HH:mm aa", Locale.getDefault()).format(startTime.getTime());
        Toast.makeText(this, "Notifications scheduled to start at " + dateString, Toast.LENGTH_LONG).show();
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
        builder.setVibrate(new long[] { 1000, 1000});

        Intent intent = new Intent(this, MainActivity.class);
        builder.setContentIntent(PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT));
        builder.setAutoCancel(true);
        return builder.build();
    }

    private static long calculateNotificationInterval(Calendar startTime, Calendar endTime){
        long timeSpanMilis = endTime.getTimeInMillis() - startTime.getTimeInMillis();
        long interval = timeSpanMilis/15;
        Log.d(TAG, "Time Interval: " + interval);
        return interval;
    }

}
