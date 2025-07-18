// lib/main.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_app/screens/game_screen.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MiniGamesApp());
}

class MiniGamesApp extends StatelessWidget {
  const MiniGamesApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FlutterNativeSplash.remove();
    return MaterialApp(
      title: 'Mini Games Collection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      home: const GamesList(),
    );
  }
}

class GamesList extends StatelessWidget {
  const GamesList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final games = [
      {'name': 'Tic Tac Toe', 'widget': const TicTacToeGame()},
      {'name': 'Memory Cards', 'widget': const MemoryGame()},
      {'name': 'Number Puzzels', 'widget': const NumberPuzzleGame()},
      {'name': 'Word Scramble', 'widget': const WordScrambleGame()},
      {'name': 'Color Memory Matching', 'widget': const ColorMemoryGame()},
      {'name': 'Obstacle Dodger', 'widget': const ObstacleDodger()},
      {'name': 'Bubble Shooter Game', 'widget': const BubbleShooterGame()},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Games Collection'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: games.length,
        itemBuilder: (context, index) {
          return GameCard(
            title: games[index]['name'] as String,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => games[index]['widget'] as Widget),
            ),
          );
        },
      ),
    );
  }
}

class GameCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const GameCard({
    Key? key,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [Colors.blue.shade300, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

// lib/games/tic_tac_toe.dart
class TicTacToeGame extends StatefulWidget {
  const TicTacToeGame({Key? key}) : super(key: key);

  @override
  _TicTacToeGameState createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  List<String> board = List.filled(9, '');
  bool xTurn = true;
  String winner = '';

  void _onTileTap(int index) {
    if (board[index].isEmpty && winner.isEmpty) {
      setState(() {
        board[index] = xTurn ? 'X' : 'O';
        xTurn = !xTurn;
        _checkWinner();
      });
    }
  }

  void _checkWinner() {
    // Winning combinations
    final lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6], // Diagonals
    ];

    for (final line in lines) {
      if (board[line[0]].isNotEmpty && board[line[0]] == board[line[1]] && board[line[0]] == board[line[2]]) {
        setState(() {
          winner = board[line[0]];
        });
        return;
      }
    }
  }

  void _resetGame() {
    setState(() {
      board = List.filled(9, '');
      xTurn = true;
      winner = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tic Tac Toe')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (winner.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Winner: $winner',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _onTileTap(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      board[index],
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _resetGame,
            child: const Text('Reset Game'),
          ),
        ],
      ),
    );
  }
}

// lib/games/memory_game.dart
class MemoryGame extends StatefulWidget {
  const MemoryGame({Key? key}) : super(key: key);

  @override
  _MemoryGameState createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  List<String> items = [];
  List<bool> flipped = [];
  List<int> matched = [];
  int? firstChoice;
  bool canFlip = true;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    items = List.from(['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼'])
      ..addAll(['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼'])
      ..shuffle();
    flipped = List.filled(16, false);
    matched = [];
    firstChoice = null;
    canFlip = true;
  }

  void _onTileClick(int index) {
    if (!canFlip || flipped[index] || matched.contains(index)) return;

    setState(() {
      flipped[index] = true;

      if (firstChoice == null) {
        firstChoice = index;
      } else {
        canFlip = false;
        if (items[firstChoice!] == items[index]) {
          matched.addAll([firstChoice!, index]);
          firstChoice = null;
          canFlip = true;
        } else {
          Future.delayed(const Duration(milliseconds: 1000), () {
            setState(() {
              flipped[firstChoice!] = false;
              flipped[index] = false;
              firstChoice = null;
              canFlip = true;
            });
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory Game')),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _onTileClick(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: matched.contains(index)
                          ? Colors.green.shade100
                          : flipped[index]
                              ? Colors.white
                              : Colors.blue.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        flipped[index] || matched.contains(index) ? items[index] : '',
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _initializeGame();
                });
              },
              child: const Text('Reset Game'),
            ),
          ),
        ],
      ),
    );
  }
}

class NumberPuzzleGame extends StatefulWidget {
  const NumberPuzzleGame({Key? key}) : super(key: key);

  @override
  _NumberPuzzleGameState createState() => _NumberPuzzleGameState();
}

class _NumberPuzzleGameState extends State<NumberPuzzleGame> {
  late List<int?> board;
  int moves = 0;
  bool isComplete = false;
  final int gridSize = 4;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  void _initializeBoard() {
    // Create solved board first
    board = List.generate(15, (index) => index + 1);
    board.add(null); // Add empty space

    // Shuffle board
    final random = Random();
    for (int i = board.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1);
      var temp = board[i];
      board[i] = board[j];
      board[j] = temp;
    }

    // Reset game state
    moves = 0;
    isComplete = false;

    // Ensure puzzle is solvable
    if (!_isSolvable()) {
      // Swap first two numbers if puzzle is not solvable
      var temp = board[0];
      board[0] = board[1];
      board[1] = temp;
    }
  }

  bool _isSolvable() {
    int inversions = 0;
    int emptyRowFromBottom = gridSize - (board.indexOf(null) ~/ gridSize);

    for (int i = 0; i < board.length - 1; i++) {
      if (board[i] == null) continue;
      for (int j = i + 1; j < board.length; j++) {
        if (board[j] != null && board[i]! > board[j]!) {
          inversions++;
        }
      }
    }

    if (gridSize.isOdd) {
      return inversions.isEven;
    } else {
      return (inversions + emptyRowFromBottom).isEven;
    }
  }

  void _onTileTap(int index) {
    if (isComplete) return;

    final emptyIndex = board.indexOf(null);
    if (_canMove(index, emptyIndex)) {
      setState(() {
        // Swap tiles
        final temp = board[index];
        board[index] = board[emptyIndex];
        board[emptyIndex] = temp;
        moves++;

        // Check if puzzle is solved
        isComplete = _checkWin();
      });
    }
  }

  bool _canMove(int tileIndex, int emptyIndex) {
    // Check if tile is adjacent to empty space
    final tileRow = tileIndex ~/ gridSize;
    final tileCol = tileIndex % gridSize;
    final emptyRow = emptyIndex ~/ gridSize;
    final emptyCol = emptyIndex % gridSize;

    return (tileRow == emptyRow && (tileCol - emptyCol).abs() == 1) || (tileCol == emptyCol && (tileRow - emptyRow).abs() == 1);
  }

  bool _checkWin() {
    for (int i = 0; i < board.length - 1; i++) {
      if (board[i] != i + 1) return false;
    }
    return board.last == null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Number Puzzle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _initializeBoard();
              });
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Moves: $moves',
            style: const TextStyle(fontSize: 24),
          ),
          if (isComplete)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Puzzle Completed!',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridSize,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: board.length,
                  itemBuilder: (context, index) {
                    return board[index] == null
                        ? const SizedBox()
                        : NumberTile(
                            number: board[index]!,
                            onTap: () => _onTileTap(index),
                          );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _initializeBoard();
                });
              },
              child: const Text('New Game'),
            ),
          ),
        ],
      ),
    );
  }
}

class NumberTile extends StatelessWidget {
  final int number;
  final VoidCallback onTap;

  const NumberTile({
    Key? key,
    required this.number,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.blue.shade300,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            number.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class WordScrambleGame extends StatefulWidget {
  const WordScrambleGame({Key? key}) : super(key: key);

  @override
  _WordScrambleGameState createState() => _WordScrambleGameState();
}

class _WordScrambleGameState extends State<WordScrambleGame> {
  final List<String> wordList = [
    'FLUTTER',
    'DART',
    'MOBILE',
    'WIDGET',
    'SCREEN',
    'PHONE',
    'TABLET',
    'CODING',
    'DEVELOPER',
    'SOFTWARE',
    'GAME',
    'PUZZLE',
    'PLAYER',
    'SCORE',
    'LEVEL'
  ];

  late String currentWord;
  late String scrambledWord;
  late List<String> letterTiles;
  List<String> selectedLetters = [];
  int score = 0;
  int attempts = 0;
  bool isCorrect = false;
  final TextEditingController guessController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  @override
  void dispose() {
    guessController.dispose();
    super.dispose();
  }

  void _newGame() {
    // Select random word
    final random = Random();
    currentWord = wordList[random.nextInt(wordList.length)];

    // Scramble the word
    List<String> letters = currentWord.split('');
    letters.shuffle();
    while (letters.join() == currentWord) {
      letters.shuffle(); // Ensure word is actually scrambled
    }
    scrambledWord = letters.join();

    // Create letter tiles
    letterTiles = scrambledWord.split('');
    selectedLetters = [];
    isCorrect = false;
    guessController.clear();

    setState(() {});
  }

  void _selectLetter(String letter, int index) {
    if (!selectedLetters.contains(letter + index.toString())) {
      setState(() {
        selectedLetters.add(letter + index.toString());
        guessController.text = selectedLetters.map((e) => e.substring(0, 1)).join();
      });
    }
  }

  void _unselectLetter(String letterWithIndex) {
    setState(() {
      selectedLetters.remove(letterWithIndex);
      guessController.text = selectedLetters.map((e) => e.substring(0, 1)).join();
    });
  }

  void _checkGuess() {
    String guess = guessController.text.toUpperCase();
    setState(() {
      attempts++;
      if (guess == currentWord) {
        score += 10;
        isCorrect = true;
        _showSuccessDialog();
      } else {
        score = max(0, score - 2); // Penalty for wrong guess
        _showErrorDialog();
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Correct!'),
        content: Text('You found the word: $currentWord'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _newGame();
            },
            child: const Text('Next Word'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Try Again'),
        content: const Text('That\'s not the correct word.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHint() {
    setState(() {
      score = max(0, score - 5); // Penalty for using hint
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hint'),
        content: Text('The first letter is: ${currentWord[0]}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Scramble'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: _showHint,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _newGame,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Score: $score', style: const TextStyle(fontSize: 20)),
                Text('Attempts: $attempts', style: const TextStyle(fontSize: 20)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Unscramble the word:',
              style: TextStyle(fontSize: 18),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: letterTiles.length,
              itemBuilder: (context, index) {
                String letterWithIndex = letterTiles[index] + index.toString();
                bool isSelected = selectedLetters.contains(letterWithIndex);
                return LetterTile(
                  letter: letterTiles[index],
                  isSelected: isSelected,
                  onTap: () {
                    if (isSelected) {
                      _unselectLetter(letterWithIndex);
                    } else {
                      _selectLetter(letterTiles[index], index);
                    }
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: guessController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Your Guess',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      guessController.clear();
                      selectedLetters.clear();
                    });
                  },
                ),
              ),
              readOnly: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: guessController.text.isNotEmpty ? _checkGuess : null,
              child: const Text('Check Answer'),
            ),
          ),
        ],
      ),
    );
  }
}

class LetterTile extends StatelessWidget {
  final String letter;
  final bool isSelected;
  final VoidCallback onTap;

  const LetterTile({
    Key? key,
    required this.letter,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade300 : Colors.blue.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.blue.shade300,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.grey : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class ColorMemoryGame extends StatefulWidget {
  const ColorMemoryGame({Key? key}) : super(key: key);

  @override
  _ColorMemoryGameState createState() => _ColorMemoryGameState();
}

class _ColorMemoryGameState extends State<ColorMemoryGame> {
  final List<Color> _allColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
  ];

  late List<Color> _randomColors; // Colors to memorize
  late List<Color?> _userChoices; // User's selected colors
  bool _isShowingColors = true; // Controls whether colors are shown or hidden
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      _randomColors = (_allColors.toList()..shuffle()).sublist(0, 4);
      _userChoices = List<Color?>.filled(4, null);
      _isShowingColors = true;
      _score = 0;
    });

    // Hide the colors after a delay of 3 seconds
    Timer(const Duration(seconds: 3), () {
      setState(() {
        _isShowingColors = false;
      });
    });
  }

  void _selectColor(Color color, int index) {
    if (_userChoices[index] == null) {
      setState(() {
        _userChoices[index] = color;

        // Check if the user's choice matches the correct color
        if (_userChoices[index] == _randomColors[index]) {
          _score++;
        }
      });
    }
  }

  bool _isGameComplete() {
    return _userChoices.every((color) => color != null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Memory Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startNewGame,
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isShowingColors)
            const Text(
              'Memorize the colors!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            )
          else if (!_isGameComplete())
            const Text(
              'Select the colors in the correct order!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            )
          else
            Text(
              'Game Over! Your Score: $_score / 4',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 20),
          // Display the colors to memorize or the user's choices
          GridView.builder(
            padding: EdgeInsets.all(5),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _randomColors.length,
            itemBuilder: (context, index) {
              return Container(
                color: _isShowingColors ? _randomColors[index] : _userChoices[index] ?? Colors.grey.shade300,
                alignment: Alignment.center,
                child: Text(
                  _isShowingColors
                      ? '${index + 1}' // Show index during memorization
                      : _userChoices[index] != null
                          ? '✓' // Show checkmark for selected tiles
                          : '#',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          if (!_isShowingColors && !_isGameComplete())
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: _allColors.map((color) {
                return GestureDetector(
                  onTap: () {
                    if (!_isGameComplete()) {
                      final emptyIndex = _userChoices.indexWhere((choice) => choice == null);
                      if (emptyIndex != -1) {
                        _selectColor(color, emptyIndex);
                      }
                    }
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    color: color,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class ObstacleDodger extends StatefulWidget {
  const ObstacleDodger({Key? key}) : super(key: key);

  @override
  _ObstacleDodgerState createState() => _ObstacleDodgerState();
}

class _ObstacleDodgerState extends State<ObstacleDodger> {
  static const playerSize = 50.0;
  static const obstacleWidth = 60.0;
  static const obstacleGap = 200.0;

  late double _playerX;
  late double _screenWidth;
  late double _screenHeight;

  List<Obstacle> _obstacles = [];
  Timer? _gameTimer;
  double _score = 0;
  bool _isPlaying = false;
  bool _gameOver = false;

  // Game settings
  double _gameSpeed = 3.0;
  final double _accelerationFactor = 0.2;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenWidth = MediaQuery.of(context).size.width;
      _screenHeight = MediaQuery.of(context).size.height;
      _playerX = _screenWidth / 2 - playerSize / 2;
      setState(() {});
    });
  }

  void _startGame() {
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
      _gameOver = false;
      _score = 0;
      _gameSpeed = 3.0;
      _obstacles.clear();
      _playerX = _screenWidth / 2 - playerSize / 2;
    });

    // Start game loop
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateGame();
    });

    // Start gyroscope listening
    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      if (_isPlaying) {
        setState(() {
          _playerX += event.x * 5;
          // Keep player within bounds
          _playerX = _playerX.clamp(0, _screenWidth - playerSize);
        });
      }
    });
  }

  void _updateGame() {
    if (!_isPlaying) return;

    setState(() {
      // Move obstacles
      for (var obstacle in _obstacles) {
        obstacle.y += _gameSpeed;
      }

      // Remove off-screen obstacles
      _obstacles.removeWhere((obstacle) => obstacle.y > _screenHeight);

      // Add new obstacles
      if (_obstacles.isEmpty || _obstacles.last.y > obstacleGap) {
        _addNewObstacle();
      }

      // Update score
      _score += 0.1;

      // Increase game speed
      _gameSpeed += _accelerationFactor * 0.01;

      // Check collisions
      if (_checkCollisions()) {
        _gameOver = true;
        _endGame();
      }
    });
  }

  void _addNewObstacle() {
    final random = Random();
    final obstacleX = random.nextDouble() * (_screenWidth - obstacleWidth);
    _obstacles.add(Obstacle(x: obstacleX, y: -50));
  }

  bool _checkCollisions() {
    final playerRect = Rect.fromLTWH(_playerX, _screenHeight - 100, playerSize, playerSize);

    for (var obstacle in _obstacles) {
      final obstacleRect = Rect.fromLTWH(obstacle.x, obstacle.y, obstacleWidth, obstacleWidth);

      if (playerRect.overlaps(obstacleRect)) {
        return true;
      }
    }
    return false;
  }

  void _endGame() {
    _isPlaying = false;
    _gameTimer?.cancel();
    _gyroscopeSubscription?.cancel();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _gyroscopeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (_isPlaying) {
            setState(() {
              _playerX += details.delta.dx;
              _playerX = _playerX.clamp(0, _screenWidth - playerSize);
            });
          }
        },
        child: Container(
          color: Colors.blue[100],
          child: Stack(
            children: [
              // Score
              Positioned(
                top: 50,
                right: 20,
                child: Text(
                  'Score: ${_score.toInt()}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Obstacles
              if (_screenWidth != null)
                ..._obstacles.map((obstacle) => Positioned(
                      left: obstacle.x,
                      top: obstacle.y,
                      child: Container(
                        width: obstacleWidth,
                        height: obstacleWidth,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )),

              // Player
              if (_screenWidth != null)
                Positioned(
                  left: _playerX,
                  bottom: 50,
                  child: Container(
                    width: playerSize,
                    height: playerSize,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),

              // Start/Game Over overlay
              if (!_isPlaying)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_gameOver)
                          Text(
                            'Game Over!\nScore: ${_score.toInt()}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _startGame,
                          child: Text(
                            _gameOver ? 'Play Again' : 'Start Game',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class Obstacle {
  double x;
  double y;

  Obstacle({required this.x, required this.y});
}

class BubbleShooterGame extends StatefulWidget {
  const BubbleShooterGame({Key? key}) : super(key: key);

  @override
  _BubbleShooterGameState createState() => _BubbleShooterGameState();
}

class _BubbleShooterGameState extends State<BubbleShooterGame> {
  static const bubbleSize = 40.0;
  static const shooterSize = 50.0;
  final List<Color> bubbleColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
  ];

  List<Bubble> _bubbles = [];
  double _shooterX = 0.0;
  double _screenWidth = 0.0;
  double _screenHeight = 0.0;
  Color _currentBubbleColor = Colors.red;
  List<Bubble> _shootingBubbles = [];
  int _score = 0;
  bool _isPlaying = false;
  Timer? _gameTimer;
  bool _isInitialized = false;

  // Aiming line variables
  double? _aimX;
  double? _aimY;
  bool _isAiming = false;

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _initializeGame() {
    if (!_isInitialized) {
      _screenWidth = MediaQuery.of(context).size.width;
      _screenHeight = MediaQuery.of(context).size.height;
      _shooterX = _screenWidth / 2 - shooterSize / 2;
      _isInitialized = true;
    }

    _bubbles = [];
    _shootingBubbles = [];
    _score = 0;

    // Create initial bubble grid
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < (_screenWidth / bubbleSize).floor(); col++) {
        _bubbles.add(
          Bubble(
            x: col * bubbleSize,
            y: row * bubbleSize,
            color: bubbleColors[Random().nextInt(bubbleColors.length)],
          ),
        );
      }
    }

    _currentBubbleColor = bubbleColors[Random().nextInt(bubbleColors.length)];
  }

  void _startGame() {
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
      _initializeGame();
    });

    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateGame();
    });
  }

  void _updateGame() {
    if (!_isPlaying) return;

    final bubblestoRemove = <Bubble>[];
    final List<Bubble> newBubbles = [];

    setState(() {
      for (final bubble in List<Bubble>.from(_shootingBubbles)) {
        bubble.y += bubble.dy;
        bubble.x += bubble.dx;

        // Check wall collisions
        if (bubble.x <= 0 || bubble.x >= _screenWidth - bubbleSize) {
          bubble.dx *= -1;
        }

        // Check collision with existing bubbles
        bool hasCollided = false;
        for (final existingBubble in _bubbles) {
          if (_checkCollision(bubble, existingBubble)) {
            final newBubble = _handleCollision(bubble);
            if (newBubble != null) {
              newBubbles.add(newBubble);
            }
            bubblestoRemove.add(bubble);
            hasCollided = true;
            break;
          }
        }

        // Check ceiling collision
        if (bubble.y <= 0) {
          final newBubble = Bubble(
            x: bubble.x,
            y: 0,
            color: bubble.color,
          );
          newBubbles.add(newBubble);
          bubblestoRemove.add(bubble);
        }

        // Remove if off screen sides
        if (bubble.y > _screenHeight || hasCollided) {
          bubblestoRemove.add(bubble);
        }
      }

      _shootingBubbles.removeWhere((b) => bubblestoRemove.contains(b));
      _bubbles.addAll(newBubbles);

      if (_bubbles.any((bubble) => bubble.y > _screenHeight - 100)) {
        _endGame();
      }
    });
  }

  bool _checkCollision(Bubble b1, Bubble b2) {
    final dx = b1.x - b2.x;
    final dy = b1.y - b2.y;
    final distance = sqrt(dx * dx + dy * dy);
    return distance < bubbleSize;
  }

  Bubble? _handleCollision(Bubble shootingBubble) {
    final newBubble = Bubble(
      x: (shootingBubble.x / bubbleSize).round() * bubbleSize,
      y: (shootingBubble.y / bubbleSize).round() * bubbleSize,
      color: shootingBubble.color,
    );

    final matches = _findMatches(newBubble);
    if (matches.length >= 3) {
      setState(() {
        _bubbles.removeWhere((b) => matches.contains(b));
        _score += matches.length * 10;
      });
      return null;
    }

    for (var bubble in _bubbles) {
      bubble.y += bubbleSize / 4;
    }

    _currentBubbleColor = bubbleColors[Random().nextInt(bubbleColors.length)];
    return newBubble;
  }

  List<Bubble> _findMatches(Bubble startBubble) {
    final matches = <Bubble>[startBubble];
    final toCheck = <Bubble>[startBubble];

    while (toCheck.isNotEmpty) {
      final bubble = toCheck.removeLast();
      final neighbors = _bubbles.where((b) {
        return b.color == bubble.color && !matches.contains(b) && _checkCollision(bubble, b);
      }).toList();

      matches.addAll(neighbors);
      toCheck.addAll(neighbors);
    }

    return matches;
  }

  void _shootBubble() {
    if (_shootingBubbles.length >= 3 || !_isAiming) return;

    final shooterCenterX = _shooterX + shooterSize / 2;
    final shooterCenterY = _screenHeight - 100;

    // Calculate angle and velocity
    final dx = _aimX! - shooterCenterX;
    final dy = _aimY! - shooterCenterY;
    final angle = atan2(dy, dx);

    const velocity = 10.0;
    final bubble = Bubble(
      x: shooterCenterX - bubbleSize / 2,
      y: shooterCenterY - bubbleSize / 2,
      color: _currentBubbleColor,
      dx: velocity * cos(angle),
      dy: velocity * sin(angle),
    );

    setState(() {
      _shootingBubbles.add(bubble);
      _isAiming = false;
      _aimX = null;
      _aimY = null;
    });
  }

  void _updateAimPosition(Offset position) {
    if (!_isPlaying) return;

    setState(() {
      _isAiming = true;
      _aimX = position.dx;
      _aimY = position.dy;
    });
  }

  void _endGame() {
    _isPlaying = false;
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      _initializeGame();
    }

    return Scaffold(
      body: GestureDetector(
        onPanStart: (details) => _updateAimPosition(details.localPosition),
        onPanUpdate: (details) => _updateAimPosition(details.localPosition),
        onPanEnd: (_) => _shootBubble(),
        child: Container(
          color: Colors.black87,
          child: Stack(
            children: [
              // Score
              Positioned(
                top: 50,
                right: 20,
                child: Text(
                  'Score: $_score',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Existing bubbles
              ..._bubbles.map((bubble) => Positioned(
                    left: bubble.x,
                    top: bubble.y,
                    child: Container(
                      width: bubbleSize,
                      height: bubbleSize,
                      decoration: BoxDecoration(
                        color: bubble.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )),

              // Shooting bubbles
              ..._shootingBubbles.map((bubble) => Positioned(
                    left: bubble.x,
                    top: bubble.y,
                    child: Container(
                      width: bubbleSize,
                      height: bubbleSize,
                      decoration: BoxDecoration(
                        color: bubble.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )),

              // Aim line
              if (_isAiming && _isPlaying)
                CustomPaint(
                  size: Size.infinite,
                  painter: AimLinePainter(
                    start: Offset(_shooterX + shooterSize / 2, _screenHeight - 100),
                    end: Offset(_aimX!, _aimY!),
                  ),
                ),

              // Shooter
              Positioned(
                left: _shooterX,
                bottom: 50,
                child: Column(
                  children: [
                    Container(
                      width: bubbleSize,
                      height: bubbleSize,
                      decoration: BoxDecoration(
                        color: _currentBubbleColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: shooterSize,
                      height: shooterSize,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ],
                ),
              ),

              // Start overlay
              if (!_isPlaying)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Score: $_score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _startGame,
                          child: const Text(
                            'Start Game',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class Bubble {
  double x;
  double y;
  final Color color;
  double dx;
  double dy;

  Bubble({
    required this.x,
    required this.y,
    required this.color,
    this.dx = 0,
    this.dy = 0,
  });
}

class AimLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;

  AimLinePainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(AimLinePainter oldDelegate) {
    return start != oldDelegate.start || end != oldDelegate.end;
  }
}

class CartRacingGame extends StatelessWidget {
  const CartRacingGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: RacingGameScreen(),
    );
  }
}

class RacingGameScreen extends StatefulWidget {
  const RacingGameScreen({super.key});

  @override
  _RacingGameScreenState createState() => _RacingGameScreenState();
}

class _RacingGameScreenState extends State<RacingGameScreen> {
  // Player car properties
  double carX = 0.0; // Car position (-1: left, 0: center, 1: right)
  final double carWidth = 70;
  final double carHeight = 100;

  // Obstacles
  List<Offset> obstacles = [];
  final double obstacleSpeed = 10; // Speed of obstacles
  Timer? gameLoop;

  // Game state
  bool isGameOver = false;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  @override
  void dispose() {
    gameLoop?.cancel();
    super.dispose();
  }

  void startGame() {
    gameLoop = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (isGameOver) return;

      setState(() {
        moveObstacles();
        checkCollision();
        spawnObstacles();
      });
    });
  }

  void moveLeft() {
    setState(() {
      if (carX > -1) carX -= 1; // Move left within bounds
    });
  }

  void moveRight() {
    setState(() {
      if (carX < 1) carX += 1; // Move right within bounds
    });
  }

  void moveObstacles() {
    // Move all obstacles down
    for (int i = 0; i < obstacles.length; i++) {
      obstacles[i] = Offset(obstacles[i].dx, obstacles[i].dy + obstacleSpeed);
    }

    // Remove obstacles that move off-screen
    obstacles.removeWhere((obs) => obs.dy > MediaQuery.of(context).size.height);
  }

  void spawnObstacles() {
    if (obstacles.isEmpty || obstacles.last.dy > 200) {
      // Randomly choose a lane (-1, 0, 1)
      int lane = [-1, 0, 1][DateTime.now().millisecondsSinceEpoch % 3];
      obstacles.add(Offset(lane.toDouble(), -100));
    }
  }

  void checkCollision() {
    for (var obs in obstacles) {
      // Check if obstacle overlaps with the player's car
      double obsLeft = MediaQuery.of(context).size.width / 2 + (obs.dx * 100) - carWidth / 2;
      double obsRight = obsLeft + carWidth;
      double obsTop = obs.dy;
      double obsBottom = obs.dy + carHeight;

      double carLeft = MediaQuery.of(context).size.width / 2 + (carX * 100) - carWidth / 2;
      double carRight = carLeft + carWidth;
      double carTop = MediaQuery.of(context).size.height - carHeight - 50;
      double carBottom = carTop + carHeight;

      if (obsBottom > carTop && obsTop < carBottom && obsLeft < carRight && obsRight > carLeft) {
        gameOver();
      }
    }
  }

  void gameOver() {
    setState(() {
      isGameOver = true;
      gameLoop?.cancel();
    });
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Game Over!"),
        content: const Text("You crashed into an obstacle."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              restartGame();
            },
            child: const Text("Restart"),
          ),
        ],
      ),
    );
  }

  void restartGame() {
    setState(() {
      isGameOver = false;
      carX = 0.0;
      obstacles.clear();
      startGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            moveRight();
          } else {
            moveLeft();
          }
        },
        child: Container(
          color: Colors.grey[800],
          child: Stack(
            children: [
              // Road
              Positioned.fill(
                child: CustomPaint(
                  painter: RoadPainter(),
                ),
              ),
              // Obstacles
              for (var obs in obstacles)
                Positioned(
                  top: obs.dy,
                  left: MediaQuery.of(context).size.width / 2 + (obs.dx * 100) - carWidth / 2,
                  child: Container(
                    width: carWidth,
                    height: carHeight,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              // Player Car
              Positioned(
                bottom: 50,
                left: MediaQuery.of(context).size.width / 2 + (carX * 100) - carWidth / 2,
                child: Container(
                  width: carWidth,
                  height: carHeight,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (isGameOver)
                const Center(
                  child: Text(
                    "Game Over",
                    style: TextStyle(fontSize: 36, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Road lanes
    paint.color = Colors.white;
    double laneWidth = 4;
    double laneHeight = 40;
    for (double i = 0; i < size.height; i += 80) {
      canvas.drawRect(Rect.fromLTWH(size.width / 2 - 100 - laneWidth / 2, i, laneWidth, laneHeight), paint);
      canvas.drawRect(Rect.fromLTWH(size.width / 2 - laneWidth / 2, i, laneWidth, laneHeight), paint);
      canvas.drawRect(Rect.fromLTWH(size.width / 2 + 100 - laneWidth / 2, i, laneWidth, laneHeight), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
