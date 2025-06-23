# Installation & Run Guide

## 1. Clone the repository
```
git clone https://github.com/yourusername/7-day-nutrition-report.git
cd 7-day-nutrition-report
```

## 2. Open in Xcode
- Open `7-day-nutrition-report.xcodeproj` in Xcode 15 or newer.

## 3. Configure Capabilities
- Enable the **HealthKit** capability in your project settings.
- Add the following keys to your `Info.plist` with appropriate descriptions:
  - `NSHealthShareUsageDescription`
  - `NSHealthUpdateUsageDescription`

## 4. Build & Run
- Select your device (not a simulator, as HealthKit requires a real device).
- Build and run the app.

## 5. Grant Permissions
- On first launch, grant Health permissions for:
  - Steps
  - Active energy
  - Carbs
  - Proteins
  - Fats
  - Calories

## 6. Use the App
- Select a date range and tap **Fetch Data**.
- Tap **Export CSV** to generate and share the CSV file.

## Troubleshooting
- If you encounter issues with HealthKit permissions, check your device's Health app settings.
- For any other issues, please open a GitHub issue. 