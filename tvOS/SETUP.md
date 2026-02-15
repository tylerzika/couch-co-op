# tvOS Xcode Project Setup Guide

This directory contains the source files for the tvOS app. Due to the complexity of Xcode project files (.pbxproj), this guide explains how to create the project structure.

## Steps to Create tvOS Project

### Option 1: Using Xcode (Requires macOS)

1. Open Xcode on your Mac
2. Create a new project: File → New → Project
3. Select tvOS → App
4. Configure the project:
   - Product Name: couch-co-op
   - Team ID: (your team, or None for personal)
   - Organization Identifier: com.example (customize as needed)
   - Interface: SwiftUI
   - Life Cycle: SwiftUI

5. Copy the AppDelegate.swift and ContentView.swift files from this directory to the Xcode project

6. Add the MathLibSwift package reference:
   - File → Add Packages
   - Enter the path to your Swift package (Swift/MathLibSwift)
   - Select your app target and add the dependency

### Option 2: Using Swift Package Manager + Xcode

1. Create a Swift package that includes tvOS targets
2. Use `swift build -Xswiftc -target -Xswiftc tvos` to target tvOS

## Project Structure

```
tvOS/
├── couch-co-op/
│   ├── AppDelegate.swift         # App entry point and setup
│   └── ContentView.swift         # Main UI (SwiftUI)
└── SETUP.md                      # This file
```

## Dependencies

The tvOS app depends on:
- **MathLibSwift**: Located in ../Swift/
- **UIKit**: Apple framework
- **SwiftUI**: Apple framework

## Building on Mac

Once the project is created in Xcode:

```bash
# Build for tvOS simulator
xcodebuild -scheme couch-co-op \
          -configuration Debug \
          -sdk appletvsimulator \
          -derivedDataPath ./DerivedData

# Build for tvOS device
xcodebuild -scheme couch-co-op \
          -configuration Release \
          -sdk appletvos \
          -derivedDataPath ./DerivedData
```

## Linking the C Library from tvOS

The tvOS app uses the Swift package (MathLibSwift) which already wraps the C library. The linking happens through:

1. vOS app → MathLibSwift (Swift package)
2. MathLibSwift → CMathLib (C module)
3. CMathLib → C/libmath_lib.a (compiled C library)

This indirect linking is necessary because Xcode on macOS must build for tvOS, and the C library needs to be compiled with tvOS SDK.

## Building C Library for tvOS

If you need to rebuild the C library for tvOS (on macOS):

```bash
cd C/build
cmake -DCMAKE_SYSTEM_NAME=tvOS \
      -DCMAKE_OSX_SYSROOT=appletvsimulator \
      ..
make
```

Or for tvOS device:
```bash
cmake -DCMAKE_SYSTEM_NAME=tvOS \
      -DCMAKE_OSX_SYSROOT=appletvos \
      ..
make
```

## Important Notes

- **Xcode Required**: tvOS app development requires macOS and Xcode. This devcontainer is for Linux and cannot directly build tvOS apps.
- **Cross-Development**: Use this Linux environment for C library development and Swift Package Manager development, then sync with Mac for final tvOS integration.
- **Module Mapping**: The modulemap in CMathLib ensures proper C-Swift interoperability.
