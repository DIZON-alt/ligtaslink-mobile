LIGTASLINK - QUICK START

To run the app from a terminal:

1. Install Flutter. For Android, also install Android Studio and start an
   emulator, or connect an Android phone with USB debugging enabled.
2. Open PowerShell in the folder containing pubspec.yaml.
3. Run:

   flutter pub get
   flutter devices
   flutter run -d chrome

To run on an Android device or emulator, use its ID from "flutter devices":

   flutter run -d <device-id>

The Flutter source is the app; do not upload generated .exe files to GitHub.
See README.md for more setup details.
