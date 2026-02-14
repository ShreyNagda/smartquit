# BreatheFree V2

A smart smoking cessation companion app built with Flutter, designed to help users quit smoking through evidence-based interventions, progress tracking, and community support.

## Features

### 🆘 Panic Button

The centerpiece of the app — a pulsating emergency button that instantly launches a random intervention when cravings strike. Provides immediate distraction and support exactly when needed.

### 🧘 10 Evidence-Based Interventions

1. **Box Breathing** — Haptic-guided 4-4-4-4 breathing rhythm to calm the nervous system
2. **5-4-3-2-1 Grounding** — Interactive sensory awareness exercise (5 things you see, 4 you hear, etc.)
3. **Guided Visualization** — 2-minute audio-visual journey to build a mental "safe space"
4. **Positive Reframing** — CBT-based affirmation card deck for cognitive restructuring
5. **Whack-a-Crave** — Fast-paced tap game to redirect motor energy
6. **Quick Sketch** — 60-second doodling canvas to occupy hands
7. **Memory Match** — Nature-themed 4x4 card flip game for cognitive distraction
8. **Water Prompt** — Interactive hydration reminder with physical substitution benefits
9. **Craving Surfing** — Mindfulness-based urge observation technique
10. **Progress Reflection** — Review achievements and milestones for motivation

### 📊 Progress Dashboard

- **Smoke-Free Timer** — Real-time counter showing days, hours, and minutes since quitting
- **Money Saved** — Track savings in ₹ (rupees) based on cigarettes not smoked
- **Cigarettes Avoided** — Running count of cigarettes you didn't smoke
- **Health Milestones** — Visual timeline of body recovery (20 min, 8 hrs, 24 hrs, etc.)

### 📈 Statistics & Analytics

- Daily, weekly, and monthly craving patterns
- Intervention effectiveness tracking
- Success rate visualization
- Streak tracking and personal records

### ⚙️ Personalization

#### Intervention Preferences

- Select your preferred interventions (minimum 3)
- Panic button only launches from your selected set
- Easily update preferences in Settings

#### User Settings

- Haptic feedback toggle
- Notification preferences
- Currency display (₹)
- Profile customization

### 🔔 Smart Notifications

- Motivational reminders
- Milestone celebrations
- Craving pattern-based alerts
- Customizable notification schedule

### 📱 Android Home Screen Widget

- **1x1 Panic Widget** — Quick access to interventions right from your home screen
- Transparent adaptive background
- Launches random intervention on tap
- Native Android widget with Material You support

### 🔐 Authentication

- Google Sign-In integration
- Firebase Authentication
- Secure cloud sync of progress data

### 💾 Data & Sync

- Cloud backup via Firebase Firestore
- Real-time sync across devices
- Offline support with local caching

### 🎨 Design

- Material Design 3
- Custom green wellness theme
- Montserrat typography
- Smooth animations throughout
- Dark mode support (coming soon)

## Tech Stack

- **Framework:** Flutter 3.2+
- **State Management:** Riverpod
- **Backend:** Firebase (Auth, Firestore, Analytics, Messaging)
- **Authentication:** Google Sign-In
- **Local Storage:** Shared Preferences
- **Audio:** audioplayers
- **Haptics:** haptic_feedback
- **Charts:** fl_chart
- **Animations:** flutter_animate, Lottie

## Getting Started

### Prerequisites

- Flutter SDK >= 3.2.0
- Dart SDK >= 3.2.0
- Android Studio / VS Code
- Firebase project configured

### Installation

1. Clone the repository

```bash
git clone https://github.com/yourusername/breathe-free.git
cd breathe-free/companion
```

2. Install dependencies

```bash
flutter pub get
```

3. Configure Firebase
   - Add your `google-services.json` to `android/app/`
   - Add your `GoogleService-Info.plist` to `ios/Runner/`

4. Run the app

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user_model.dart
│   └── intervention_model.dart
├── providers/                # Riverpod providers
│   ├── user_provider.dart
│   └── intervention_provider.dart
├── screens/                  # UI screens
│   ├── splash_screen.dart
│   ├── home/
│   ├── onboarding/
│   ├── interventions/        # 10 intervention screens
│   └── settings/
├── services/                 # Business logic
│   └── haptic_service.dart
├── theme/                    # App theming
│   └── app_theme.dart
└── widgets/                  # Reusable components
    └── panic_button.dart
```

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Evidence-based intervention techniques from cognitive behavioral therapy (CBT)
- Mindfulness-based stress reduction (MBSR) principles
- WHO guidelines for smoking cessation

---

**BreatheFree** — _Every breath is a victory_ 🌿
