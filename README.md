# v3magazin – iOS & Android apps

Monorepo with two platform projects:

- magazin_v3.IOS – Xcode workspace with iOS app (WebView + native tabs, Basket)
- magazin_v3.Android/android – Android Studio project (WebView + native tabs, Basket)

## Folder structure

- magazin_v3.IOS/
  - Glyanec.xcworkspace – open this in Xcode
  - Glyanec.xcodeproj, Glyanec/, Pods/ – project sources and dependencies
- magazin_v3.Android/
  - android/ – Gradle project root (open in Android Studio)

## Requirements

- macOS (for building iOS). Xcode 15+
- Android Studio (Hedgehog/Koala or newer) with Android SDK 34
- Java 17 (bundled with Android Studio is OK)

## Quick start – iOS

1) Open the workspace
   - Double–click `magazin_v3.IOS/Glyanec.xcworkspace`
2) Select a simulator (e.g. iPhone 15)
3) Run (⌘R)

If CocoaPods reinstallation is needed on your machine:

```
cd magazin_v3.IOS
sudo gem install cocoapods # if pods not installed
pod install
open Glyanec.xcworkspace
```

## Quick start – Android

Option A – Android Studio (recommended)
1) Open `magazin_v3.Android/android` in Android Studio
2) Let Gradle sync finish
3) Create/start an emulator via Device Manager (Pixel device, API 34)
4) Run the `app` configuration

Option B – CLI

```
cd magazin_v3.Android/android
./gradlew assembleDebug

# If an emulator is configured, you can install the apk
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n com.glyanec.shop/.MainActivity
```

## What’s implemented

- WebView-powered store screens for Home, Catalog, Favorites
- Native BottomNavigation
- Native Basket (RecyclerView on Android, UITableView on iOS) with local persistence

## Notes for App Store / Google Play

- Keep platform bundles independent: iOS builds/upload via Xcode, Android via `bundleRelease` / Play Console
- Provide Privacy Policy URL, app screenshots (Home, Catalog, Favorites, Basket)

## Repo housekeeping

- Top-level docs (README, QUICKSTART, INTEGRATION_GUIDE, CHANGELOG) remain here
- iOS and Android codebases live inside their platform folders

# GlyanecShop_iOS

Application template for an online store.
Swift development language.
MVVM architecture