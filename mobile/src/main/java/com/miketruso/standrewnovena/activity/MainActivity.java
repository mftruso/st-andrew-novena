package com.miketruso.standrewnovena.activity;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.TextView;

import com.miketruso.standrewnovena.R;

import java.util.Calendar;

/**
 * +AMDG+
 *
 * +JMJ+
 *
 * Sanctus Andrea, ora pro nobis!
 */

public class MainActivity extends AppCompatActivity {

    private static final String MY_PREFERENCES = "STANDREWSHAREDPREFERENCES";
    private static final String COUNT_KEY = "dailyPrayerCount";
    private static final String RESET_KEY = "resetTime";
    private static final String TAG = "MainActivity";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Toolbar myToolbar = (Toolbar) findViewById(R.id.standrew_toolbar);
        setSupportActionBar(myToolbar);
        getSupportActionBar().setTitle(R.string.app_name);

        if(needsReset()){
            setLastReset(Calendar.getInstance());
            setDailyPrayerCount(0);
        }
        updateCountInView();
    }

    @Override
    protected void onRestart(){
        super.onRestart();
        if(needsReset()){
            setLastReset(Calendar.getInstance());
            setDailyPrayerCount(0);
        }
        updateCountInView();
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.action_notify_settings:
                Log.d(TAG, "go to notification settings");
                Intent intent = new Intent(this, NotificationActivity.class);
                startActivity(intent);
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }
    }

    public void incrementDailyPrayerCount(View view){
        int prayerCount = readDailyPrayerCount();
        prayerCount++;
        setDailyPrayerCount(prayerCount);
    }

    public void updateCountInView(){
        TextView textView = (TextView) findViewById(R.id.dailyPrayerCountHolder);
        textView.setText(String.valueOf(readDailyPrayerCount()));
    }

    private int readDailyPrayerCount(){
        SharedPreferences sharedPref = getSharedPreferences(MY_PREFERENCES, Context.MODE_PRIVATE);
        return sharedPref.getInt(COUNT_KEY, 0);
    }

    private void setDailyPrayerCount(int prayerCount){
        SharedPreferences sharedPref = getSharedPreferences(MY_PREFERENCES,Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putInt(COUNT_KEY, prayerCount);
        editor.commit();
        updateCountInView();
    }

    /**
     * lookup when the daily count was last reset, default is today
     * @return Calendar
     */
    private Calendar readLastReset(){
        SharedPreferences sharedPref = getSharedPreferences(MY_PREFERENCES, Context.MODE_PRIVATE);
        long lastResetTime = sharedPref.getLong(RESET_KEY, lookupYesterday().getTimeInMillis());
        Calendar cal = Calendar.getInstance();
        cal.setTimeInMillis(lastResetTime);
        return cal;
    }

    private void setLastReset(Calendar cal){
        SharedPreferences sharedPref = getSharedPreferences(MY_PREFERENCES,Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putLong(RESET_KEY, cal.getTimeInMillis());
        editor.commit();
    }

    /**
     * Check if the count was reset today
     *
     * @return boolean
     */
    private boolean needsReset(){
        boolean needsReset = false;
        Calendar lastReset = readLastReset();
        Calendar today = Calendar.getInstance();

        if (lastReset.get(Calendar.YEAR) != today.get(Calendar.YEAR)
                || lastReset.get(Calendar.DAY_OF_YEAR) < today.get(Calendar.DAY_OF_YEAR)) {
            needsReset = true;
        }

        return needsReset;
    }

    private Calendar lookupYesterday(){
        Calendar cal = Calendar.getInstance();
        cal.add(Calendar.DATE, -1);
        return cal;
    }
}

