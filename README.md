# Kanban Finance System

A Flutter app for tracking bank accounts, transactions and wealth on Kanban boards. Move transactions across status columns and see inflow, outflow and net flow at a glance.

A web version built with Next.js is in [Kanban-Finance-Web](https://github.com/DarkWizardCK-24/Kanban-Finance-Web). Both use the same Firebase project, so accounts and data stay in sync.

## Features

- **Authentication**: email and password login and registration with Firebase Auth.
- **Bank accounts**: add and edit accounts shown as gradient cards.
- **Transactions**: record credits and debits per account.
- **Kanban board**: drag transactions across stages to update their status.
- **Wealth summary**: inflow, outflow and net flow calculated from your transactions.
- **Profile management**, animated screens and a custom theme.

## Tech stack

- Flutter and Dart
- Firebase Auth and Cloud Firestore
- `flutter_animate`, `google_fonts`, `font_awesome_flutter`, `intl`, `uuid`

## Project structure

```
lib/
  models/      bank account, transaction and user models
  services/    auth_service, firestore_service
  screens/     auth, home, bank, kanban, profile
  widgets/     bank cards, wealth summary, kanban columns and cards
  utils/       formatters, validators, wealth_calculator
  constants/   colours, strings, theme
```

## Getting started

1. Install Flutter (Dart SDK 3.11 or newer).
2. Create a Firebase project with Email/Password auth and Firestore, then run `flutterfire configure` to generate `lib/firebase_options.dart`.
3. Run:

```bash
flutter pub get
flutter run
```
