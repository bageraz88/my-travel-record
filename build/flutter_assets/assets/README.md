<p align="center">
  <img src="assets/app_icon.png" width="120" height="120" alt="My Travel Record Logo">
</p>

<h1 align="center">My Travel Record</h1>

<p align="center">
  <strong>Capture your journeys, preserve your memories.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Material_3-6750A4?style=for-the-badge&logo=materialdesign&logoColor=white" alt="Material 3">
  <img src="https://img.shields.io/badge/PWA-Ready-orange?style=for-the-badge&logo=pwa&logoColor=white" alt="PWA Ready">
</p>

---

## 🌟 Overview

**My Travel Record** is a professional-grade Flutter application built to help you document every step of your adventures. Whether you're a casual tourist or a hardcore explorer, this app provides the tools to log trip details, capture photos, and export professional reports—all while keeping your data private and local.

---

## ✨ Key Features

### 📝 Smart Logging
- **Detailed Records**: Log place names, specific timestamps, and distance values.
- **Trip Types**: Categorize movements by **Departure** or **Arrival**.
- **Intuitive UI**: Built on **Material 3** for a fluid, modern experience.

### 📸 Visual Memories
- **Photo Attachments**: Snap a photo or pick from your gallery to accompany any record.
- **Square Cropping**: Built-in editor to ensure your travel gallery looks perfectly uniform.
- **Interactive Viewer**: Pinch-to-zoom and pan your saved photos in high definition.
- **Global Sharing**: Share your travel photos directly to other apps (WhatsApp, Drive, etc.) on both Mobile and Web.

### 📊 Versatile Exports
- **CSV Support**: Generate data-rich spreadsheets for deep analysis or cloud backup.
- **PDF Generation**: Create beautiful, shareable travel summaries with one tap.
- **Timed Naming**: Exports are automatically timestamped (e.g., `travel_records_20260525_153000.pdf`).

### 🔒 Privacy & Performance
- **Cross-Platform Persistence**: Powered by **Hive (NoSQL)**, your data is stored locally on-device or in IndexedDB for Web.
- **PWA Ready**: Runs seamlessly on Android and as a high-performance, installable Web App.
- **Adaptive Theme**: Automatically adapts to your system's **Light** or **Dark** mode settings.
- **Accessibility**: Comprehensive screen reader support and optimized touch targets.

---

## 🏗️ Technical Stack

| Category | Technology |
| :--- | :--- |
| **Core** | Flutter / Dart |
| **Database** | Hive (Cross-platform Local Storage) |
| **UI Framework** | Material 3 (Indigo Seed) |
| **Imaging** | Image Picker & Image Cropper |
| **Reporting** | PDF Widgets & Printing Service |
| **Markdown** | Flutter Markdown (for About section) |

---

## 📁 Project Map

- `lib/main.dart` - The heart of the application logic and main views.
- `lib/splash_screen.dart` - Animated themed entry experience.
- `lib/main_record_tile.dart` - Specialized, accessible UI component for record list items.
- `assets/` - High-quality graphical resources and documentation.

---

## 📦 Build & Release

The project is optimized for production-grade performance.

- **For Mobile**: Signed and shrunk APKs with ABI splitting (~21MB for modern devices).
- **For Web**: Fully responsive PWA with offline storage persistence.

---

## 👤 Author

**Meor Shukri**
*Crafted with ❤️ in 2026*

---
<p align="center">
  <i>This project is open-source and licensed under the MIT License.</i>
</p>
