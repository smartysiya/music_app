# music_app

A new Flutter project.

## Configuration

This project requires API keys to function properly. Copy `.env.example` to `.env` in the project root and fill in your keys:

```bash
cp .env.example .env
```

Then edit `.env`:

```env
YOUTUBE_API_KEY=your_youtube_api_key_here
LASTFM_API_KEY=your_lastfm_api_key_here
```

The app loads these at runtime via `flutter_dotenv`. No extra flags are needed — just run:

```bash
flutter run
```

> **⚠️ Important:** Never commit your `.env` file. It is already listed in `.gitignore`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
