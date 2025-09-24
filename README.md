MoneyBase
Personal Finance Management App
Download on Google PLay

# moneybase

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

### Environment configuration

Copy `.env.example` to `.env` in the project root and add your Gemini API key:

```
GEMINI_API_KEY=your-google-gemini-api-key
```

The assistant reads this configuration at launch. Keep the `.env` file out of
version control to protect your credentials.

To hydrate `.env` from CI or Vercel environment variables, run the helper
script. It copies `GEMINI_API_KEY` (or `VERCEL_GEMINI_API_KEY`) from the current
process environment into the file:

```
dart run tools/create_env.dart
```

Pass a custom output path if you need to emit the environment file elsewhere:

```
dart run tools/create_env.dart /tmp/output.env
```

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
