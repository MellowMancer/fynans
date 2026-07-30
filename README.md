# Fynans

Fynans is a Flutter personal-finance tracker for Android. It reads bank transaction
SMS messages, parses them automatically, and lets you manually add and categorize transactions — all stored locally on-device with Hive.

## Setup

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.44.0, stable channel (bundles Dart)
- Android SDK 36.1.0 (platform API 36) — install via Android Studio or `sdkmanager`
- JDK 17–21 to run the Android Gradle build (Android Studio bundles a compatible JDK 21; newer JDKs like 24/25 are not yet supported by this project's Gradle 8.14)
- An Android device or emulator running Android 6.0 (API 23) or newer

Run `flutter doctor` to confirm your setup.

### Run

```bash
flutter pub get          # install dependencies
flutter run -d android   # build and launch on a connected Android device
```

> If you change any `@HiveType` model, regenerate the Hive adapters:
> ```bash
> dart run build_runner build --delete-conflicting-outputs
> ```

## Docker

The included `Dockerfile` provides a complete Flutter + Android SDK build environment,
so you can build the app without installing Flutter locally (useful for reproducible/CI builds).

```bash
# Build the dev-environment image
docker build -t fynans-dev .

# Build a release APK (output lands in build/app/outputs/flutter-apk/).
# --user + HOME keep generated files owned by your host user instead of root.
docker run --rm -v "$PWD":/app -w /app \
  --user "$(id -u):$(id -g)" -e HOME=/tmp \
  fynans-dev bash -c "flutter pub get && flutter build apk"

# Or open an interactive shell inside the environment
docker run --rm -it -v "$PWD":/app -w /app \
  --user "$(id -u):$(id -g)" -e HOME=/tmp fynans-dev bash
```

> Omitting `--user` makes the build write files (`build/`, `.dart_tool/`) back to the
> mounted directory as **root** on your host. Deploying to a physical device from inside
> Docker also needs USB passthrough (`--privileged -v /dev/bus/usb:/dev/bus/usb`) —
> running on-device is simpler with a native Flutter install.
