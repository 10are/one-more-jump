import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../gladiator_game.dart';
import '../constants.dart';
import '../services/save_service.dart';

class GamblingScreen extends StatefulWidget {
  const GamblingScreen({super.key});

  @override
  State<GamblingScreen> createState() => _GamblingScreenState();
}

class _GamblingScreenState extends State<GamblingScreen> {
  int selectedGame = 0; // 0: 21, 1: Zar

  @override
  Widget build(BuildContext context) {
    return Consumer<GladiatorGame>(
      builder: (context, game, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Ana içerik
              selectedGame == 0
                  ? _Blackjack21Game(game: game)
                  : _DiceGame(game: game),

              // Üst bar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Geri butonu
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Altın
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: GameConstants.gold.withAlpha(100)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.paid, color: GameConstants.gold, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '${game.state.gold}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: GameConstants.gold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Oyun seçimi
                      _buildGameSelector(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9C27B0).withAlpha(150), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withAlpha(40),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildGameTab(0, '21', Icons.style),
          _buildGameTab(1, 'ZAR', Icons.casino),
        ],
      ),
    );
  }

  Widget _buildGameTab(int index, String label, IconData icon) {
    final isSelected = selectedGame == index;
    return GestureDetector(
      onTap: () => setState(() => selectedGame = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9C27B0) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF9C27B0).withAlpha(60), blurRadius: 8)]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.white38,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.white38,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ 21 (BLACKJACK) OYUNU ============
class _Blackjack21Game extends StatefulWidget {
  final GladiatorGame game;

  const _Blackjack21Game({required this.game});

  @override
  State<_Blackjack21Game> createState() => _Blackjack21GameState();
}

class _Blackjack21GameState extends State<_Blackjack21Game> with TickerProviderStateMixin {
  final _random = Random();
  int betAmount = 50;
  bool isPlaying = false;
  bool gameOver = false;
  bool playerWon = false;

  List<int> playerCards = [];
  List<int> dealerCards = [];
  bool dealerRevealed = false;

  // Her kart için ayrı animasyon controller'ları
  List<AnimationController> _playerCardControllers = [];
  List<AnimationController> _dealerCardControllers = [];

  int get playerTotal => _calcTotal(playerCards);
  int get dealerTotal => _calcTotal(dealerCards);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (var c in _playerCardControllers) {
      c.dispose();
    }
    for (var c in _dealerCardControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // Yeni kart animasyonu oluştur
  AnimationController _createCardAnimation() {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    controller.forward();
    return controller;
  }

  // Tüm animasyonları temizle
  void _clearAnimations() {
    for (var c in _playerCardControllers) {
      c.dispose();
    }
    for (var c in _dealerCardControllers) {
      c.dispose();
    }
    _playerCardControllers = [];
    _dealerCardControllers = [];
  }

  int _calcTotal(List<int> cards) {
    int total = 0, aces = 0;
    for (int c in cards) {
      if (c == 1) {
        aces++;
        total += 11;
      } else if (c >= 10) {
        total += 10;
      } else {
        total += c;
      }
    }
    while (total > 21 && aces > 0) {
      total -= 10;
      aces--;
    }
    return total;
  }

  int _draw() => _random.nextInt(13) + 1;

  void _start() async {
    if (widget.game.state.gold < betAmount) return;

    _clearAnimations();

    setState(() {
      isPlaying = true;
      gameOver = false;
      dealerRevealed = false;
      playerCards = [];
      dealerCards = [];
    });

    // Kartları sırayla dağıt - animasyonlu
    await Future.delayed(const Duration(milliseconds: 100));
    _addPlayerCard();
    await Future.delayed(const Duration(milliseconds: 200));
    _addDealerCard();
    await Future.delayed(const Duration(milliseconds: 200));
    _addPlayerCard();
    await Future.delayed(const Duration(milliseconds: 200));
    _addDealerCard();

    if (playerTotal == 21) {
      await Future.delayed(const Duration(milliseconds: 300));
      _stand();
    }
  }

  void _addPlayerCard() {
    setState(() {
      playerCards.add(_draw());
      _playerCardControllers.add(_createCardAnimation());
    });
  }

  void _addDealerCard() {
    setState(() {
      dealerCards.add(_draw());
      _dealerCardControllers.add(_createCardAnimation());
    });
  }

  void _hit() async {
    _addPlayerCard();
    await Future.delayed(const Duration(milliseconds: 300));
    if (playerTotal > 21) {
      _end(false);
    } else if (playerTotal == 21) {
      _stand();
    }
  }

  void _stand() {
    setState(() => dealerRevealed = true);
    while (dealerTotal < 17) {
      dealerCards.add(_draw());
    }
    setState(() {});
    if (dealerTotal > 21) {
      _end(true);
    } else if (playerTotal > dealerTotal) {
      _end(true);
    } else if (playerTotal < dealerTotal) {
      _end(false);
    } else {
      _end(null);
    }
  }

  void _end(bool? won) {
    setState(() {
      gameOver = true;
      playerWon = won == true;
      dealerRevealed = true;
    });
    if (won == true) {
      widget.game.state.modifyGold(betAmount);
    } else if (won == false) {
      widget.game.state.modifyGold(-betAmount);
    }
    widget.game.refreshState();
    SaveService.autoSave(widget.game.state);
  }

  // Yeni el - oyun devam ediyor
  void _newHand() async {
    if (widget.game.state.gold < betAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yeterli altın yok!'),
          backgroundColor: GameConstants.danger,
        ),
      );
      return;
    }

    _clearAnimations();

    setState(() {
      gameOver = false;
      dealerRevealed = false;
      playerCards = [];
      dealerCards = [];
    });

    // Kartları sırayla dağıt
    await Future.delayed(const Duration(milliseconds: 100));
    _addPlayerCard();
    await Future.delayed(const Duration(milliseconds: 200));
    _addDealerCard();
    await Future.delayed(const Duration(milliseconds: 200));
    _addPlayerCard();
    await Future.delayed(const Duration(milliseconds: 200));
    _addDealerCard();

    if (playerTotal == 21) {
      await Future.delayed(const Duration(milliseconds: 300));
      _stand();
    }
  }

  // Normal sayı göster
  String _cardName(int v) {
    if (v == 1) return 'A';
    if (v == 11) return 'J';
    if (v == 12) return 'Q';
    if (v == 13) return 'K';
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Arka plan
        Image.asset(
          'assets/21.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1a472a), Color(0xFF0d2818)],
              ),
            ),
          ),
        ),

        // Karartma
        Container(color: Colors.black.withAlpha(120)),

        // Oyun içeriği
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
            child: Column(
              children: [
                const Spacer(),

                if (!isPlaying) ...[
                  // Bahis seçimi
                  Text(
                    'BAHİS SEÇ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [25, 50, 100, 200].map((b) => _betBtn(b)).toList(),
                  ),
                  const SizedBox(height: 24),
                  _actionBtn('OYNA', GameConstants.gold, _start),
                ] else ...[
                  // Krupiye kartları
                  _cardRow('KRUPİYE', dealerCards, dealerTotal, !dealerRevealed),
                  const SizedBox(height: 20),

                  // Sonuç
                  if (gameOver)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: playerTotal == dealerTotal
                              ? Colors.white54
                              : (playerWon ? GameConstants.success : GameConstants.danger),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        playerTotal == dealerTotal
                            ? 'BERABERE'
                            : (playerWon ? '+$betAmount ALTIN' : '-$betAmount ALTIN'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: playerTotal == dealerTotal
                              ? Colors.white54
                              : (playerWon ? GameConstants.success : GameConstants.danger),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 50),

                  const SizedBox(height: 20),

                  // Oyuncu kartları
                  _cardRow('SEN', playerCards, playerTotal, false),
                  const SizedBox(height: 24),

                  if (gameOver) ...[
                    // Devam et veya çık
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _actionBtn('DEVAM ET', const Color(0xFF9C27B0), _newHand),
                        const SizedBox(width: 16),
                        _smallBtn('ÇIK', Colors.white38, () {
                          setState(() {
                            isPlaying = false;
                            playerCards = [];
                            dealerCards = [];
                          });
                        }),
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _actionBtn('ÇEK', GameConstants.success, _hit),
                        const SizedBox(width: 20),
                        _actionBtn('KAL', GameConstants.danger, _stand),
                      ],
                    ),
                  ],
                ],

                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _betBtn(int amount) {
    final sel = betAmount == amount;
    final can = widget.game.state.gold >= amount;
    return GestureDetector(
      onTap: can ? () => setState(() => betAmount = amount) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF9C27B0) : Colors.black45,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: sel ? const Color(0xFF9C27B0) : Colors.white24,
            width: sel ? 2 : 1,
          ),
        ),
        child: Text(
          '$amount',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: sel ? Colors.white : (can ? Colors.white70 : Colors.white30),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(80),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _smallBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _cardRow(String title, List<int> cards, int total, bool hide) {
    final isPlayer = title == 'SEN';
    final controllers = isPlayer ? _playerCardControllers : _dealerCardControllers;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B7355).withAlpha(100)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFD4AF37),
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: total > 21
                      ? GameConstants.danger.withAlpha(40)
                      : const Color(0xFFD4AF37).withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: total > 21 ? GameConstants.danger : const Color(0xFFD4AF37),
                  ),
                ),
                child: Text(
                  hide ? '?' : '$total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: total > 21 ? GameConstants.danger : const Color(0xFFD4AF37),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(cards.length, (i) {
              final hidden = hide && i == 1;
              final controller = i < controllers.length ? controllers[i] : null;
              return _buildAnimatedCard(cards[i], hidden, controller);
            }),
          ),
        ],
      ),
    );
  }

  // Animasyonlu kart widget'ı
  Widget _buildAnimatedCard(int value, bool hidden, AnimationController? controller) {
    if (controller == null) {
      return _buildAntiqueCard(value, hidden);
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = controller.value;
        final slideOffset = (1 - progress) * 100;
        final rotation = (1 - progress) * 0.5;
        final scale = 0.5 + (progress * 0.5);

        return Transform.translate(
          offset: Offset(slideOffset, -slideOffset * 0.5),
          child: Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: progress,
                child: _buildAntiqueCard(value, hidden),
              ),
            ),
          ),
        );
      },
    );
  }

  // Eskitilmiş antik kart tasarımı - NORMAL SAYILAR
  Widget _buildAntiqueCard(int value, bool hidden) {
    return Container(
      width: 55,
      height: 78,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        // Eskitilmiş parşömen rengi
        gradient: hidden
            ? const LinearGradient(
          colors: [Color(0xFF6B3FA0), Color(0xFF4A2C7C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : const LinearGradient(
          colors: [
            Color(0xFFF5E6C8),
            Color(0xFFE8D4A8),
            Color(0xFFD4C098),
            Color(0xFFC4B088),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hidden ? const Color(0xFF9C27B0) : const Color(0xFF6B5344),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: hidden
          ? Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.shield, color: Colors.white.withAlpha(60), size: 40),
            Icon(Icons.question_mark, color: Colors.white.withAlpha(180), size: 20),
          ],
        ),
      )
          : Stack(
        children: [
          // Eskitilmiş doku efekti
          Positioned.fill(
            child: CustomPaint(
              painter: _AgedPaperPainter(),
            ),
          ),
          // Sol üst köşe sayı
          Positioned(
            top: 4,
            left: 6,
            child: Text(
              _cardName(value),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: _getCardColor(value),
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(50),
                    offset: const Offset(1, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          // Sağ alt köşe sayı (ters)
          Positioned(
            bottom: 4,
            right: 6,
            child: Transform.rotate(
              angle: 3.14159,
              child: Text(
                _cardName(value),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: _getCardColor(value),
                  shadows: [
                    Shadow(
                      color: Colors.black.withAlpha(50),
                      offset: const Offset(1, 1),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Merkez - büyük sayı ve sembol
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Antik sembol
                Text(
                  _getCardSymbol(value),
                  style: TextStyle(
                    fontSize: 18,
                    color: _getCardColor(value),
                  ),
                ),
                const SizedBox(height: 2),
                // Büyük sayı
                Text(
                  _cardName(value),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _getCardColor(value),
                    letterSpacing: -1,
                    shadows: [
                      Shadow(
                        color: Colors.black.withAlpha(40),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Kenar süslemeleri - antik çerçeve
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: const Color(0xFF8B7355).withAlpha(60),
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCardColor(int value) {
    // As ve figürler koyu kırmızı, diğerleri koyu kahve
    if (value == 1 || value >= 11) {
      return const Color(0xFF8B0000);
    }
    return const Color(0xFF3D2914);
  }

  String _getCardSymbol(int value) {
    if (value == 1) return '★'; // As - Yıldız
    if (value == 11) return '⚔'; // Jack - Kılıç
    if (value == 12) return '♕'; // Queen - Kraliçe
    if (value == 13) return '♔'; // King - Kral
    return '●';
  }
}

// Eskitilmiş kağıt efekti
class _AgedPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // Sabit seed
    final paint = Paint()..color = const Color(0xFF8B7355).withAlpha(15);

    // Rastgele lekeler
    for (int i = 0; i < 8; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = random.nextDouble() * 4 + 1;
      canvas.drawCircle(Offset(x, y), r, paint);
    }

    // Çizik efekti
    final linePaint = Paint()
      ..color = const Color(0xFF8B7355).withAlpha(20)
      ..strokeWidth = 0.5;

    for (int i = 0; i < 3; i++) {
      final y = random.nextDouble() * size.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width * (0.3 + random.nextDouble() * 0.4), y + random.nextDouble() * 5),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============ ZAR OYUNU ============
class _DiceGame extends StatefulWidget {
  final GladiatorGame game;

  const _DiceGame({required this.game});

  @override
  State<_DiceGame> createState() => _DiceGameState();
}

class _DiceGameState extends State<_DiceGame> with TickerProviderStateMixin {
  final _random = Random();
  int betAmount = 50;
  bool isPlaying = false; // Oyun başladı mı?
  bool isRolling = false;
  bool showResult = false;

  int p1 = 0, p2 = 0, o1 = 0, o2 = 0;
  int get pTotal => p1 + p2;
  int get oTotal => o1 + o2;

  // Zar animasyonu
  late AnimationController _diceAnimController;
  late Animation<double> _diceRotation;

  @override
  void initState() {
    super.initState();
    _diceAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _diceRotation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _diceAnimController, curve: Curves.bounceOut),
    );
  }

  @override
  void dispose() {
    _diceAnimController.dispose();
    super.dispose();
  }

  void _startGame() {
    if (widget.game.state.gold < betAmount) return;
    setState(() {
      isPlaying = true;
      showResult = false;
      p1 = 0;
      p2 = 0;
      o1 = 0;
      o2 = 0;
    });
  }

  void _roll() async {
    if (widget.game.state.gold < betAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yeterli altın yok!'),
          backgroundColor: GameConstants.danger,
        ),
      );
      return;
    }

    setState(() {
      isRolling = true;
      showResult = false;
    });

    // Animasyon başlat
    _diceAnimController.forward(from: 0);

    // Zar atma animasyonu
    for (int i = 0; i < 12; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (mounted) {
        setState(() {
          p1 = _random.nextInt(6) + 1;
          p2 = _random.nextInt(6) + 1;
          o1 = _random.nextInt(6) + 1;
          o2 = _random.nextInt(6) + 1;
        });
      }
    }

    setState(() {
      isRolling = false;
      showResult = true;
    });

    // Sonuç işle
    if (pTotal > oTotal) {
      widget.game.state.modifyGold(betAmount);
    } else if (pTotal < oTotal) {
      widget.game.state.modifyGold(-betAmount);
    }
    widget.game.refreshState();
    SaveService.autoSave(widget.game.state);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Arka plan
        Image.asset(
          'assets/zar.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2d1f3d), Color(0xFF1a1225)],
              ),
            ),
          ),
        ),

        // Karartma
        Container(color: Colors.black.withAlpha(120)),

        // Oyun içeriği
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
            child: Column(
              children: [
                const Spacer(),

                if (!isPlaying) ...[
                  // Başlangıç - bahis seç ve oyna
                  Text(
                    'BAHİS SEÇ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [25, 50, 100, 200].map((b) => _betBtn(b)).toList(),
                  ),
                  const SizedBox(height: 24),
                  _actionBtn('OYNA', const Color(0xFF9C27B0), _startGame),
                ] else ...[
                  // Oyun devam ediyor

                  // Rakip zarları
                  _diceRow('RAKİP', o1, o2, oTotal, GameConstants.danger),

                  const SizedBox(height: 30),

                  // Sonuç
                  if (showResult)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: pTotal > oTotal
                              ? GameConstants.success
                              : (pTotal < oTotal ? GameConstants.danger : Colors.white54),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        pTotal > oTotal
                            ? '+$betAmount ALTIN'
                            : (pTotal < oTotal ? '-$betAmount ALTIN' : 'BERABERE'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: pTotal > oTotal
                              ? GameConstants.success
                              : (pTotal < oTotal ? GameConstants.danger : Colors.white54),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white38,
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),

                  // Oyuncu zarları
                  _diceRow('SEN', p1, p2, pTotal, GameConstants.success),

                  const SizedBox(height: 40),

                  // Bahis seçimi (oyun içinde)
                  if (!isRolling && showResult) ...[
                    Text(
                      'BAHİS',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [25, 50, 100, 200].map((b) => _betBtn(b)).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Butonlar
                  if (showResult) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _actionBtn('TEKRAR AT', const Color(0xFF9C27B0), _roll),
                        const SizedBox(width: 16),
                        _smallBtn('ÇIK', Colors.white38, () {
                          setState(() {
                            isPlaying = false;
                            showResult = false;
                            p1 = 0;
                            p2 = 0;
                            o1 = 0;
                            o2 = 0;
                          });
                        }),
                      ],
                    ),
                  ] else ...[
                    _actionBtn(
                      isRolling ? 'ATILIYOR...' : 'ZAR AT',
                      isRolling ? Colors.grey : const Color(0xFF9C27B0),
                      isRolling ? () {} : _roll,
                    ),
                  ],
                ],

                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _betBtn(int amount) {
    final sel = betAmount == amount;
    final can = widget.game.state.gold >= amount;
    return GestureDetector(
      onTap: can ? () => setState(() => betAmount = amount) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF9C27B0) : Colors.black45,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: sel ? const Color(0xFF9C27B0) : Colors.white24,
            width: sel ? 2 : 1,
          ),
        ),
        child: Text(
          '$amount',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: sel ? Colors.white : (can ? Colors.white70 : Colors.white30),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: color != Colors.grey
              ? [
            BoxShadow(
              color: color.withAlpha(80),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label == 'ZAR AT' || label == 'TEKRAR AT')
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.casino, color: Colors.white, size: 20),
              ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _diceRow(String title, int d1, int d2, int total, Color color) {
    final showPlaceholder = d1 == 0 && d2 == 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withAlpha(180),
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: showPlaceholder ? Colors.white10 : color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: showPlaceholder ? Colors.white24 : color),
                ),
                child: Text(
                  showPlaceholder ? '?' : '$total',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: showPlaceholder ? Colors.white38 : color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _animatedDie(d1, color, showPlaceholder),
              const SizedBox(width: 20),
              _animatedDie(d2, color, showPlaceholder),
            ],
          ),
        ],
      ),
    );
  }

  Widget _animatedDie(int value, Color color, bool showPlaceholder) {
    if (showPlaceholder) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Center(
          child: Icon(
            Icons.casino,
            color: Colors.white38,
            size: 30,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _diceAnimController,
      builder: (context, child) {
        final bounce = isRolling ? sin(_diceRotation.value * 3) * 10 : 0.0;
        final scale = isRolling ? 0.9 + sin(_diceRotation.value * 2) * 0.1 : 1.0;

        return Transform.translate(
          offset: Offset(0, bounce),
          child: Transform.scale(
            scale: scale,
            child: Transform.rotate(
              angle: isRolling ? _diceRotation.value : 0,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(60),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CustomPaint(painter: _DiePainter(value, color)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DiePainter extends CustomPainter {
  final int value;
  final Color color;
  _DiePainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final r = size.width * 0.1;
    final positions = <Offset>[];

    switch (value) {
      case 1:
        positions.add(const Offset(0.5, 0.5));
        break;
      case 2:
        positions.addAll([const Offset(0.3, 0.3), const Offset(0.7, 0.7)]);
        break;
      case 3:
        positions.addAll([const Offset(0.3, 0.3), const Offset(0.5, 0.5), const Offset(0.7, 0.7)]);
        break;
      case 4:
        positions.addAll([
          const Offset(0.3, 0.3),
          const Offset(0.7, 0.3),
          const Offset(0.3, 0.7),
          const Offset(0.7, 0.7)
        ]);
        break;
      case 5:
        positions.addAll([
          const Offset(0.3, 0.3),
          const Offset(0.7, 0.3),
          const Offset(0.5, 0.5),
          const Offset(0.3, 0.7),
          const Offset(0.7, 0.7)
        ]);
        break;
      case 6:
        positions.addAll([
          const Offset(0.3, 0.3),
          const Offset(0.7, 0.3),
          const Offset(0.3, 0.5),
          const Offset(0.7, 0.5),
          const Offset(0.3, 0.7),
          const Offset(0.7, 0.7)
        ]);
        break;
    }

    for (final p in positions) {
      canvas.drawCircle(Offset(p.dx * size.width, p.dy * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
