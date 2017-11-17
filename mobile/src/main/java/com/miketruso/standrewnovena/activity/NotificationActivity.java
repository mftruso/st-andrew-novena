package com.miketruso.standrewnovena.activity;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.Menu;
import android.widget.CompoundButton;
import android.widget.Switch;
import android.widget.Toast;

import com.firebase.jobdispatcher.FirebaseJobDispatcher;
import com.firebase.jobdispatcher.GooglePlayDriver;
import com.firebase.jobdispatcher.Job;
import com.firebase.jobdispatcher.Lifetime;
import com.firebase.jobdispatcher.Trigger;
import com.miketruso.standrewnovena.R;
import com.miketruso.standrewnovena.service.NotificationJobService;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Locale;


public class NotificationActivity extends AppCompatActivity {

    private static final String TAG = "NotificationActivity";
    private static final String NOTIFY_DEFAULT = "DEFAULT";
    private static final String NOTIFY_NONE = "NONE";
    private static final String MY_PREFERENCES = "STANDREWSHAREDPREFERENCES";
    private static final String NOTIFY_KEY = "NOTIFICATION_TYPE";
    private static final String JOB_TAG = "st-andrew-notification-job";

    FirebaseJobDispatcher dispatcher;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_notification_settings);

        dispatcher = new FirebaseJobDispatcher(new GooglePlayDriver(this));

        Switch toggle = (Switch) findViewById(R.id.notifications_enabled_switch);
        if(NOTIFY_DEFAULT.equals(getNotificationType())){
            toggle.setChecked(true);
        }

        toggle.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (isChecked) {
                    startNotifications();
                } else {
                    stopNotifications();
                }
            }
        });
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.main, menu);
        return true;
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

    private void startNotifications(){
        setNotificationType(NOTIFY_DEFAULT);

        Calendar startTime = getStartTime();
        Calendar endTime = getEndTime(startTime);
        Integer interval = (int) calculateNotificationInterval(startTime, endTime) / 1000;

        Job myJob = dispatcher.newJobBuilder()
                .setService(NotificationJobService.class)
                .setTag(JOB_TAG)
                .setRecurring(true)
                .setLifetime(Lifetime.FOREVER)
                .setTrigger(Trigger.executionWindow(0, interval))
                .setReplaceCurrent(false)
                .build();

        dispatcher.mustSchedule(myJob);
        displayStartTimeToast(startTime);
    }

    private void stopNotifications(){
        setNotificationType(NOTIFY_NONE);
        dispatcher.cancel(JOB_TAG);
        Toast.makeText(this, R.string.toast_notification_disabled, Toast.LENGTH_LONG).show();    }

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

    /**
     * Returns a time interval in milliseconds
     * @param startTime
     * @param endTime
     * @return
     */
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
        String text = getString(R.string.toast_notification_start_time, dateString);
        Toast.makeText(this, text, Toast.LENGTH_LONG).show();
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
        return currentTime.getTimeInMillis() > endTime.getTimeInMillis();
    }
}