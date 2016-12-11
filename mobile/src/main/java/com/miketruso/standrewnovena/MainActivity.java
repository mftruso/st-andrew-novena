package com.miketruso.standrewnovena;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.view.View;
import android.widget.TextView;

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
        int dailyPrayerCount = sharedPref.getInt(COUNT_KEY, 0);
        return dailyPrayerCount;
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

    //TODO: Notification modes: NONE, DEFAULT, CUSTOM
    //TODO: Make notification on schedule


}

