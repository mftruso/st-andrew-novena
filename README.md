# St. Andrew Novena Mobile App

A tradition in the Catholic Church is to pray the St. Andrew Novena prayer 15 times each day
from the feast of St. Andrew on November 30 until Christmas.

This app aims to aid in that prayer by tracking the number of times the prayer is recited.
Pretty simple! Just like this prayer.

[Download from the Google Play Store](https://play.google.com/store/apps/details?id=com.miketruso.standrewnovena)


## Learn More

- [What is a Novena?](https://en.wikipedia.org/wiki/Novena)
- [Prepare for Christmas with the St. Andrew Novena](http://aleteia.org/2016/11/30/prepare-for-christmas-with-the-saint-andrew-novena/)

## Features

- Tap the Amen button to increment the prayer count
- Prayer count refreshes each day
- Notifications can be enabled to remind you to pray periodically throughout the day. They start each day at 7 a.m. Once you've completed the prayer 15 times, notifications pause until the next day.

## Development

Built with [Flutter](https://flutter.dev/) v3.38.3

```
flutter doctor
flutter pub get
```

test on connected android device
```
flutter build apk
flutter install
```

Run locally
```
flutter run
```

## Publish

### Android

create `android/key.properties`. NB: this file should never be committed 
```
storePassword=
keyPassword=
keyAlias=upload
storeFile=<location of the key store file, such as /Users/<user name>/android.jks>
```

build android app bundle
```
flutter build appbundle
```