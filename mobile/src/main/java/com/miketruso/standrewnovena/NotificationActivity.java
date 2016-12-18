package com.miketruso.standrewnovena;

import android.app.AlarmManager;
import android.app.Notification;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.Menu;
import android.widget.CompoundButton;
import android.widget.Switch;
import android.widget.Toast;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Locale;


public class NotificationActivity extends AppCompatActivity {

    private static final String TAG = "NotificationActivity";
    private static final String NOTIFY_DEFAULT = "DEFAULT";
    private static final String NOTIFY_NONE = "NONE";
    private static final String MY_PREFERENCES = "STANDREWSHAREDPREFERENCES";
    private static final String NOTIFY_KEY = "NOTIFICATION_TYPE";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_notification_settings);

        Switch toggle = (Switch) findViewById(R.id.notifications_enabled_switch);
        if(NOTIFY_DEFAULT.equals(getNotificationType())){
            toggle.setChecked(true);
        }

        toggle.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (isChecked) {
                    setNotificationType(NOTIFY_DEFAULT);
                    Calendar startTime = Calendar.getInstance();
                    startTime.setTimeInMillis(System.currentTimeMillis());
                    startTime.set(Calendar.HOUR_OF_DAY, 7);
                    startTime.set(Calendar.MINUTE,0);

                    Calendar endTime = Calendar.getInstance();
                    endTime.set(Calendar.HOUR_OF_DAY, 7);
                    endTime.set(Calendar.MINUTE, 0);
                    endTime.add(Calendar.HOUR, 12);

                    scheduleNotification(getNotification("Oremus"), startTime, endTime);
                } else {
                    setNotificationType(NOTIFY_NONE);
                    cancelAllAlarms();
                }
            }
        });
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.main, menu);
        return true;
    }

    /**
     * Default notification behavior: 7am to 7pm
     * @param notification
     */
    private void scheduleNotification(Notification notification, Calendar startTime, Calendar endTime){
        PendingIntent pendingIntent = assembleNotificationPendingIntent(notification);

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
        return builder.getNotification();
    }

    private String getNotificationType(){
        SharedPreferences sharedPref = getSharedPreferences(MY_PREFERENCES,Context.MODE_PRIVATE);
        return sharedPref.getString(NOTIFY_KEY, NOTIFY_NONE);
    }

    private void setNotificationType(String notificationType){
        Log.d(TAG, "setting notificationType to: " + notificationType);
        SharedPreferences sharedPref = getSharedPreferences(MY_PREFERENCES,Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putString(NOTIFY_KEY, notificationType);
        editor.apply();
    }

    private long calculateNotificationInterval(Calendar startTime, Calendar endTime){
        long timeSpanMilis = endTime.getTimeInMillis() - startTime.getTimeInMillis();
        long interval = timeSpanMilis/15;
        Log.d(TAG, "Time Interval: " + interval);
        return interval;
    }

    private void cancelAllAlarms(){
        AlarmManager alarmManager = (AlarmManager)getSystemService(Context.ALARM_SERVICE);
        alarmManager.cancel(assembleNotificationPendingIntent(getNotification("Oremus")));
        Log.d(TAG, "Existing alarms cancelled");
        Toast.makeText(this, "Notifications disabled", Toast.LENGTH_LONG).show();
    }

}