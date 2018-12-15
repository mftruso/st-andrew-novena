package com.miketruso.standrewnovena.activity;

import android.content.Intent;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.TextView;

import com.miketruso.standrewnovena.R;
import com.miketruso.standrewnovena.service.SharedPreferencesService;


/**
 * +AMDG+
 * <p>
 * +JMJ+
 * <p>
 * Sanctus Andrea, ora pro nobis!
 */

public class MainActivity extends AppCompatActivity {

    private static final String TAG = "MainActivity";
    private SharedPreferencesService sharedPreferencesService = new SharedPreferencesService();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Toolbar myToolbar = (Toolbar) findViewById(R.id.standrew_toolbar);
        setSupportActionBar(myToolbar);
        getSupportActionBar().setTitle(R.string.app_name);

        if (sharedPreferencesService.needsReset()) {
            setDailyPrayerCount(0);
        }
        updateCountInView();
    }

    @Override
    protected void onRestart() {
        super.onRestart();
        if (sharedPreferencesService.needsReset()) {
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

    public void incrementDailyPrayerCount(View view) {
        int prayerCount = sharedPreferencesService.getDailyPrayerCount();
        prayerCount++;
        setDailyPrayerCount(prayerCount);
    }

    private void setDailyPrayerCount(int prayerCount) {
        sharedPreferencesService.setDailyPrayerCount(prayerCount);
        updateCountInView();
    }

    public void updateCountInView() {
        TextView textView = (TextView) findViewById(R.id.dailyPrayerCountHolder);
        textView.setText(String.valueOf(sharedPreferencesService.getDailyPrayerCount()));
    }
}
