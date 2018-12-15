package com.miketruso.standrewnovena;

import android.app.Application;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;

public class StAndrewNovenaApplication extends Application {
    private static StAndrewNovenaApplication INSTANCE;

    private SharedPreferences sharedPref;

    @Override
    public void onCreate() {
        super.onCreate();
        INSTANCE = this;
    }

    private static StAndrewNovenaApplication getInstance() {
        return INSTANCE;
    }

    public static SharedPreferences getSharedPreferences() {
        if (INSTANCE.sharedPref == null) {
            INSTANCE.sharedPref = PreferenceManager.getDefaultSharedPreferences(INSTANCE);
        }
        return INSTANCE.sharedPref;
    }
}
