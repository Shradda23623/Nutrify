# Contributing to Nutrify

Thanks for your interest in contributing. This document covers how to file issues, propose changes, and get a development environment running.

## Reporting issues

Before opening a new issue, please search [existing issues](https://github.com/Shradda23623/Nutrify/issues) to avoid duplicates. When you do open one, use the appropriate template (Bug Report or Feature Request) and include:

- A clear, specific title
- For bugs: device model, Android/iOS version, app version, exact steps to reproduce, expected vs actual behavior, and screenshots or stack traces if available
- For features: the user problem you're trying to solve, not just the proposed solution

## Proposing code changes

For anything beyond a typo or one-line fix, please **open an issue first** and let's agree on the approach before you spend time on a PR. This avoids the situation where someone writes a feature that doesn't fit the project's direction.

Workflow once we've agreed on the change:

1. Fork the repo and create a topic branch off `main`. Use a descriptive branch name like `feature/recipe-builder` or `fix/scanner-permission-ios`.
2. Make your changes. Keep commits small and focused; one logical change per commit. Write commit messages in the imperative mood ("Add recipe builder", not "Added recipe builder").
3. Run the local checks before pushing — see "Development setup" below.
4. Open a pull request against `main`. Reference the issue number in the PR description (`Closes #42`).
5. Be ready to iterate. Reviews are about the code, not the contributor.

## Development setup

```bash
# 1. Clone and install
git clone https://github.com/Shradda23623/Nutrify.git
cd Nutrify
flutter pub get

# 2. Configure your own Firebase project (the keys in this repo are mine)
dart pub global activate flutterfire_cli
flutterfire configure

# 3. Run on a connected device or emulator
flutter run
```

Required Firebase services: Authentication (Email/Password + Google), Cloud Firestore, Storage, Cloud Messaging.

## Code quality checklist

Before opening a PR, please run all of these locally and make sure they pass:

```bash
flutter analyze        # static analysis
flutter test           # unit tests
dart format .          # code formatting
```

CI runs the same commands. PRs that fail CI will not be merged until they're green.

When adding features:

- Follow the existing folder layout (`lib/features/<feature>/{models,screens,widgets,services}/`).
- Prefer small, focused widgets over deeply nested build methods.
- Put pure business logic in `models/` so it can be unit-tested without the widget tree (see `test/widget_test.dart` for examples).
- Keep one feature's code inside its feature folder; cross-feature code goes in `lib/core/`.

## What does *not* belong in this repo

- Generated build artifacts (`build/`, `.dart_tool/`, IDE config) — already in `.gitignore`.
- Service-account JSON files or other Firebase admin credentials.
- Personal screenshots, notes, or local debug data.

## Code of conduct

Be respectful. Disagree with code, not people. Reviewers and contributors are putting in their time for free; thank them for it.

## Questions

Email shradda141@gmail.com or open a discussion on the repo.
