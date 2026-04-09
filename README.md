# TrainingApp

## Supabase config

The app now reads Supabase settings from Dart defines instead of hardcoded values in source.

1. Create a local file named `supabase.env.json` in the project root.
2. Copy the structure from `supabase.env.example.json`.
3. Fill in your real Supabase project URL and anon key.

Example run command:

```bash
flutter run --dart-define-from-file=supabase.env.json
```

Example debug build:

```bash
flutter build apk --debug --dart-define-from-file=supabase.env.json
```