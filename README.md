# game_app

A new Flutter project.

## Voyager Signal

Open **Voyager Signal** from the collection to blink Morse code with the phone's
flashlight, or use screen light on devices without one. The message starts as
`VGR`; replace it with letters A–Z, numbers, and spaces (up to 80 characters).

Choose a preset for Voyager, SOS, Help, Medical help, or Need water. SOS uses the
continuous `...---...` distress signal. Preview the Morse code, choose the output,
adjust dot duration or repeat, then tap **Start signal**. A cancelable three-second
countdown runs before the first flash. **Stop signal**, leaving the screen, or
backgrounding the app cancels transmission and releases the flashlight and
mobile screen-awake setting. Emergency presets only flash a visual message;
they do not contact emergency services.

Android and iOS use a native method channel for torch control. Other platforms
offer screen light. Verify flashlight operation on a physical device; simulators
cannot validate the hardware output.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
