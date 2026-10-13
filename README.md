# 💊 DoseMate — Smart Medication Companion

**Your Smart Medication Companion**

DoseMate is a medication reminder and tracking mobile application designed to help users manage their medication schedules, track doses, and build healthier medication habits. It aims to make medication management simpler for individuals and help families support their loved ones.

## ✨ Features

- **Medication Management** — Add, view, edit, and delete medication records.
- **Medication Scheduling** — Set medication details, dosage, frequency, and reminder times.
- **Dose Tracking** — Track medication doses as taken or skipped.
- **Medication History** — View recorded dose activity, including medication names, dosages, dates, times, and dose status.
- **User Authentication** — Firebase Authentication integration for user accounts.
- **Cloud Data Storage** — Cloud Firestore integration for storing user-specific medication data.
- **Notifications** — Local medication reminder scheduling.
- **User-Friendly Interface** — Clean layouts, consistent typography, and a blue-and-white visual theme.
- **Onboarding Experience** — Introductory screens that explain the app's purpose and help users get started.
- **Profile & Support** — Dedicated interfaces for account information, notification settings, and app support.

> **Development note:** Features are being developed and tested iteratively. Notification delivery, permanent dose history, and other production-critical behavior must be verified before release.

## 🎨 UI/UX Design

The DoseMate interface was designed in **Figma** with an emphasis on clarity, accessibility, and ease of use.

The design process includes:

- Splash screen and app branding
- Onboarding screens
- User-type selection
- Authentication screens
- Home and medication-management screens
- History and profile screens
- Consistent colors, typography, buttons, cards, and navigation

**Design tool:** Figma

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform mobile UI |
| Dart | Application programming language |
| Firebase Authentication | User authentication |
| Cloud Firestore | Cloud database and real-time data |
| Local Notifications | Scheduled medication reminders |
| Figma | UI/UX design and prototyping |
| Git & GitHub | Version control and source-code management |

## 📱 Application Screens

DoseMate is designed around the following screens:

1. **Splash Screen** — Introduces the DoseMate brand.
2. **Onboarding** — Explains the app's main benefits.
3. **User Selection** — Helps users choose whether to manage their own medication or assist a family member.
4. **Authentication** — Provides account access.
5. **Home** — Serves as the main medication dashboard.
6. **Medications** — Displays and manages medication schedules.
7. **Add/Edit Medication** — Captures medication names, dosage, form, frequency, schedule times, and notes.
8. **History** — Displays recorded taken and skipped doses.
9. **Profile** — Provides account and support options.

## 🏗️ Project Structure

```text
lib/
├── assets/
├── models/
├── screens/
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── user_type_screen.dart
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── medications_screen.dart
│   ├── add_medicine_screen.dart
│   └── history_screen.dart
├── services/
│   └── notification_service.dart
├── utils/
├── widgets/
├── firebase_options.dart
└── main.dart
```

*The structure above describes the intended organization; filenames may differ as development progresses.*

## 🚀 Getting Started

### Prerequisites

Install the following tools:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- [Android Studio](https://developer.android.com/studio) or VS Code
- An Android emulator or physical Android device
- A Firebase project

### Installation

**1. Clone the repository**

```bash
git clone https://github.com/Ritvik-io/dosemate.git
cd dosemate
```

**2. Install dependencies**

```bash
flutter pub get
```

**3. Configure Firebase**

Configure your own Firebase project for the platforms you intend to run. Enable Firebase Authentication providers used by the app and configure Cloud Firestore.

Generate or configure the Flutter Firebase options using the [FlutterFire CLI setup guide](https://firebase.google.com/docs/flutter/setup).

Ensure that Firestore Security Rules restrict users to their own data. Never commit service-account private keys, passwords, or other confidential credentials.

**4. Run the application**

```bash
flutter run
```

To check your development environment:

```bash
flutter doctor
```

## 🔐 Security & Privacy

DoseMate handles medication-related information, so security and privacy are important.

- Use Firebase Authentication to identify users.
- Apply Firestore Security Rules to prevent unauthorized access to user data.
- Restrict Google API keys to the applications and APIs that require them.
- Keep private credentials and service-account keys out of version control.
- Test account deletion, data retention, and notification permissions before production release.

Firebase client configuration is not a substitute for database security rules.

## 🗺️ Future Improvements

- Permanent dose history that remains available after a medication is deleted.
- Daily, weekly, and monthly medication-adherence summaries.
- History filters for taken, skipped, and missed doses.
- Reliable recurring reminders and notification-permission handling.
- Profile editing and account-management functionality.
- Family or caregiver support.
- Improved accessibility and additional UI testing.
- Automated tests and production-release preparation.

## 🎯 Project Goal

The goal of DoseMate is to make medication management easier and more reliable through thoughtful UI/UX design, mobile development, cloud integration, and reminder functionality.

## 👨‍💻 Developer

**Ritvik Sharma**

GitHub: [@Ritvik-io](https://github.com/Ritvik-io)

## ⚠️ Disclaimer

DoseMate is a medication-management and reminder project, not a medical device or substitute for professional medical advice. Users should follow their healthcare professional's instructions. Reminder notifications may be delayed or unavailable depending on device settings and operating-system restrictions.

---

*Built with Flutter, Firebase, and Figma 💙*
