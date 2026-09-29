# ♻️ SecondLife

### Give Materials a Second Life

SecondLife is a circular-economy platform that connects people who have reusable or unwanted materials with people who need them.

Instead of letting useful materials become waste, SecondLife allows users to **list materials they have, discover materials they need, and request them from other users**.

## 🌱 Problem

Many reusable materials are discarded simply because the owner no longer needs them, while someone else may be looking for the same material.

SecondLife aims to bridge this gap by creating a simple platform for **reuse, exchange, and responsible resource management**.

## 💡 Solution

SecondLife provides two main user flows:

* **I Have** – List materials that you want to give away or sell.
* **I Need** – Search for available materials and send requests to their owners.

The platform also provides request tracking so users can monitor the status of their requests.

## ✨ Key Features

### 📦 I Have

* Add reusable materials
* Upload material images
* Specify item name and quantity
* Add location
* Set free or paid availability
* View previously added materials
* Track incoming requests

### 🔎 I Need

* Browse available materials
* Search for required materials
* View material details
* Send requests to material owners
* Track submitted requests
* View request status

### 📋 Request Tracking

Users can track requests throughout the exchange process:

**Pending → Accepted / Rejected → Completed**

## 🛠️ Technology Stack

* **Frontend:** Flutter
* **Backend:** Firebase
* **Authentication:** Firebase Authentication
* **Database:** Cloud Firestore
* **Platform:** Android / Web
* **Language:** Dart

## 🏗️ Project Structure

```text
secondlife/
├── android/
├── assets/
├── ios/
├── lib/
│   ├── firebase_options.dart
│   └── ...
├── web/
├── windows/
├── pubspec.yaml
└── README.md
```

## 🚀 Getting Started

### Prerequisites

Make sure you have:

* Flutter SDK
* Dart SDK
* Android Studio or VS Code
* Firebase project
* Android device or emulator

### Installation

Clone the repository:

```bash
git clone https://github.com/cgopika/secondlife.git
```

Navigate to the project:

```bash
cd secondlife
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

## 🔥 Firebase

SecondLife uses Firebase for:

* User authentication
* Material data storage
* Request management
* Real-time data synchronization

Firebase configuration files are required to run the application correctly.

## 🎯 Project Goal

The goal of SecondLife is to encourage the **reuse of materials, reduce unnecessary waste, and connect available resources with people who need them** through a simple digital platform.

## 👩‍💻 Project

**SecondLife – Circular Economy Platform**

Developed as a student/hackathon project.

---



