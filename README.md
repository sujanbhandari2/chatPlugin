# Health Chat Mobile (Flutter)

Production-ready mobile chat client (Android + iOS) for the existing backend in this repository.

## Stack

- Flutter 3.35+
- Riverpod (state management)
- Dio (HTTP)
- GoRouter (navigation)
- Socket.IO client (real-time messaging)
- Shared Preferences (session persistence)
- Firebase Core + Firebase Messaging (push notifications)
- Image Picker / File Picker / Record (media)

## Features

- Username + password `register` and `login`
- Persistent session until explicit logout
- Conversation list with unread/new message badge
- Global conversation and direct user-to-user conversations
- Real-time events:
  - `message_received`
  - `message_reacted`
  - `message_deleted`
  - `message_read`
- Send message types:
  - Text
  - Image upload
  - Voice file upload
  - Voice record + send
- React to messages (emoji)
- Soft delete messages
- Read receipt trigger (`mark_as_read`)
- Online users panel (presence refresh)
- Push notifications:
  - FCM token auto-register on authenticated session
  - FCM token refresh sync to backend
  - FCM token unregister on logout
  - Foreground message snack alerts
  - Notification tap routing to target conversation

## Architecture

Feature-first clean architecture with separated layers:

```text
lib/
  app/
    app.dart
    router/app_router.dart
  core/
    config/app_config.dart
    models/app_role.dart
    network/
      dio_client.dart
      socket_client.dart
    storage/session_storage.dart
    push/
      push_notification_service.dart
      push_token_api.dart
    theme/app_theme.dart
  features/
    auth/
      data/
      domain/
      presentation/
    chat/
      data/
      domain/
      presentation/
  shared/widgets/
```

### Module responsibilities

- `auth`:
  - handles register/login
  - stores/loads session from local storage
- `chat`:
  - API + socket integrations
  - chat state orchestration
  - unread tracking and conversation selection
- `core`:
  - transport config
  - app-wide theme/config
  - persistence utilities

## Backend contract used

- REST:
  - `POST /api/auth/register`
  - `POST /api/auth/login`
  - `GET /api/users`
  - `GET /api/conversations`
  - `GET /api/conversations/:id/messages?page=1&pageSize=50`
  - `POST /api/conversations`
  - `POST /api/upload`
  - `POST /api/users/push-token`
  - `DELETE /api/users/push-token`
- Socket:
  - emit: `join_conversation`, `send_message`, `react_to_message`, `delete_message`, `mark_as_read`
  - listen: `message_received`, `message_reacted`, `message_deleted`, `message_read`

## Local setup

1. Start backend stack from repo root:
   - `./run-dev.sh`
2. Install mobile deps:
   - `cd mobile_app`
   - `flutter pub get`
3. Run app:
   - iOS simulator: `flutter run`
   - Android emulator: `flutter run`

## Push notification setup

1. Flutter Firebase config is already wired (`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`).
2. Configure backend Firebase service-account env values:
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_CLIENT_EMAIL`
   - `FIREBASE_PRIVATE_KEY` (escaped newlines)
3. Restart backend after setting env values.

## API endpoint configuration

Default behavior:

- Android emulator uses `http://10.0.2.2:4000`
- iOS simulator uses `http://localhost:4000`

Override via `dart-define`:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://<YOUR_HOST>:4000/api \
  --dart-define=SOCKET_URL=http://<YOUR_HOST>:4000
```

## Quality checks

- `flutter analyze`
- `flutter test`

Both pass in current implementation.
