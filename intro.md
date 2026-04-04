# News Lab — Flutter + Firebase + BLoC

## Steps to go live

### 1. Create a Firebase project
- Go to [console.firebase.google.com](https://console.firebase.google.com)
- Create a new project (e.g. `news-lab`)
- Enable **Authentication** → Sign-in method → Email/Password
- Enable **Firestore Database** (start in test mode)
- Enable **Storage**

### 2. Connect Firebase to the Flutter app
```bash
cd frontend
dart pub global activate flutterfire_cli
flutterfire configure
```
Then update `main.dart`:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

### 3. Set your Firebase project ID
Edit [backend/.firebaserc](backend/.firebaserc) — replace `YOUR_FIREBASE_PROJECT_ID`.

### 4. Deploy Firestore & Storage rules
```bash
cd backend
npm install -g firebase-tools
firebase login
firebase deploy
```

### 5. Run the code generator
```bash
cd frontend
flutter pub run build_runner build --delete-conflicting-outputs
```

### 6. Create a test journalist account
Firebase Console → Authentication → Add user (email + password).

### 7. Run the app
```bash
cd frontend
flutter run
```
