# Trace

A native iOS app that overlays a reference photo on top of your camera feed, so you can trace it onto paper by hand.

## What it does

Trace uses your device's rear camera as a live viewfinder. You pick a photo from your library and it appears as a translucent overlay on the camera feed. Adjust the position, scale, rotation, and opacity of the overlay until it lines up with your paper, then draw.

## Requirements

- **Xcode** 15 or later
- **iOS** 16.0 or later
- A **physical iPhone or iPad** to use the camera (the simulator has no camera feed)

## Running the app

1. In Xcode, select your device from the run destination menu
2. Set your development team under **Signing & Capabilities** (required to run on a physical device)
3. Press **Run** (⌘R)

On first launch, the app will ask for camera permission. The photo picker uses the system Photos UI and does not require a separate permission prompt.

## How to use

| Action | What it does |
|---|---|
| **Tap "Choose Photo"** | Opens the system photo picker |
| **Drag** the overlay | Moves it around the screen |
| **Pinch** the overlay | Scales it up or down |
| **Two-finger rotate** the overlay | Rotates it freely |
| **Opacity slider** | Adjusts how transparent the overlay is |
| **↺ Reset** | Snaps the overlay back to center at its original size and rotation |
| **Lock button** | Freezes the overlay in place so it won't shift while you draw; turns yellow when active |
| **Tap anywhere** | Hides or shows the controls |
