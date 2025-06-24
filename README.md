# 7-Day Nutrition Report

This iOS app collects deduplicated daily statistics from Apple Health for steps, active energy, carbs, proteins, fats, and calories over a user-selected date range, and exports the data as a CSV file for sharing.

## Features
- Fetches daily health and nutrition data from Apple Health
- Exports data as CSV for each day in the selected range
- Share the CSV file via the system share sheet
- SwiftUI interface, supports dark mode and dynamic type

## Requirements
- Xcode 15+
- iOS 17.0+
- Apple Health permissions (requested on first launch)

## Setup & Run
See [INSTALL.md](INSTALL.md) for build and run instructions.

## Build Artifacts (CI)
- On every tag push, GitHub Actions will build and export an `.ipa` artifact.

## Notes
- All data is read-only from Apple Health and never leaves your device unless you share the CSV.
- For any issues, please open a GitHub issue.

## 🌟 Features

- Tracks daily nutritional intake:
  - Carbohydrates (grams)
  - Proteins (grams)
  - Fats (grams)
  - Total Calories
- Tracks daily physical activity:
  - Steps taken
- Exports a report in CSV format.

## 🚀 Getting Started

*To be updated with installation/setup instructions.*

## 📋 How to Use

*To be updated with usage instructions.*

## 📊 Output File

The script generates a `nutrition_report.csv` file with the following columns:

| Column   | Description                               | Format    |
|----------|-------------------------------------------|-----------|
| `date`     | The date of the record.                   | `dd-MM-yy`  |
| `steps`    | The number of steps taken that day.       | Integer   |
| `carbs`    | Total carbohydrates consumed (in grams).  | Integer     |
| `proteins` | Total proteins consumed (in grams).       | Integer     |
| `fats`     | Total fats consumed (in grams).           | Integer     |
| `calories` | Total calories consumed.                  | Integer     |

---

## 📝 Future Enhancements

- Add activity energy expenditure tracking
  - Research and implement deduplication strategy for multiple data sources
  - Calculate calories burned from workouts and daily activities
- Add cloud data integration
  - Enable export to Google Sheets for data analysis
  - Add option to backup data to S3 or similar cloud storage
  - Build foundation for future data analytics capabilities