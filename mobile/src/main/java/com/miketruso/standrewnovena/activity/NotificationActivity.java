package com.miketruso.standrewnovena.activity;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.Menu;
import android.widget.CompoundButton;
import android.widget.Switch;

import com.miketruso.standrewnovena.R;
import com.miketruso.standrewnovena.service.NotificationService;

import java.util.Calendar;


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
        Calendar startTime = Calendar.getInstance();
        startTime.setTimeInMillis(System.currentTimeMillis());
        startTime.set(Calendar.HOUR_OF_DAY, 7);
        startTime.set(Calendar.MINUTE,0);
        Intent intent = new Intent(this, NotificationService.class);
        intent.putExtra("NOTIFICATION_START_TIME", startTime.getTimeInMillis());
        startService(intent);
    }

    private void stopNotifications(){
        setNotificationType(NOTIFY_NONE);
        stopService(new Intent(this, NotificationService.class));
    }
}