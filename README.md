# 🌐 REE — Social Media App

A modern and interactive **Social Media Application** built with **Flutter** for the frontend, powered by a flexible backend of your choice (Firebase / REST API), and designed with clean, modular architecture.
Created to deliver a smooth posting, sharing, and discovery experience across platforms.

---

## ✨ Features

* 📝 Create & share posts instantly
* 🏠 Personalized home feed
* 🔐 Secure authentication
* 📁 Media-ready architecture (images, videos)
* 🎨 Beautiful, responsive UI with Flutter
* ⚡ Smooth navigation & performance
* 💾 Persistent local storage
* 🧹 Clean, scalable, and modular codebase

---

## 📱 Screenshots

|            Login Screen            |         Home Feed Screen         |             Profile Screen             |
| :--------------------------------: | :------------------------------: | :------------------------------------: |
| ![Login](assets/screens/login.png) | ![Feed](assets/screens/feed.png) | ![Profile](assets/screens/profile.png) |

---

## 🛠️ Built With

* **Flutter** — Cross-platform app framework
* **NodeJS REST Framework** — Backend API
* **GetX** — State Management & Routing
* **SharedPreferences** — Local storage
* **Dart** — Frontend programming language
---

## 🧩 Architecture Overview

```plaintext
lib/
├── controllers/      # State management controllers
├── models/           # Models: User, Post
├── services/         # API service, auth service, storage service
├── views/            # UI screens & widgets (Feed, Profile, Login, etc.)
├── utils/            # Themes, constants, helpers
└── main.dart         # App entry point
```

## 🚀 Getting Started

Follow these simple steps to run the project:

### 1. **Clone the repository**

```bash
git clone https://github.com/S4K1L/REE-Social-Media.git
cd REE-Social-Media
```

### 2. **Install Flutter dependencies**

```bash
flutter pub get
```

### 3. **Configure Backend**

#### ** REST API (Node)**

* Setup your API
* Add base URL to `services/api_service.dart`

### 4. **Run the App**

```bash
flutter run
```

---

## 🔑 Environment Configuration

* Store API keys / Firebase configs securely
* Use `.env` or `flutter_dotenv` for sensitive values
* For REST API, configure endpoints in one place for easy maintenance

---

## 📈 Future Improvements

* 💬 Direct messaging
* 🎥 Video posts & reels
* 🔔 Push notifications
* 📊 Analytics dashboard (optional admin)

---

## 🤝 Contributing

Contributions are welcome! 🎉
Fork the repository, create a feature branch, and submit a pull request.

```bash
# Create a feature branch
git checkout -b feature/YourFeature

# Commit your changes
git commit -m 'Add some feature'

# Push your branch
git push origin feature/YourFeature
```

---

## 📄 License

This project is licensed under the **MIT License**.

---

## 💬 Connect with Me

* GitHub: [https://github.com/S4K1L](https://github.com/S4K1L)
---

> **Crafted with ❤️ using Flutter and a clean modern architecture.**

---
