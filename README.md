# LigtasLink

## Run from a terminal

Install Flutter and, for Android, Android Studio with an emulator or connect an
Android phone with USB debugging enabled. Open PowerShell in the folder that
contains `pubspec.yaml`, then run:

```powershell
flutter doctor
flutter pub get
flutter devices
flutter run -d chrome
```

To run on a listed Android device or emulator instead of Chrome, use its device
ID from `flutter devices`:

```powershell
flutter run -d <device-id>
```

Running with `-d chrome` does not build or launch a Windows `.exe`. Windows
executables are local build outputs and should not be uploaded to GitHub; they
can be recreated from the Flutter source.

To create a native Windows release, run `flutter build windows --release`. This requires:

- Flutter
- Visual Studio 2022 with the **Desktop development with C++** workload
- Windows 10 or Windows 11

The compiled app will be created at:

`build\windows\x64\runner\Release\ligtaslink.exe`

## Changes in this corrected package

- Configured Firebase Authentication for the Android, iOS, and web Flutter apps, with a local fallback if Firebase cannot initialize.
- Removed generated paths tied to the previous computer.
- Added local registration, sign-in, password reset by recovery PIN, saved sessions, and sign-out.
- Added responsive Dashboard, Incident Report, Contacts, Alerts, Profile, and Settings navigation with a mobile drawer and a navigation rail on wider screens.
- Expanded the signed-in mobile dashboard with Emergency SOS, Ambulance, Fire Rescue, Police Help, Road Rescue, incident reporting, emergency contacts, safety alerts, Material cards, chips, dialogs, bottom sheets, and a floating action button.
- Relaxed the Dart version requirement so the project works with more current Flutter installations.
- Added responsive layouts for computer and mobile-sized windows.
- Added a no-install computer version as a reliable launcher.
- Added live earthquake information from PHIVOLCS and typhoon bulletins from PAGASA to the National Hub.
- Added opt-in Firebase push notification subscriptions and a scheduled official-alert publisher.
- Added a dedicated Firestore profile editor, account deletion, and private, per-user incident report storage/history.

## Data note

The standalone Windows browser package stores accounts in that browser's local storage. The Flutter Android, iOS, and web apps use Firebase Authentication when Firebase initializes, unless `API_BASE_URL` selects the REST API; otherwise, they fall back to local accounts. Firebase Email/Password sign-in must be enabled in the Firebase console. Desktop Firebase options are not configured.

## Local REST API

The project includes a small local REST API for user records. Install Node.js, then run these commands from the `computer_app` folder:

```text
npm start
```

The API listens on `http://localhost:3000`.

- `GET /api/health` checks that the API is running.
- `GET /api/services` returns the structured emergency service catalog.
- `POST /api/auth/register` creates an account with `name`, `email`, `password`, and `recoveryPin`.
- `POST /api/auth/login` signs in with `email` and `password`.
- `POST /api/auth/reset-password` changes a password with `email`, `recoveryPin`, and `newPassword`.
- `GET /api/users` lists users without sensitive fields.
- `GET /api/users/:id` reads one user.
- `POST /api/users` creates a user with `name` and `email`.
- `PUT` or `PATCH /api/users/:id` updates a user.
- `DELETE /api/users/:id` removes a user.

User records are stored in `assets/data.json`. This local prototype API has no authentication and should not be exposed to the public internet.

The service catalog is stored in `assets/services.json` with a top-level `catalog` object and a `services` array. The Flutter app displays it under **Services** using searchable cards, category filters, refresh, and request buttons.

The Flutter app fetches the service catalog from the configured public Gist by default,
and falls back to the bundled catalog if the Gist is unavailable. To use the local API
instead, start the server and run Flutter with its base URL:

```text
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

For an Android emulator, use `http://10.0.2.2:3000` instead of `localhost`:

```text
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

If the Gist or configured REST API is unreachable, the Services page falls back to the
bundled catalog and displays an offline notice. For an Android emulator, use
`http://10.0.2.2:3000`; for a Windows app, use `http://localhost:3000`.

## Firebase Authentication

The Flutter app is configured for the Firebase project `ligtas-link-mobile`
on Android, iOS, and web. The Android package ID and iOS bundle ID are currently
`com.example.ligtaslink`.

Enable **Authentication > Sign-in method > Email/Password** in the Firebase
console before creating or signing into accounts. Firebase is initialized using
`lib/firebase_options.dart`; Android and iOS configuration files are also
included in their platform targets. On desktop, Firebase options are not
configured and the app continues to use its local authentication fallback.

Registration and sign-in use Firebase email/password authentication. Password recovery sends Firebase's secure reset email. The recovery PIN remains supported by the offline local provider but is not used by Firebase.

The Profile page has a dedicated **Edit profile** screen and a **My incident
reports** history. Firebase-backed incident reports are stored in the
`incident_reports` collection and are readable only by their creator. Deleting
an account requires the current password and removes that user's reports and
profile before deleting their Firebase Authentication account. The local
provider deletes the local account; the REST API does not currently support
account deletion.

Deploy the included Firestore rules and query index to enable the Firebase
features:

```text
firebase deploy --only firestore:rules,firestore:indexes
```

## Earthquake and typhoon alerts

The National Hub reads the latest earthquake list directly from
[PHIVOLCS](https://earthquake.phivolcs.dost.gov.ph/) and the active tropical
cyclone bulletin from
[PAGASA](https://www.pagasa.dost.gov.ph/tropical-cyclone/severe-weather-bulletin).
The feed refreshes every five minutes while the app is open. If either official
site is unavailable, the app shows that source's error instead of presenting it
as an all-clear. Earthquake push alerts are limited to magnitude 4.0 and above;
typhoon push alerts are sent when PAGASA publishes a new active bulletin.

Push delivery while the app is closed requires a configured Firebase project
and deployment of the included scheduled function:

1. Enable Firebase Cloud Messaging and Cloud Firestore in the project. Upload
   an APNs authentication key in Firebase project settings and enable Push
   Notifications for the iOS app in Xcode before expecting iOS pushes to arrive.
2. Install the Firebase CLI, sign in, and use the configured default project.
3. Install the alert function dependencies with `npm install --prefix functions`.
4. Deploy the publisher with
   `firebase deploy --only functions:publishDisasterAlerts`.
5. Run the app on Android or iOS, open **Settings**, and enable **Disaster push
   notifications** and the alert categories you want.

The scheduled function checks the official sources every five minutes and uses
Firebase Cloud Messaging topics for delivery. Firebase scheduled functions
require billing-enabled Google Cloud project services. Push alerts are
best-effort and must not replace official warnings or emergency services.
