# 7-Day Nutrition Report

A Shortcut to generate a 7-day nutrition and activity report.
Latest version of shortcut you can find in **Releases**

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