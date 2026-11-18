import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/utilities/voyager_signal/morse.dart';
import 'package:game_app/utilities/voyager_signal/voyager_signal_screen.dart';

void main() {
  test('VGR uses correct marks and standard timing', () {
    expect(displayMorse('vgr'), '...- --. .-.');
    final pulses = encodeMorse('VGR');
    expect(pulses.where((p) => p.lit).map((p) => p.units),
        [1, 1, 1, 3, 3, 3, 1, 1, 3, 1]);
    expect(pulses.where((p) => !p.lit).map((p) => p.units),
        [1, 1, 1, 3, 1, 1, 3, 1, 1]);
    expect(pulses.fold<int>(0, (sum, pulse) => sum + pulse.units), 31);
  });

  test('SOS is a continuous distress signal', () {
    final pulses = encodeMorse('SOS');
    expect(displayMorse('sos'), '...---...');
    expect(pulses.where((p) => p.lit).map((p) => p.units),
        [1, 1, 1, 3, 3, 3, 1, 1, 1]);
    expect(pulses.where((p) => !p.lit).map((p) => p.units), everyElement(1));
  });

  test('custom messages normalize whitespace and reject unsupported input', () {
    expect(encodeMorse(' e   t ').map((p) => p.units), [1, 7, 3]);
    expect(displayMorse(' e   t '), '. / -');
    expect(displayMorse('0123456789'),
        '----- .---- ..--- ...-- ....- ..... -.... --... ---.. ----.');
    expect(() => encodeMorse('HI!'), throwsFormatException);
    expect(() => encodeMorse('  '), throwsFormatException);
  });

  const channel = MethodChannel('game_app/voyager_torch');
  final calls = <MethodCall>[];

  void mockTorch(WidgetTester tester,
      {bool available = true, bool fail = false}) {
    calls.clear();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      calls.add(call);
      if (call.method == 'isAvailable') return available;
      if (fail &&
          call.method == 'setTorch' &&
          (call.arguments as Map)['enabled'] == true) {
        throw PlatformException(code: 'BUSY', message: 'Camera is busy.');
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
  }

  List<MethodCall> torchOnCalls() => calls
      .where((call) =>
          call.method == 'setTorch' &&
          (call.arguments as Map)['enabled'] == true)
      .toList();

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: VoyagerSignalScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder, double delta) =>
      tester.scrollUntilVisible(finder, delta,
          scrollable: find.byType(Scrollable).first);

  Future<void> start(WidgetTester tester) async {
    await reveal(tester, find.byKey(const Key('start-signal')), 200);
    await tester.tap(find.byKey(const Key('start-signal')));
    await tester.pump();
  }

  Future<void> countdown(WidgetTester tester) async {
    for (var second = 0; second < 3; second++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  testWidgets('prefills VGR, edits custom text, and selects emergency presets',
      (tester) async {
    mockTorch(tester);
    await mount(tester);
    final field = find.byKey(const Key('signal-message'));
    final controller = tester.widget<TextField>(field).controller!;
    expect(controller.text, 'VGR');
    await tester.enterText(field, 'hello 2');
    await tester.pump();
    await reveal(tester, find.text('.... . .-.. .-.. --- / ..---'), 100);
    expect(find.text('.... . .-.. .-.. --- / ..---'), findsOneWidget);
    await reveal(tester, find.widgetWithText(ChoiceChip, 'SOS'), -100);
    await tester.tap(find.widgetWithText(ChoiceChip, 'SOS'));
    await tester.pump();
    expect(controller.text, 'SOS');
    expect(find.text('...---...'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Medical help'));
    await tester.pump();
    expect(controller.text, 'NEED MEDICAL HELP');
    await reveal(tester, field, -200);
    await tester.enterText(field, '🙂');
    await tester.pump();
    await reveal(tester, find.byKey(const Key('start-signal')), 200);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('start-signal')))
            .onPressed,
        isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
      'counts 3–2–1 before the first flashlight pulse and stops immediately',
      (tester) async {
    mockTorch(tester);
    await mount(tester);
    await start(tester);
    expect(find.text('3'), findsOneWidget);
    expect(torchOnCalls(), isEmpty);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);
    expect(torchOnCalls(), isEmpty);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1'), findsOneWidget);
    expect(torchOnCalls(), isEmpty);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('V'), findsOneWidget);
    expect(torchOnCalls(), hasLength(1));
    await tester.tap(find.byKey(const Key('stop-signal')));
    await tester.pumpAndSettle();
    final count = torchOnCalls().length;
    await tester.pump(const Duration(seconds: 20));
    expect(torchOnCalls(), hasLength(count));
    expect(find.byKey(const Key('stop-signal')), findsNothing);
    expect(calls.where((call) => call.method == 'setTorch').last.arguments,
        {'enabled': false});
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
      'canceling the countdown never turns on the torch, including after restart',
      (tester) async {
    mockTorch(tester);
    await mount(tester);
    await start(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('stop-signal')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));
    expect(torchOnCalls(), isEmpty);
    await start(tester);
    expect(find.text('3'), findsOneWidget);
    await countdown(tester);
    expect(torchOnCalls(), hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('backgrounding during countdown cancels the signal',
      (tester) async {
    mockTorch(tester);
    await mount(tester);
    await start(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    expect(torchOnCalls(), isEmpty);
    expect(find.byKey(const Key('stop-signal')), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('countdown and stop controls fit a small landscape screen',
      (tester) async {
    tester.view.physicalSize = const Size(640, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    mockTorch(tester);
    await mount(tester);
    await start(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('stop-signal')).hitTestable(), findsOneWidget);
    await countdown(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('stop-signal')).hitTestable(), findsOneWidget);
    await tester.tap(find.byKey(const Key('stop-signal')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
      'screen fallback completes a custom one-shot message without torch calls',
      (tester) async {
    mockTorch(tester, available: false);
    await mount(tester);
    await tester.enterText(find.byKey(const Key('signal-message')), 'E');
    await reveal(tester, find.byType(SwitchListTile), 300);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('start-signal')), -200);
    await tester.tap(find.byKey(const Key('start-signal')));
    await tester.pump();
    await countdown(tester);
    expect(find.text('E'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stop-signal')), findsNothing);
    expect(torchOnCalls(), isEmpty);
    await reveal(tester, find.byType(SwitchListTile), 200);
    expect(find.text('1 message sent'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('flashlight errors stop signaling and offer screen mode',
      (tester) async {
    mockTorch(tester, fail: true);
    await mount(tester);
    await start(tester);
    await countdown(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stop-signal')), findsNothing);
    await reveal(tester,
        find.text('Camera is busy. Select screen light to continue.'), 100);
    expect(find.text('Camera is busy. Select screen light to continue.'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
