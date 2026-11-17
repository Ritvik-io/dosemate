<div align="center">

# 💊 DoseMate

### Your smart medication companion

**Never miss a dose. Build healthier habits.**

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
[![Release](https://img.shields.io/github/v/release/Ritvik-io/dosemate)](../../releases/latest)

[⬇️ Download APK](../../releases/latest) · [🐛 Report a Bug](../../issues) · [💡 Request a Feature](../../issues)

</div>

---

## 📖 About

DoseMate is a Flutter-based medication reminder and tracking app. It helps you manage your medicines, get timely reminders, and keep a clear history of what you've taken, so staying consistent with your routine becomes effortless.

## 📸 Screenshots

<!-- TODO: add 3-4 screenshots to /screenshots and update the paths -->
| Home | Add Medicine | Reminders | History |
|:---:|:---:|:---:|:---:|
| ![Home](screenshots/home.png) | ![Add](screenshots/add.png) | ![Reminders](screenshots/reminders.png) | ![History](screenshots/history.png) |

## ✨ Features

- 💊 **Medication Management**: add, edit and organize your medicines
- ⏰ **Smart Reminders**: scheduled notifications so you never miss a dose
- 📜 **Medication History**: review your past medication activity
- 🔐 **Secure Authentication**: sign up and log in with Firebase Auth
- ☁️ **Cloud Sync**: your data is stored in Cloud Firestore
- 👤 **Profile Section**: manage your personal profile
- 🎨 **Clean UI**: simple, modern and easy to use

## 📲 Installation (Android)

1. Go to the [latest release](../../releases/latest) and download `app-release.apk`.
2. Open the file on your device.
3. If prompted, allow **Install from unknown sources** for your browser or file manager.
4. Tap **Install** and launch DoseMate.

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| **Flutter** | Cross-platform UI framework |
| **Dart** | Programming language |
| **Firebase Authentication** | User sign-up and login |
| **Cloud Firestore** | Cloud database |
| **Flutter Local Notifications** | Medication reminders |

## 📂 Project Structure

```text
lib/
├── assets/      # Images, icons and static resources
├── models/      # Data models
├── screens/     # App screens / pages
├── services/    # Firebase, notifications and business logic
├── utils/       # Helpers and constants
├── widgets/     # Reusable UI components
└── main.dart    # App entry point
```

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- Android Studio or VS Code with the Flutter extension
- A Firebase project

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/Ritvik-io/dosemate.git
cd dosemate

# 2. Install dependencies
flutter pub get
```

### Firebase configuration

1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Add an Android app using the package name from `android/app/build.gradle`.
3. Download `google-services.json` and place it in `android/app/`.
4. Enable **Email/Password** under *Authentication → Sign-in method*.
5. Create a **Cloud Firestore** database and set appropriate security rules.

<!-- TODO: confirm these steps match your project (e.g. FlutterFire CLI / firebase_options.dart) -->

### Run

```bash
flutter run
```

## 📦 Build a Release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## 🔐 Security

- Configure Firestore security rules before deploying.
- **Never commit** `google-services.json`, service-account credentials, keystores or other secrets to a public repository (add them to `.gitignore`).

## 🗺️ Roadmap

<!-- TODO: edit to match your real plans -->
- [ ] iOS support
- [ ] Dose-streak and adherence statistics
- [ ] Refill reminders
- [ ] Dark mode
- [ ] Caregiver / family sharing

## 🤝 Contributing

Contributions, issues and feature requests are welcome! Feel free to open an [issue](../../issues) or submit a pull request.

## 📄 License

<!-- TODO: add a LICENSE file (e.g. MIT) and keep this line in sync -->
Distributed under the MIT License. See `LICENSE` for details.

## 👨‍💻 Author

**Ritvik**
GitHub: [@Ritvik-io](https://github.com/Ritvik-io)

---

<div align="center">

⭐ If you find DoseMate useful, consider giving the repo a star!

**DoseMate: Stay Consistent. Stay Healthy.** 💙

</div>
