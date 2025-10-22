# Android – v3magazin

## Open & run

1) Open `magazin_v3.Android/android` in Android Studio
2) Wait for Gradle Sync
3) Create/start a virtual device (Pixel, API 34)
4) Run the `app` configuration

## CLI build

```
cd magazin_v3.Android/android
./gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n com.glyanec.shop/.MainActivity
```

## Release bundle

```
./gradlew bundleRelease
# Output: app/build/outputs/bundle/release/app-release.aab
```

## Troubleshooting

- Ensure Java 17 is used (Android Studio bundled JDK is fine)
- If WebView is blank on first boot – restart the app (adb shell am force-stop com.glyanec.shop)


