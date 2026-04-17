import 'dart:math';
import 'package:flutter/material.dart';
import 'game.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: GamePage()),
      ),
    );
  }
}

class Tile extends StatelessWidget {
  const Tile(this.letter, this.hitType, {super.key});

  final String letter;
  final HitType hitType;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.bounceIn,
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        color: switch (hitType) {
          HitType.hit => Colors.green,
          HitType.partial => Colors.yellow,
          HitType.miss => Colors.grey,
          _ => Colors.white,
        },
      ),
      child: Center(
        child: Text(
          letter.toUpperCase(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

// ─── Easter Egg: Estrela caindo ───────────────────────────────────────────────

class FallingStar extends StatelessWidget {
  const FallingStar({
    super.key,
    required this.controller,
    required this.index,
  });

  final AnimationController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    final random = Random(index * 137);
    final startX = random.nextDouble();
    final size = 14.0 + random.nextDouble() * 18;
    final delay = random.nextDouble() * 0.6;
    final emoji = ['✨', '⭐', '💜', '🍎'][index % 4];

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final raw = controller.value - delay;
        final progress = (raw / (1.0 - delay)).clamp(0.0, 1.0);
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;

        double opacity;
        if (progress < 0.15) {
          opacity = progress / 0.15;
        } else if (progress > 0.85) {
          opacity = (1.0 - progress) / 0.15;
        } else {
          opacity = 1.0;
        }

        return Positioned(
          left: startX * screenWidth,
          top: -size + progress * (screenHeight + size * 2),
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Text(emoji, style: TextStyle(fontSize: size)),
          ),
        );
      },
    );
  }
}

// ─── GamePage ─────────────────────────────────────────────────────────────────

class GamePage extends StatefulWidget {
  GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  final Game _game = Game();
  bool _showEasterEgg = false;

  late final AnimationController _starsController;
  late final AnimationController _cardController;
  late final Animation<double> _cardScale;

  @override
  void initState() {
    super.initState();

    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _cardScale = CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _starsController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _triggerEasterEgg() {
    setState(() => _showEasterEgg = true);
    _starsController.forward(from: 0);
    _cardController.forward(from: 0);

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _cardController.reverse().then((_) {
          if (mounted) setState(() => _showEasterEgg = false);
        });
      }
    });
  }

  void _dismissEasterEgg() {
    _cardController.reverse().then((_) {
      if (mounted) setState(() => _showEasterEgg = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Fundo animado ──────────────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
          color: _showEasterEgg ? const Color(0xFF2D0B5E) : Colors.white,
          width: double.infinity,
          height: double.infinity,
        ),

        // ── Jogo principal ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              for (var guess in _game.guesses)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var letter in guess)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2.5,
                          vertical: 2.5,
                        ),
                        child: Tile(letter.char, letter.type),
                      )
                  ],
                ),
              GuessInput(
                onSubmitGuess: (String guess) {
                  if (guess.toLowerCase() == 'lanna') {
                    _triggerEasterEgg();
                    return;
                  }
                  setState(() {
                    _game.guess(guess);
                  });
                },
              ),
            ],
          ),
        ),

        // ── Estrelas caindo ────────────────────────────────────────────────
        if (_showEasterEgg)
          ...List.generate(
            20,
            (i) => FallingStar(controller: _starsController, index: i),
          ),

        // ── Card do easter egg ─────────────────────────────────────────────
        if (_showEasterEgg)
          Center(
            child: ScaleTransition(
              scale: _cardScale,
              child: GestureDetector(
                onTap: _dismissEasterEgg,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A0E8F),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.purpleAccent.shade100,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.6),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '💜 Modo Lanna ativado! 🍎',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'BTS + Crepúsculo = combinação aprovada ✨',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFCBA3FF),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: _dismissEasterEgg,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.purpleAccent.shade100
                              .withOpacity(0.25),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'Fechar',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── GuessInput ───────────────────────────────────────────────────────────────

class GuessInput extends StatelessWidget {
  GuessInput({super.key, required this.onSubmitGuess});

  final void Function(String) onSubmitGuess;

  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  void _onSubmit() {
    onSubmitGuess(_textEditingController.text);
    _textEditingController.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              maxLength: 5,
              focusNode: _focusNode,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(35)),
                ),
              ),
              controller: _textEditingController,
              onSubmitted: (String value) {
                _onSubmit();
              },
            ),
          ),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_circle_up),
          onPressed: _onSubmit,
        ),
      ],
    );
  }
}
