# Build Android App Bundle (AAB) for Google Play Store

## Quick build

From this directory (`apptemplate/`), run:

```bash
flutter build appbundle
```

The AAB will be at:

**`build/app/outputs/bundle/release/app-release.aab`**

Upload this file in [Google Play Console](https://play.google.com/console) under your app → Release → Production (or Testing) → Create new release.

---

## Release signing (required for Play Store)

For production, use a **release keystore** instead of the debug key.

### 1. Create a keystore (one-time)

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Store `upload-keystore.jks` somewhere safe and **back it up**. You need it for every future update.

### 2. Configure signing

In `android/`, copy the example and edit:

```bash
cd android
cp key.properties.example key.properties
```

Edit `key.properties` (do **not** commit it):

```properties
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=upload
storeFile=../path/to/upload-keystore.jks
```

Use an absolute path or a path relative to `android/` for `storeFile`, e.g. `storeFile=/Users/you/keystores/upload-keystore.jks`.

### 3. Build signed AAB

```bash
flutter build appbundle
```

The same command now produces a release-signed AAB.

---

## Version for each release

Set version in `pubspec.yaml` (e.g. `version: 1.0.0+1`) or override when building:

```bash
flutter build appbundle --build-name=1.0.0 --build-number=2
```

---

## Checklist

- [ ] Flutter installed and on your PATH (`flutter doctor`)
- [ ] Release keystore created and `key.properties` set (for Play Store)
- [ ] App version and build number updated
- [ ] Upload `app-release.aab` in Play Console
