const morseAlphabet = <String, String>{
  'A': '.-',
  'B': '-...',
  'C': '-.-.',
  'D': '-..',
  'E': '.',
  'F': '..-.',
  'G': '--.',
  'H': '....',
  'I': '..',
  'J': '.---',
  'K': '-.-',
  'L': '.-..',
  'M': '--',
  'N': '-.',
  'O': '---',
  'P': '.--.',
  'Q': '--.-',
  'R': '.-.',
  'S': '...',
  'T': '-',
  'U': '..-',
  'V': '...-',
  'W': '.--',
  'X': '-..-',
  'Y': '-.--',
  'Z': '--..',
  '0': '-----',
  '1': '.----',
  '2': '..---',
  '3': '...--',
  '4': '....-',
  '5': '.....',
  '6': '-....',
  '7': '--...',
  '8': '---..',
  '9': '----.',
};

String normalizeMessage(String text) =>
    text.toUpperCase().trim().replaceAll(RegExp(r'\s+'), ' ');

bool isMorseMessage(String text) =>
    text.isNotEmpty && RegExp(r'^[A-Z0-9 ]+$').hasMatch(text);

String displayMorse(String text) {
  final message = normalizeMessage(text);
  // The distress signal SOS is a single continuous prosign.
  if (message == 'SOS') return '...---...';
  return message
      .split(' ')
      .map((word) => word
          .split('')
          .map((letter) => morseAlphabet[letter] ?? '?')
          .join(' '))
      .join(' / ');
}

class MorsePulse {
  const MorsePulse(this.lit, this.units, this.letter);
  final bool lit;
  final int units;
  final String letter;
}

/// Standard timing: dot 1, dash 3, element gap 1, letter gap 3, word gap 7.
List<MorsePulse> encodeMorse(String text) {
  final message = normalizeMessage(text);
  if (!isMorseMessage(message)) {
    throw const FormatException('Use letters A–Z, numbers, and spaces.');
  }
  final pulses = <MorsePulse>[];
  if (message == 'SOS') {
    _appendSymbols(pulses, '...---...', 'SOS');
    return pulses;
  }
  final words = message.split(' ');
  for (var w = 0; w < words.length; w++) {
    final letters = words[w].split('');
    for (var l = 0; l < letters.length; l++) {
      _appendSymbols(pulses, morseAlphabet[letters[l]]!, letters[l]);
      if (l < letters.length - 1) pulses.add(const MorsePulse(false, 3, ''));
    }
    if (w < words.length - 1) pulses.add(const MorsePulse(false, 7, ''));
  }
  return pulses;
}

void _appendSymbols(List<MorsePulse> pulses, String symbols, String letter) {
  for (var s = 0; s < symbols.length; s++) {
    pulses.add(MorsePulse(true, symbols[s] == '.' ? 1 : 3, letter));
    if (s < symbols.length - 1) pulses.add(MorsePulse(false, 1, letter));
  }
}
