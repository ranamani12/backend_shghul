# Shugal Mobile App

A Flutter mobile application for the Shugal job marketplace platform.

## Project Structure

```
mobile/
├── lib/
│   ├── theme/
│   │   └── app_theme.dart      # App theme configuration
│   └── main.dart               # App entry point
├── assets/
│   └── images/
│       └── logo.png            # App logo
└── pubspec.yaml                # Dependencies and assets
```

## Theme Colors

The app uses a consistent color palette based on the design:

- **Primary Color**: `#075056` (Dark Teal)
  - Used for headers, primary buttons, and navigation bars
  
- **Secondary Color**: `#DADADA` (Light Gray)
  - Used for secondary elements and chips
  
- **Body/Surface Color**: `#F5F5F5` (Very Light Gray)
  - Used for background and surface areas

- **Additional Colors**:
  - Text Primary: `#1A1A1A`
  - Text Secondary: `#666666`
  - Text Muted: `#999999`
  - Border Color: `#E0E0E0`
  - Success: `#10B981`
  - Error: `#EF4444`
  - Warning: `#F59E0B`

## Usage

### Using the Theme

The theme is automatically applied in `main.dart`. To use theme colors in your widgets:

```dart
import 'package:shugal/theme/app_theme.dart';

// Use theme colors
Container(
  color: AppTheme.primaryColor,
  child: Text(
    'Hello',
    style: TextStyle(color: AppTheme.white),
  ),
)
```

### Using Text Styles

```dart
import 'package:shugal/theme/app_theme.dart';

Text(
  'Heading',
  style: AppTextStyles.heading1,
)

Text(
  'Body text',
  style: AppTextStyles.body1,
)
```

### Using Theme in Widgets

```dart
// Access theme colors via context
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.surface
Theme.of(context).textTheme.headlineMedium
```

## Running the App

```bash
cd mobile
flutter pub get
flutter run
```

## Features

- ✅ Material Design 3
- ✅ Custom theme with brand colors
- ✅ Responsive design
- ✅ Ready for Arabic/English localization
- ✅ Logo asset configured

## Next Steps

1. Create screen widgets (Login, Register, Job List, etc.)
2. Set up API integration
3. Add state management (Provider/Riverpod/Bloc)
4. Implement navigation
5. Add localization support
