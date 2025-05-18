# Toffee Tube

A Flutter app that displays YouTube trending videos with a clean Material UI, supporting both mobile (Android) and desktop platforms (Windows, macOS, Linux). The app adapts its UI layout to mimic Android on mobile and YouTube's desktop website on desktop.

---

## Features

- Fetches trending YouTube videos using web scraping (no official API)
- Responsive UI with:
  - List view on mobile (Android style)
  - Grid/List view on desktop mimicking YouTube website layout
- Supports light and dark themes with Material 3 design system
- Video cards show thumbnails, titles, channel info, view count, and publish time
- Context menu on videos (share, open in browser)
- Cross-platform: runs on Android and Desktop (Windows, macOS, Linux)

---

## Screenshots

*(Add your app screenshots here for light/dark mode, mobile and desktop views)*

---

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio or VSCode (recommended for development)
- Supported desktop platform setup (Windows, Linux, macOS) if building for desktop

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/toffee_tube.git
   cd toffee_tube
    ```
2. Get dependencies:
```bash
flutter pub get
```
3. Run the app:
For Android:
```bash
flutter run
```
For Desktop:
```bash
        flutter run -d windows
        flutter run -d macos
        flutter run -d linux
```

## Notes

    This app scrapes YouTube and is not endorsed by YouTube.

    Uses Material 3 design for consistent modern UI.

    Thumbnail size and layout adapt depending on platform.

## Contributing

Feel free to open issues or submit pull requests. Please keep contributions clean and maintainable.
License

## Licensing 
This project is licensed under the MIT License - see the LICENSE file for details.