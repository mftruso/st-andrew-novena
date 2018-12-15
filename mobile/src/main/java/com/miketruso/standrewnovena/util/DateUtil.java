package com.miketruso.standrewnovena.util;

import java.util.Calendar;

public class DateUtil {

    public static Calendar lookupYesterday(){
        Calendar cal = Calendar.getInstance();
        cal.add(Calendar.DATE, -1);
        return cal;
    }
}
