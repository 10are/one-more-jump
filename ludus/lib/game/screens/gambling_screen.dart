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

                      // Oyun seçimi - BELİRGİN
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

// ============ 21 (BLACKJACK) OYUNU - ANTİK KARTLAR ============
class _Blackjack21Game extends StatefulWidget {
  final GladiatorGame game;

  const _Blackjack21Game({required this.game});

  @override
  State<_Blackjack21Game> createState() => _Blackjack21GameState();
}

class _Blackjack21GameState extends State<_Blackjack21Game> {
  final _random = Random();
  int betAmount = 50;
  bool isPlaying = false;
  bool gameOver = false;
  bool playerWon = false;

  List<int> playerCards = [];
  List<int> dealerCards = [];
  bool dealerRevealed = false;

  int get playerTotal => _calcTotal(playerCards);
  int get dealerTotal => _calcTotal(dealerCards);

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

  void _start() {
    if (widget.game.state.gold < betAmount) return;
    setState(() {
      isPlaying = true;
      gameOver = false;
      dealerRevealed = false;
      playerCards = [_draw(), _draw()];
      dealerCards = [_draw(), _draw()];
    });
    if (playerTotal == 21) _stand();
  }

  void _hit() {
    setState(() => playerCards.add(_draw()));
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

  // Antik Roma kart isimleri
  String _cardName(int v) {
    if (v == 1) return 'I'; // As = I (Roma rakamı)
    if (v == 11) return 'XI'; // Jack = XI
    if (v == 12) return 'XII'; // Queen = XII
    if (v == 13) return 'XIII'; // King = XIII
    // Roma rakamları
    const romanNumerals = ['', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];
    return v <= 10 ? romanNumerals[v] : '$v';
  }

  // Antik sembol
  String _cardSymbol(int v) {
    if (v == 1) return '☆'; // As - Yıldız
    if (v == 11) return '⚔'; // Jack - Kılıç
    if (v == 12) return '♕'; // Queen - Taç
    if (v == 13) return '♔'; // King - Kral tacı
    return '●';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Arka plan - 21.jpg
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
        Container(color: Colors.black.withAlpha(100)),

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
                  _cardRow('KRUPIER', dealerCards, dealerTotal, !dealerRevealed),
                  const SizedBox(height: 20),

                  // Sonuç
                  if (gameOver)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: playerWon ? GameConstants.gold : GameConstants.danger,
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
                          color: playerWon ? GameConstants.success : GameConstants.danger,
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
                    _actionBtn('YENİ OYUN', const Color(0xFF9C27B0), () {
                      setState(() {
                        isPlaying = false;
                        playerCards = [];
                        dealerCards = [];
                      });
                    }),
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

  Widget _cardRow(String title, List<int> cards, int total, bool hide) {
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
              return _buildAntiqueCard(cards[i], hidden);
            }),
          ),
        ],
      ),
    );
  }

  // Antik Roma tarzı kart
  Widget _buildAntiqueCard(int value, bool hidden) {
    return Container(
      width: 50,
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        // Parşömen/eski kağıt rengi
        gradient: hidden
            ? const LinearGradient(
                colors: [Color(0xFF6B3FA0), Color(0xFF4A2C7C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFF5E6C8), Color(0xFFE8D4A8), Color(0xFFD4C098)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hidden ? const Color(0xFF9C27B0) : const Color(0xFF8B7355),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: hidden
          ? Center(
              child: Icon(
                Icons.shield,
                color: Colors.white.withAlpha(180),
                size: 28,
              ),
            )
          : Stack(
              children: [
                // Kenar süslemeleri
                Positioned(
                  top: 4,
                  left: 4,
                  child: Text(
                    _cardName(value),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: (value == 1 || value >= 11) ? const Color(0xFF8B0000) : const Color(0xFF4A3728),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Transform.rotate(
                    angle: 3.14159,
                    child: Text(
                      _cardName(value),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: (value == 1 || value >= 11) ? const Color(0xFF8B0000) : const Color(0xFF4A3728),
                      ),
                    ),
                  ),
                ),
                // Merkez sembol
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _cardSymbol(value),
                        style: TextStyle(
                          fontSize: 20,
                          color: (value == 1 || value >= 11) ? const Color(0xFF8B0000) : const Color(0xFF4A3728),
                        ),
                      ),
                      Text(
                        _cardName(value),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: (value == 1 || value >= 11) ? const Color(0xFF8B0000) : const Color(0xFF4A3728),
                          fontFamily: 'serif',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ============ ZAR OYUNU ============
class _DiceGame extends StatefulWidget {
  final GladiatorGame game;

  const _DiceGame({required this.game});

  @override
  State<_DiceGame> createState() => _DiceGameState();
}

class _DiceGameState extends State<_DiceGame> {
  final _random = Random();
  int betAmount = 50;
  bool isRolling = false;
  bool showResult = false;
  bool hasRolled = false; // İlk atış yapıldı mı?

  int p1 = 0, p2 = 0, o1 = 0, o2 = 0;
  int get pTotal => p1 + p2;
  int get oTotal => o1 + o2;

  void _roll() async {
    if (widget.game.state.gold < betAmount) return;

    setState(() {
      isRolling = true;
      showResult = false;
    });

    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
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
      hasRolled = true;
    });

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
        // Arka plan - zar.jpg
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
        Container(color: Colors.black.withAlpha(100)),

        // Oyun içeriği
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
            child: Column(
              children: [
                const Spacer(),

                // Rakip zarları
                _diceRow('RAKİP', o1, o2, oTotal, GameConstants.danger, !hasRolled),

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
                _diceRow('SEN', p1, p2, pTotal, GameConstants.success, !hasRolled),

                const SizedBox(height: 40),

                // Bahis seçimi
                if (!isRolling) ...[
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

                // Zar at butonu
                GestureDetector(
                  onTap: isRolling ? null : _roll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    decoration: BoxDecoration(
                      color: isRolling ? Colors.grey : const Color(0xFF9C27B0),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isRolling
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFF9C27B0).withAlpha(80),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.casino,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isRolling ? 'ATILIYOR...' : 'ZAR AT',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

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

  Widget _diceRow(String title, int d1, int d2, int total, Color color, bool showPlaceholder) {
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
              if (d1 > 0 && !showPlaceholder)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    '$total',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white38,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _die(d1, color, showPlaceholder),
              const SizedBox(width: 20),
              _die(d2, color, showPlaceholder),
            ],
          ),
        ],
      ),
    );
  }

  Widget _die(int value, Color color, bool showPlaceholder) {
    // Placeholder göster - zar atılmadan önce
    if (showPlaceholder || value == 0) {
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

    return Container(
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
