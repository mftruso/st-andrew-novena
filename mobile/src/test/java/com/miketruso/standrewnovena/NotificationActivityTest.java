package com.miketruso.standrewnovena;

import com.miketruso.standrewnovena.activity.NotificationActivity;

import org.junit.Test;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.Calendar;

import static org.junit.Assert.assertEquals;

public class NotificationActivityTest {

    @Test
    public void calculateNotificationInterval_twelveHour() throws InvocationTargetException, IllegalAccessException, NoSuchMethodException {
        Calendar startTime = Calendar.getInstance();
        Calendar endTime = Calendar.getInstance();
        endTime.set(Calendar.HOUR_OF_DAY, startTime.get(Calendar.HOUR_OF_DAY));
        endTime.set(Calendar.MINUTE, startTime.get(Calendar.MINUTE));
        endTime.add(Calendar.HOUR, 12);

        Class[] cArg = new Class[2];
        cArg[0] = Calendar.class;
        cArg[1] = Calendar.class;

        Method method = NotificationActivity.class.getDeclaredMethod("calculateNotificationInterval", cArg);
        method.setAccessible(true);
        Object result = method.invoke(method, startTime, endTime);
        assertEquals(2880000l, result); //48 minutes
    }
}
