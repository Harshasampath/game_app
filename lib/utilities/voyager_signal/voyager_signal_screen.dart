import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'morse.dart';

class VoyagerSignalScreen extends StatefulWidget {
  const VoyagerSignalScreen({super.key});

  @override
  State<VoyagerSignalScreen> createState() => _VoyagerSignalScreenState();
}

class _VoyagerSignalScreenState extends State<VoyagerSignalScreen>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('game_app/voyager_torch');
  static const _gold = Color(0xFFFFD58A);
  static const _night = Color(0xFF090F1D);
  static const _presets = {
    'Voyager': 'VGR',
    'SOS': 'SOS',
    'Help': 'HELP',
    'Medical help': 'NEED MEDICAL HELP',
    'Need water': 'NEED WATER',
  };

  final _message = TextEditingController(text: 'VGR');
  bool _busy = false;
  bool _cleaning = false;
  bool _lit = false;
  bool _repeat = true;
  bool _flashlight = false;
  bool _available = false;
  bool _checking = true;
  bool _torchEngaged = false;
  int _generation = 0;
  int _completed = 0;
  int _countdown = 0;
  double _unitMs = 300;
  String _letter = '';
  String? _error;
  Timer? _timer;
  Completer<void>? _delay;

  bool get _locked => _busy || _checking || _cleaning;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_checkTorch());
  }

  Future<void> _checkTorch() async {
    var available = false;
    try {
      available = await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on PlatformException {
      // Screen signaling remains available when the camera is unavailable.
    } on MissingPluginException {
      // Desktop and web support screen signaling.
    }
    if (mounted) {
      setState(() {
        _available = available;
        _flashlight = available;
        _checking = false;
      });
    }
  }

  Future<void> _torch(bool enabled) async {
    if (enabled) _torchEngaged = true;
    await _channel.invokeMethod<void>('setTorch', {'enabled': enabled});
  }

  Future<void> _keepAwake(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setKeepAwake', {'enabled': enabled});
    } on MissingPluginException {
      // Not supported on desktop or web.
    } on PlatformException {
      // A wake-lock failure does not prevent a signal.
    }
  }

  Future<void> _releaseOutput() async {
    try {
      if (_torchEngaged) await _torch(false);
    } on PlatformException {
      // Native lifecycle cleanup also releases the torch.
    } on MissingPluginException {
      // No torch on this platform.
    } finally {
      _torchEngaged = false;
      await _keepAwake(false);
    }
  }

  Future<void> _wait(int milliseconds) {
    final delay = Completer<void>();
    _delay = delay;
    _timer = Timer(Duration(milliseconds: milliseconds), () {
      if (!delay.isCompleted) delay.complete();
    });
    return delay.future;
  }

  void _stop({bool updateUi = true}) {
    final generation = ++_generation;
    _timer?.cancel();
    if (_delay != null && !_delay!.isCompleted) _delay!.complete();
    if (mounted && updateUi) {
      setState(() {
        _busy = false;
        _cleaning = true;
        _lit = false;
        _countdown = 0;
        _letter = '';
      });
    }
    unawaited(_releaseOutput().whenComplete(() {
      if (mounted && updateUi && generation == _generation) {
        setState(() => _cleaning = false);
      }
    }));
  }

  bool _isCurrent(int generation) => mounted && generation == _generation;

  Future<void> _start() async {
    if (_locked) return;
    final message = normalizeMessage(_message.text);
    if (!isMorseMessage(message)) {
      setState(() => _error = 'Use letters A–Z, numbers, and spaces.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final generation = ++_generation;
    final pulses = encodeMorse(message);
    setState(() {
      _busy = true;
      _countdown = 3;
      _completed = 0;
      _error = null;
    });
    try {
      await _keepAwake(true);
      for (var second = 3; second > 0; second--) {
        if (!_isCurrent(generation)) return;
        setState(() => _countdown = second);
        await _wait(1000);
      }
      if (!_isCurrent(generation)) return;
      setState(() => _countdown = 0);
      do {
        for (final pulse in pulses) {
          if (!_isCurrent(generation)) return;
          if (_flashlight) await _torch(pulse.lit);
          if (!_isCurrent(generation)) return;
          setState(() {
            _lit = pulse.lit;
            _letter = pulse.letter;
          });
          await _wait((pulse.units * _unitMs).round());
        }
        if (!_isCurrent(generation)) return;
        if (_flashlight) await _torch(false);
        if (!_isCurrent(generation)) return;
        setState(() {
          _lit = false;
          _letter = '';
          _completed++;
        });
        if (!_repeat) break;
        await _wait((7 * _unitMs).round());
      } while (_isCurrent(generation));
    } on PlatformException catch (error) {
      if (_isCurrent(generation)) {
        setState(() {
          _error =
              '${error.message ?? 'Flashlight unavailable.'} Select screen light to continue.';
          _flashlight = false;
        });
      }
    } on MissingPluginException {
      if (_isCurrent(generation)) {
        setState(() {
          _error = 'Flashlight unavailable. Select screen light to continue.';
          _flashlight = false;
        });
      }
    } finally {
      if (_isCurrent(generation)) _stop();
    }
  }

  void _choosePreset(String message) {
    setState(() {
      _message.text = message;
      _error = null;
      _completed = 0;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _busy) _stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stop(updateUi: false);
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = normalizeMessage(_message.text);
    final valid = isMorseMessage(message);
    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        colorScheme:
            ColorScheme.fromSeed(seedColor: _gold, brightness: Brightness.dark),
        scaffoldBackgroundColor: _night,
        useMaterial3: true,
      ),
      child: Scaffold(
        appBar: AppBar(
            title: const Text('Voyager Signal'), backgroundColor: _night),
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                    children: [
                      const Row(children: [
                        Icon(Icons.satellite_alt_rounded,
                            color: _gold, size: 30),
                        SizedBox(width: 12),
                        Expanded(
                            child: Text('A LITTLE LIGHT. A LONG WAY.',
                                style: TextStyle(
                                    color: _gold,
                                    letterSpacing: 1.5,
                                    fontSize: 11))),
                      ]),
                      const SizedBox(height: 16),
                      const Text('Thank you, Voyager.',
                          style: TextStyle(
                              fontSize: 30, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                          'A symbolic greeting from Earth, one light-day away.',
                          style: TextStyle(color: Colors.white70, height: 1.5)),
                      const SizedBox(height: 24),
                      TextField(
                        key: const Key('signal-message'),
                        controller: _message,
                        enabled: !_locked,
                        maxLength: 80,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Your message',
                          helperText:
                              'VGR is prefilled. You can enter your own text.',
                          helperMaxLines: 2,
                          errorText: !valid && _message.text.isNotEmpty
                              ? 'Use letters A–Z, numbers, and spaces.'
                              : null,
                          errorMaxLines: 2,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {
                          _error = null;
                          _completed = 0;
                        }),
                      ),
                      const SizedBox(height: 4),
                      const Text('QUICK PRESETS',
                          style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _presets.entries
                            .map((preset) => ChoiceChip(
                                  label: Text(preset.key),
                                  selected: message == preset.value,
                                  onSelected: _locked
                                      ? null
                                      : (_) => _choosePreset(preset.value),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141E31),
                          borderRadius: BorderRadius.circular(18),
                          border:
                              Border.all(color: _gold.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('MORSE PREVIEW',
                                  style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                      letterSpacing: 1.5)),
                              const SizedBox(height: 8),
                              SelectableText(
                                  valid ? displayMorse(message) : '—',
                                  style: const TextStyle(
                                      color: _gold,
                                      fontSize: 24,
                                      letterSpacing: 3)),
                              const SizedBox(height: 6),
                              Text(
                                  message == 'SOS'
                                      ? 'SOS • three short, three long, three short'
                                      : 'Short flash = dot • Long flash = dash',
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 12)),
                            ]),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        key: const Key('start-signal'),
                        onPressed: _locked || !valid ? null : _start,
                        style: FilledButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: _night,
                          minimumSize: const Size.fromHeight(56),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(_checking
                            ? 'Checking flashlight…'
                            : 'Start signal'),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                          'A 3-second countdown gives you time to aim your light.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Colors.white60, fontSize: 12)),
                      if (_error != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: Colors.orangeAccent))),
                      const SizedBox(height: 20),
                      SegmentedButton<bool>(
                        segments: [
                          const ButtonSegment(
                              value: false,
                              label: Text('Screen light'),
                              icon: Icon(Icons.phone_android)),
                          ButtonSegment(
                              value: true,
                              label: const Text('Flashlight'),
                              icon: const Icon(Icons.flashlight_on),
                              enabled: _available),
                        ],
                        selected: {_flashlight},
                        onSelectionChanged: _locked
                            ? null
                            : (selection) =>
                                setState(() => _flashlight = selection.first),
                      ),
                      if (!_available && !_checking)
                        const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                                'No flashlight detected. Your screen can send the signal.',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 12))),
                      const SizedBox(height: 20),
                      Row(children: [
                        const Text('Dot duration'),
                        const Spacer(),
                        Text('${(_unitMs / 1000).toStringAsFixed(2)} s',
                            style: const TextStyle(color: Colors.white60)),
                      ]),
                      Slider(
                          value: _unitMs,
                          min: 200,
                          max: 600,
                          divisions: 8,
                          label: '${_unitMs.round()} ms',
                          onChanged: _locked
                              ? null
                              : (value) => setState(() => _unitMs = value)),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Repeat message'),
                        subtitle: Text(
                            '$_completed ${_completed == 1 ? 'message' : 'messages'} sent'),
                        value: _repeat,
                        onChanged: _locked
                            ? null
                            : (value) => setState(() => _repeat = value),
                      ),
                      const Divider(height: 32),
                      const Text('SHINE BRIGHT • NOVEMBER 17, 2026',
                          style: TextStyle(
                              color: _gold, fontSize: 11, letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      const Text(
                          'NASA invited everyone to flash VGR after sunset on November 17. '
                          'Voyager 1 reaches one light-day from Earth on November 18, 2026. '
                          'This is an independent tribute.',
                          style: TextStyle(
                              color: Colors.white60,
                              height: 1.5,
                              fontSize: 12)),
                      const SizedBox(height: 12),
                      const Text(
                          'Emergency presets are visual signals only; they do not contact '
                          'emergency services. Flashing lights may affect people with photosensitivity. '
                          'Leaving this screen or backgrounding the app stops the signal.',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              height: 1.5)),
                    ],
                  ),
                ),
              ),
              if (_busy) Positioned.fill(child: _transmissionView(message)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transmissionView(String message) {
    final bright = _lit && !_flashlight;
    final foreground = bright ? _night : _gold;
    return ColoredBox(
      color: bright ? _gold : _night,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Text(_countdown > 0 ? 'GET READY' : 'SENDING MORSE',
              style:
                  TextStyle(color: foreground, letterSpacing: 3, fontSize: 12)),
          Expanded(
              child: Center(
                  child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (_countdown > 0) ...[
                Semantics(
                    liveRegion: true,
                    child: Text('$_countdown',
                        key: const Key('signal-countdown'),
                        style: const TextStyle(
                            color: _gold,
                            fontSize: 112,
                            fontWeight: FontWeight.w300))),
                const Text('Aim your light. Your signal starts shortly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70)),
              ] else ...[
                Icon(
                    _flashlight ? Icons.flashlight_on : Icons.wb_sunny_outlined,
                    size: 64,
                    color: _lit ? foreground : Colors.white24),
                const SizedBox(height: 20),
                Text(_letter.isEmpty ? 'PAUSE' : _letter,
                    key: const Key('current-letter'),
                    style: TextStyle(
                        color: foreground,
                        fontSize: 48,
                        letterSpacing: 6,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                    '$_completed ${_completed == 1 ? 'message' : 'messages'} sent',
                    style: TextStyle(color: foreground)),
              ],
            ]),
          ))),
          Text(message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(color: foreground, letterSpacing: 2)),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('stop-signal'),
            onPressed: _stop,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25334C),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(Icons.stop_rounded),
            label: Text(_countdown > 0 ? 'Cancel countdown' : 'Stop signal'),
          ),
        ]),
      ),
    );
  }
}
