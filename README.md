# KidneyCalc

KidneyCalc is a SwiftUI iOS app that provides a curated set of nephrology calculators and reference formulas. It is designed for fast lookup, clear presentation, and easy expansion as new equations are added.

## Highlights

- Curated nephrology formulas grouped by category
- Dedicated calculator views for key equations
- Clean SwiftUI navigation with formula detail pages
- Simple, extensible model for adding new formulas

## Included Calculators

- CKD-EPI 2021 eGFR (race-free)
- Glucose correction for sodium
- Adrogue–Madias sodium prediction
- Free water deficit
- Corrected calcium
- Anion gap and delta–delta ratio
- Acid–base interpretation helpers
- Bicarbonate deficit

## Requirements

- macOS with Xcode installed
- iOS simulator or a connected iOS device

## Build and Run

1. Open KidneyCalc.xcodeproj in Xcode.
2. Select a simulator or device.
3. Run the app (Cmd+R).

## Project Structure

- KidneyCalc/
  - KidneyCalcApp.swift — app entry point
  - ContentView.swift — main list, categories, and navigation
  - Models/ — data models (Formula)
  - Views/ — calculator views and formula detail UI

## Adding a New Formula

1. Add a Formula to the placeholder list in ContentView.swift.
2. If a custom calculator view is needed, create it under Views/.
3. Wire the new view in FormulaDetailView.swift (see the name-based switch).
4. Optionally include equation, variables, and reference text for display.

## Medical Disclaimer

This app is for educational and reference purposes only. It does not provide medical advice, diagnosis, or treatment. Always use clinical judgment and consult authoritative sources.

## Privacy Policy

Nephro Calc is built with your privacy as a primary feature. I believe that a simple tool like a calculator shouldn't be a gateway for data collection.

No Data Collection: This application does not collect, store, or transmit any personal information, usage data, or mathematical input.

Offline First: All calculations are performed locally on your device. No data ever leaves your machine.

No Third-Party Tracking: There are no cookies, analytics, or third-party SDKs integrated into this project.

Transparency: You are free to review the source code here. 
