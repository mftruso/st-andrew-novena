package com.miketruso.standrewnovena.service;

import android.content.SharedPreferences;
import android.util.Log;

import com.miketruso.standrewnovena.StAndrewNovenaApplication;

import java.util.Calendar;

import static com.miketruso.standrewnovena.activity.NotificationActivity.NOTIFY_NONE;
import static com.miketruso.standrewnovena.util.DateUtil.lookupYesterday;

public class SharedPreferencesService {
    private static final String TAG = "SharedPrefService";
    private static final String COUNT_KEY = "dailyPrayerCount";
    private static final String RESET_KEY = "resetTime";
    private static final String NOTIFY_KEY = "NOTIFICATION_TYPE";

    private SharedPreferences sharedPref = StAndrewNovenaApplication.getSharedPreferences();

    public int getDailyPrayerCount(){
        return sharedPref.getInt(COUNT_KEY, 0);
    }

    public void setDailyPrayerCount(int prayerCount) {
        setLastReset(Calendar.getInstance());
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putInt(COUNT_KEY, prayerCount);
        editor.commit();
    }

    /**
     * Check if the count was reset today
     *
     * @return boolean
     */
    public boolean needsReset(){
        boolean needsReset = false;
        Calendar lastReset = readLastReset();
        Calendar today = Calendar.getInstance();

        if (lastReset.get(Calendar.YEAR) != today.get(Calendar.YEAR)
                || lastReset.get(Calendar.DAY_OF_YEAR) < today.get(Calendar.DAY_OF_YEAR)) {
            needsReset = true;
        }

        return needsReset;
    }

    public String getNotificationType(){
        return sharedPref.getString(NOTIFY_KEY, NOTIFY_NONE);
    }

    public void setNotificationType(String notificationType){
        Log.d(TAG, "setting notificationType to: " + notificationType);
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putString(NOTIFY_KEY, notificationType);
        editor.apply();
    }

    /**
     * lookup when the daily count was last reset, default is today
     * @return Calendar
     */
    private Calendar readLastReset(){
        long lastResetTime = sharedPref.getLong(RESET_KEY, lookupYesterday().getTimeInMillis());
        Calendar cal = Calendar.getInstance();
        cal.setTimeInMillis(lastResetTime);
        return cal;
    }

    private void setLastReset(Calendar cal){
        SharedPreferences.Editor editor = sharedPref.edit();
        editor.putLong(RESET_KEY, cal.getTimeInMillis());
        editor.commit();
    }
}
