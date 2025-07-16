# 🛍️ Web Selling Chatbot (Flutter Frontend)

This is the Flutter frontend for an AI-powered e-commerce chatbot system. It connects to a FastAPI backend and provides a modern, cross-platform shopping experience with integrated AI chatbot support.

---

## 🚀 Features
- Product catalog & search
- Cart & order management
- AI chatbot (OpenAI GPT, context-aware)
- Admin dashboard for managing products, orders, and users
  
---

## 📋 Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0+ recommended)
- Dart (comes with Flutter)
- Android Studio or Xcode (for mobile builds)
- Chrome or Edge (for web builds)
- A running backend API (see [Backend Repo Link](https://github.com/ThanhAn-Tran/web_api_backend.git))

---

## 🏁 Getting Started

### 1. Clone the Repository
```bash
git clone <your-flutter-frontend-repo-link>
cd web_selling_chatbot
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Backend API Endpoint
- Open `lib/services/api_service.dart` (or the relevant service file).
- Update the base URL to point to your backend server (e.g., `http://localhost:8000` or your deployed backend URL).
- Example:
  ```dart
  // lib/services/api_service.dart
  const String baseUrl = 'http://localhost:8000';
  ```

---

## ▶️ Running the App

### For Web
```bash
flutter run -d chrome
```

### For Android
```bash
flutter run -d android
```

### For iOS
```bash
flutter run -d ios
```
> **Note:** For iOS, you need a Mac with Xcode installed.

### For Windows
```bash
flutter run -d windows
```

### For macOS
```bash
flutter run -d macos
```

### For Linux
```bash
flutter run -d linux
```

---

## 📦 Building for Production

### Web
```bash
flutter build web
```

### Android
```bash
flutter build apk
```

### iOS
```bash
flutter build ios
```

### Windows
```bash
flutter build windows
```

### macOS
```bash
flutter build macos
```

### Linux
```bash
flutter build linux
```

---

## 📁 Project Structure

- `lib/` – Main Flutter source code:
  - `main.dart` – App entry point
  - `models/` – Data models (cart, category, conversation, order, payment, product, user)
  - `providers/` – State management (auth, cart, chatbot, order, product)
  - `screens/` – UI screens (admin, cart, chatbot, checkout, home, login, orders, payment, product, profile, register)
  - `services/` – API and business logic (API, auth, cart, chatbot, checkout, order, payment, product)
  - `utils/` – Utilities and constants
  - `widgets/` – Reusable UI components
- `assets/` – Images and static assets
- Platform folders: `android/`, `ios/`, `web/`, `macos/`, `linux/`, `windows/`

---

## 🔗 Backend Connection
- Ensure your backend API is running and accessible.
- The frontend communicates with the backend for all core features.
- Update the API endpoint as described above to match your backend deployment.

---

## 🔗 Backend (FastAPI)
https://github.com/ThanhAn-Tran/web_api_backend.git

---

## 🎥 Demo

▶️ Watch the video demo here:  
[Smart Shopping Chatbot Demo – YouTube](https://youtube.com/shorts/YTPVJ-bAWgM?feature=share)
