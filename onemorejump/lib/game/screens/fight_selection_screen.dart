import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../gladiator_game.dart';
import '../constants.dart';
import '../models/gladiator.dart';
import 'fight_screen.dart';

class FightSelectionScreen extends StatefulWidget {
  final bool isArena;

  const FightSelectionScreen({super.key, required this.isArena});

  @override
  State<FightSelectionScreen> createState() => _FightSelectionScreenState();
}

class _FightSelectionScreenState extends State<FightSelectionScreen> {
  List<Map<String, dynamic>> fighters = [];
  bool isLoading = true;
  final PageController _pageController = PageController(viewportFraction: 0.45);

  @override
  void initState() {
    super.initState();
    _loadFighters();
  }

  Future<void> _loadFighters() async {
    try {
      final String jsonPath = widget.isArena
          ? 'assets/data/arena_fighters.json'
          : 'assets/data/underground_fighters.json';
      final String jsonString = await rootBundle.loadString(jsonPath);
      final Map<String, dynamic> data = json.decode(jsonString);

      setState(() {
        fighters = List<Map<String, dynamic>>.from(
          widget.isArena ? data['arena_fighters'] : data['underground_fighters'],
        );
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GladiatorGame>(
      builder: (context, game, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Arka plan görseli - TAM GÖRÜNÜR
              Positioned.fill(
                child: Image.asset(
                  widget.isArena ? 'assets/arena.png' : 'assets/yeralti.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: widget.isArena
                            ? [GameConstants.warmOrange.withAlpha(80), GameConstants.primaryDark]
                            : [GameConstants.primaryDark, Colors.black],
                      ),
                    ),
                  ),
                ),
              ),

              // İçerik
              SafeArea(
                child: Column(
                  children: [
                    // Üst bar
                    _buildTopBar(context, game),

                    // Boşluk - arka plan görünsün
                    const Spacer(),

                    // Alt kısımda sabit kartlar
                    SizedBox(
                      height: 300,
                      child: isLoading
                          ? Center(child: CircularProgressIndicator(color: GameConstants.gold))
                          : PageView.builder(
                              controller: _pageController,
                              itemCount: fighters.length,
                              itemBuilder: (context, index) {
                                final fighter = fighters[index];
                                return _FighterCard(
                                  fighter: fighter,
                                  isArena: widget.isArena,
                                  game: game,
                                  index: index + 1,
                                  total: fighters.length,
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, GladiatorGame game) {
    final accentColor = widget.isArena ? GameConstants.gold : GameConstants.bloodRed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Geri butonu
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(120),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_back, color: GameConstants.textLight, size: 22),
            ),
          ),

          const SizedBox(width: 12),

          // Başlık
          Text(
            widget.isArena ? 'ARENA' : 'YERALTI',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: accentColor,
              letterSpacing: 3,
              shadows: [Shadow(color: Colors.black, blurRadius: 10)],
            ),
          ),

          const Spacer(),

          // Altın
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(120),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.paid, color: GameConstants.gold, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${game.state.gold}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: GameConstants.gold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Savaşçı kartı - KÜÇÜK VE KOMPAKT
class _FighterCard extends StatelessWidget {
  final Map<String, dynamic> fighter;
  final bool isArena;
  final GladiatorGame game;
  final int index;
  final int total;

  const _FighterCard({
    required this.fighter,
    required this.isArena,
    required this.game,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDefeated = fighter['defeated'] ?? false;
    final Color accentColor = isArena ? GameConstants.gold : GameConstants.bloodRed;
    final String? imagePath = fighter['image'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(isDefeated ? 150 : 180),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDefeated ? GameConstants.textMuted.withAlpha(50) : accentColor.withAlpha(100),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColorFiltered(
          colorFilter: isDefeated
              ? const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 1, 0,
                ])
              : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
          child: Column(
            children: [
              // Görsel
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Asker görseli
                    if (imagePath != null)
                      Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: accentColor.withAlpha(30),
                          child: Icon(Icons.person, size: 50, color: accentColor.withAlpha(100)),
                        ),
                      )
                    else
                      Container(
                        color: accentColor.withAlpha(30),
                        child: Icon(Icons.person, size: 50, color: accentColor.withAlpha(100)),
                      ),

                    // Gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withAlpha(200)],
                          ),
                        ),
                      ),
                    ),

                    // Sıra numarası
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$index/$total',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                    ),

                    // Defeated badge
                    if (isDefeated)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: GameConstants.success,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),

              // Bilgiler - kompakt
              Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    // İsim ve Unvan
                    Text(
                      fighter['name'] ?? 'Bilinmeyen',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDefeated ? GameConstants.textMuted : GameConstants.textLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      fighter['title'] ?? '',
                      style: TextStyle(
                        fontSize: 9,
                        color: isDefeated ? GameConstants.textMuted.withAlpha(150) : accentColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Statlar - küçük ikonlarla
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMiniStat(Icons.favorite, fighter['health'] ?? 0, Colors.red),
                        _buildMiniStat(Icons.flash_on, fighter['strength'] ?? 0, Colors.orange),
                        _buildMiniStat(Icons.psychology, fighter['intelligence'] ?? 0, Colors.blue),
                        _buildMiniStat(Icons.directions_run, fighter['stamina'] ?? 0, Colors.green),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Ödül
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.paid, color: GameConstants.gold, size: 11),
                        const SizedBox(width: 2),
                        Text(
                          '${fighter['reward'] ?? 0}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GameConstants.gold),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Savaş butonu
                    if (!isDefeated)
                      GestureDetector(
                        onTap: () => _showBetDialog(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'SAVAŞ',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: GameConstants.success.withAlpha(50),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'YENİLDİ',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: GameConstants.success),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, int value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 12, color: color.withAlpha(200)),
        const SizedBox(height: 1),
        Text(
          '$value',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: GameConstants.textLight),
        ),
      ],
    );
  }

  void _showBetDialog(BuildContext context) {
    final availableGladiators = game.state.availableForFight;

    if (availableGladiators.isEmpty) {
      _showCustomPopup(context, 'UYARI', 'Savaşabilecek gladyatör yok!', false);
      return;
    }

    // Arena modunda bahis yok, direkt gladyatör seç
    if (isArena) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => _GladiatorSelectionSheet(
          fighter: fighter,
          game: game,
          availableGladiators: availableGladiators,
        ),
      );
    } else {
      // Yeraltı modunda bahis var
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => _BetSelectionSheet(
          fighter: fighter,
          game: game,
          isArena: false,
          availableGladiators: availableGladiators,
        ),
      );
    }
  }

  void _showCustomPopup(BuildContext context, String title, String message, bool success) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 50),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: GameConstants.primaryDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: success ? GameConstants.gold : GameConstants.danger, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(success ? Icons.check_circle : Icons.error, color: success ? GameConstants.gold : GameConstants.danger, size: 40),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: success ? GameConstants.gold : GameConstants.danger)),
              const SizedBox(height: 4),
              Text(message, style: TextStyle(fontSize: 12, color: GameConstants.textLight), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(color: success ? GameConstants.gold : GameConstants.danger, borderRadius: BorderRadius.circular(6)),
                  child: Text('TAMAM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ARENA - GLADYATÖR SEÇİM EKRANI (BAHİS YOK)
class _GladiatorSelectionSheet extends StatefulWidget {
  final Map<String, dynamic> fighter;
  final GladiatorGame game;
  final List availableGladiators;

  const _GladiatorSelectionSheet({
    required this.fighter,
    required this.game,
    required this.availableGladiators,
  });

  @override
  State<_GladiatorSelectionSheet> createState() => _GladiatorSelectionSheetState();
}

class _GladiatorSelectionSheetState extends State<_GladiatorSelectionSheet> {
  String? selectedGladiatorId;

  @override
  Widget build(BuildContext context) {
    final reward = widget.fighter['reward'] ?? 0;
    final reputationReward = widget.fighter['reputation_reward'] ?? 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameConstants.primaryDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: GameConstants.gold.withAlpha(60)),
      ),
      child: Column(
        children: [
          // Başlık
          Text(
            '${widget.fighter['name']}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GameConstants.gold),
          ),
          Text(
            widget.fighter['title'] ?? '',
            style: TextStyle(fontSize: 11, color: GameConstants.textMuted),
          ),

          const SizedBox(height: 12),

          // Ödül bilgisi
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GameConstants.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GameConstants.gold.withAlpha(40)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Icon(Icons.paid, color: GameConstants.gold, size: 20),
                    const SizedBox(height: 4),
                    Text('$reward', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GameConstants.gold)),
                    Text('Altın', style: TextStyle(fontSize: 10, color: GameConstants.textMuted)),
                  ],
                ),
                Container(width: 1, height: 40, color: GameConstants.cardBorder),
                Column(
                  children: [
                    Icon(Icons.star, color: GameConstants.warmOrange, size: 20),
                    const SizedBox(height: 4),
                    Text('+$reputationReward', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GameConstants.warmOrange)),
                    Text('İtibar', style: TextStyle(fontSize: 10, color: GameConstants.textMuted)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text('SAVAŞÇI SEÇ', style: TextStyle(fontSize: 11, color: GameConstants.textMuted, letterSpacing: 1)),
          const SizedBox(height: 6),

          Expanded(
            child: ListView.builder(
              itemCount: widget.availableGladiators.length,
              itemBuilder: (context, index) {
                final g = widget.availableGladiators[index];
                final isSelected = selectedGladiatorId == g.id;

                return GestureDetector(
                  onTap: () => setState(() => selectedGladiatorId = g.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? GameConstants.gold.withAlpha(30) : GameConstants.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? GameConstants.gold : GameConstants.cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: GameConstants.bloodRed.withAlpha(50),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(g.name[0], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GameConstants.bloodRed)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.name, style: TextStyle(color: GameConstants.textLight, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Güç: ${g.overallPower} | HP: ${g.health}%', style: TextStyle(color: GameConstants.textMuted, fontSize: 10)),
                            ],
                          ),
                        ),
                        if (isSelected) Icon(Icons.check_circle, color: GameConstants.gold, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedGladiatorId != null
                  ? () {
                      Navigator.pop(context);
                      _startArenaFight(context, selectedGladiatorId!);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: GameConstants.gold,
                disabledBackgroundColor: GameConstants.cardBorder,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'ARENAYA GİR',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startArenaFight(BuildContext context, String gladiatorId) {
    final gladiator = widget.availableGladiators.firstWhere((g) => g.id == gladiatorId) as Gladiator;
    final reward = widget.fighter['reward'] ?? 0;
    final reputationReward = widget.fighter['reputation_reward'] ?? 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FightScreen(
          player: gladiator,
          enemyName: widget.fighter['name'] ?? 'Rakip',
          enemyTitle: widget.fighter['title'] ?? '',
          enemyImage: widget.fighter['image'],
          enemyHealth: widget.fighter['health'] ?? 50,
          enemyStrength: widget.fighter['strength'] ?? 50,
          enemyIntelligence: widget.fighter['intelligence'] ?? 50,
          enemyStamina: widget.fighter['stamina'] ?? 50,
          goldReward: reward,
          reputationReward: reputationReward,
          fightType: 'arena',
          onFightEnd: (outcome) {
            // Sonuçları uygula
            if (outcome.playerWon) {
              widget.game.state.modifyGold(outcome.goldReward);
              widget.game.state.modifyReputation(outcome.reputationReward);
            }

            // Hasar uygula
            gladiator.takeDamage(outcome.playerDamage);

            // Ölüm kontrolü
            if (outcome.playerDied) {
              widget.game.state.gladiators.remove(gladiator);
            }

            widget.game.refreshState();
          },
        ),
      ),
    );
  }
}

// YERALTI - BAHİS VE SAVAŞÇI SEÇİM EKRANI
class _BetSelectionSheet extends StatefulWidget {
  final Map<String, dynamic> fighter;
  final GladiatorGame game;
  final bool isArena;
  final List availableGladiators;

  const _BetSelectionSheet({
    required this.fighter,
    required this.game,
    required this.isArena,
    required this.availableGladiators,
  });

  @override
  State<_BetSelectionSheet> createState() => _BetSelectionSheetState();
}

class _BetSelectionSheetState extends State<_BetSelectionSheet> {
  int betAmount = 0;
  String? selectedGladiatorId;

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isArena ? GameConstants.gold : GameConstants.bloodRed;
    final maxBet = widget.game.state.gold;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameConstants.primaryDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: accentColor.withAlpha(60)),
      ),
      child: Column(
        children: [
          // Başlık
          Text(
            '${widget.fighter['name']}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor),
          ),
          Text(
            'ile savaşacaksın',
            style: TextStyle(fontSize: 11, color: GameConstants.textMuted),
          ),

          const SizedBox(height: 12),

          // BAHİS BÖLÜMÜ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GameConstants.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GameConstants.gold.withAlpha(40)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.casino, color: GameConstants.gold, size: 16),
                        const SizedBox(width: 6),
                        Text('BAHİS', style: TextStyle(fontSize: 11, color: GameConstants.textMuted)),
                      ],
                    ),
                    Text('Mevcut: $maxBet', style: TextStyle(fontSize: 11, color: GameConstants.gold)),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: betAmount.toDouble(),
                        min: 0,
                        max: maxBet.toDouble(),
                        divisions: maxBet > 0 ? (maxBet ~/ 10).clamp(1, 20) : 1,
                        activeColor: GameConstants.gold,
                        inactiveColor: GameConstants.cardBorder,
                        onChanged: (value) => setState(() => betAmount = value.toInt()),
                      ),
                    ),
                    Container(
                      width: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: GameConstants.gold.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$betAmount',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: GameConstants.gold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),

                if (betAmount > 0)
                  Text(
                    'Kazanırsan: +${betAmount * 2} (2x)',
                    style: TextStyle(fontSize: 12, color: GameConstants.success, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text('SAVAŞÇI SEÇ', style: TextStyle(fontSize: 11, color: GameConstants.textMuted, letterSpacing: 1)),
          const SizedBox(height: 6),

          Expanded(
            child: ListView.builder(
              itemCount: widget.availableGladiators.length,
              itemBuilder: (context, index) {
                final g = widget.availableGladiators[index];
                final isSelected = selectedGladiatorId == g.id;

                return GestureDetector(
                  onTap: () => setState(() => selectedGladiatorId = g.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor.withAlpha(30) : GameConstants.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? accentColor : GameConstants.cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: GameConstants.bloodRed.withAlpha(50),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(g.name[0], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GameConstants.bloodRed)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.name, style: TextStyle(color: GameConstants.textLight, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Güç: ${g.overallPower} | HP: ${g.health}%', style: TextStyle(color: GameConstants.textMuted, fontSize: 10)),
                            ],
                          ),
                        ),
                        if (isSelected) Icon(Icons.check_circle, color: accentColor, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedGladiatorId != null
                  ? () {
                      Navigator.pop(context);
                      _startUndergroundFight(context, selectedGladiatorId!, betAmount);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                disabledBackgroundColor: GameConstants.cardBorder,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                betAmount > 0 ? 'SAVAŞ (Bahis: $betAmount)' : 'SAVAŞ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startUndergroundFight(BuildContext context, String gladiatorId, int bet) {
    final gladiator = widget.availableGladiators.firstWhere((g) => g.id == gladiatorId) as Gladiator;
    final reward = widget.fighter['reward'] ?? 100;

    // Bahis miktarını düş
    if (bet > 0) {
      widget.game.state.modifyGold(-bet);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FightScreen(
          player: gladiator,
          enemyName: widget.fighter['name'] ?? 'Rakip',
          enemyTitle: widget.fighter['title'] ?? 'Yeraltı Savaşçısı',
          enemyImage: widget.fighter['image'],
          enemyHealth: widget.fighter['health'] ?? 50,
          enemyStrength: widget.fighter['strength'] ?? 50,
          enemyIntelligence: widget.fighter['intelligence'] ?? 50,
          enemyStamina: widget.fighter['stamina'] ?? 50,
          goldReward: reward + bet, // Bahis + ödül
          reputationReward: 0, // Yeraltı'da itibar yok
          fightType: 'underground',
          onFightEnd: (outcome) {
            // Sonuçları uygula
            if (outcome.playerWon) {
              widget.game.state.modifyGold(outcome.goldReward);
              // Bahis kazanıldıysa 2x ver
              if (bet > 0) {
                widget.game.state.modifyGold(bet); // Bahis geri + kar
              }
            }

            // Hasar uygula
            gladiator.takeDamage(outcome.playerDamage);

            // Ölüm kontrolü
            if (outcome.playerDied) {
              widget.game.state.gladiators.remove(gladiator);
            }

            widget.game.refreshState();
          },
        ),
      ),
    );
  }
}
