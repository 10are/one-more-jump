import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../gladiator_game.dart';
import '../constants.dart';
import '../models/gladiator.dart';
import 'fight_screen.dart';
import 'components/dialogue_component.dart';

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
    PreFightDialogueHelper.loadDialogues();
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
              // Arka plan gorseli - TAM GORUNUR
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

              // Icerik
              SafeArea(
                child: Column(
                  children: [
                    // Ust bar
                    _buildTopBar(context, game),

                    // Bosluk - arka plan gorunsun
                    const Spacer(),

                    // Alt kisimda sabit kartlar
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

          // Baslik
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

          // Altin
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

// Savasci karti - KUCUK VE KOMPAKT
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
              // Gorsel
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Asker gorseli
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

                    // Sira numarasi
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
                    // Isim ve Unvan
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

                    // Statlar - kucuk ikonlarla
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

                    // Odul
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

                    // Savas butonu
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
                            'SAVAS',
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
                          'YENILDI',
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
      _showCustomPopup(context, 'UYARI', 'Savasabilecek gladyator yok!', false);
      return;
    }

    // Arena modunda bahis yok, direkt gladyator sec
    if (isArena) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => _GladiatorSelectionSheet(
          fighter: fighter,
          game: game,
          availableGladiators: availableGladiators,
          isArena: true,
        ),
      );
    } else {
      // Yeralti modunda bahis var
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

// ARENA/YERALTI - GLADYATOR SECIM EKRANI
class _GladiatorSelectionSheet extends StatefulWidget {
  final Map<String, dynamic> fighter;
  final GladiatorGame game;
  final List availableGladiators;
  final bool isArena;
  final int betAmount;

  const _GladiatorSelectionSheet({
    required this.fighter,
    required this.game,
    required this.availableGladiators,
    required this.isArena,
    this.betAmount = 0,
  });

  @override
  State<_GladiatorSelectionSheet> createState() => _GladiatorSelectionSheetState();
}

class _GladiatorSelectionSheetState extends State<_GladiatorSelectionSheet> {
  String? selectedGladiatorId;
  bool showDialogue = false;
  int moraleBonus = 0;
  Map<String, dynamic>? currentDialogue;

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isArena ? GameConstants.gold : GameConstants.bloodRed;
    final reward = widget.fighter['reward'] ?? 0;
    final reputationReward = widget.fighter['reputation_reward'] ?? 0;

    // Diyalog gosteriliyor mu?
    if (showDialogue && selectedGladiatorId != null) {
      return _buildDialogueView(context, accentColor);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: GameConstants.primaryDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: accentColor.withAlpha(60)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: GameConstants.textMuted.withAlpha(100),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Baslik ve odul satiri - kompakt
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.fighter['name']}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accentColor),
                    ),
                    Text(
                      widget.fighter['title'] ?? '',
                      style: TextStyle(fontSize: 10, color: GameConstants.textMuted),
                    ),
                  ],
                ),
              ),
              // Oduller - kompakt
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: GameConstants.gold.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.paid, color: GameConstants.gold, size: 14),
                        const SizedBox(width: 4),
                        Text('$reward', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GameConstants.gold)),
                      ],
                    ),
                  ),
                  if (widget.isArena) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: GameConstants.warmOrange.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: GameConstants.warmOrange, size: 14),
                          const SizedBox(width: 4),
                          Text('+$reputationReward', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GameConstants.warmOrange)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Ayirici
          Container(
            height: 1,
            color: GameConstants.cardBorder.withAlpha(50),
          ),

          const SizedBox(height: 12),

          Text('SAVASCI SEC', style: TextStyle(fontSize: 10, color: GameConstants.textMuted, letterSpacing: 1)),
          const SizedBox(height: 8),

          // Gladyator kartlari - yatay kaydirmali
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.availableGladiators.length,
              itemBuilder: (context, index) {
                final g = widget.availableGladiators[index];
                final isSelected = selectedGladiatorId == g.id;

                return GestureDetector(
                  onTap: () => setState(() => selectedGladiatorId = g.id),
                  child: Container(
                    width: 110,
                    margin: EdgeInsets.only(
                      left: index == 0 ? 0 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor.withAlpha(40) : Colors.black.withAlpha(150),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accentColor : GameConstants.cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accentColor.withAlpha(50),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Column(
                        children: [
                          // Gladyator gorseli
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                g.imagePath != null
                                    ? Image.asset(
                                        g.imagePath!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildPlaceholder(g, accentColor),
                                      )
                                    : _buildPlaceholder(g, accentColor),

                                // Gradient overlay
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  height: 30,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withAlpha(200),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Secili badge
                                if (isSelected)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: accentColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.check, size: 12, color: Colors.black),
                                    ),
                                  ),

                                // HP ve Guc - altta
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  right: 4,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // HP
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withAlpha(150),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.favorite, size: 8, color: _getHealthColor(g.health)),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${g.health}',
                                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: _getHealthColor(g.health)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Guc
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withAlpha(150),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.flash_on, size: 8, color: accentColor),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${g.overallPower}',
                                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: accentColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Isim - altta
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            color: Colors.black.withAlpha(80),
                            child: Text(
                              g.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? accentColor : GameConstants.textLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Buton
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedGladiatorId != null
                  ? () {
                      currentDialogue = PreFightDialogueHelper.getRandomDialogue();
                      setState(() => showDialogue = true);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                disabledBackgroundColor: GameConstants.cardBorder,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                widget.isArena ? 'ARENAYA GIR' : 'SAVASA GIR',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(dynamic g, Color accentColor) {
    return Container(
      color: accentColor.withAlpha(30),
      child: Center(
        child: Text(
          g.name[0],
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
      ),
    );
  }

  Color _getHealthColor(int health) {
    if (health > 50) return GameConstants.success;
    if (health > 25) return GameConstants.gold;
    return GameConstants.danger;
  }

  Widget _buildDialogueView(BuildContext context, Color accentColor) {
    final gladiator = widget.availableGladiators.firstWhere((g) => g.id == selectedGladiatorId) as Gladiator;
    final dialogue = currentDialogue!;
    final options = List<Map<String, dynamic>>.from(dialogue['options']);

    // Sike secenegi ekle (sadece yeralti icin)
    if (!widget.isArena) {
      final riggedOption = PreFightDialogueHelper.getRiggedOption();
      if (riggedOption != null) {
        options.add(riggedOption);
      }
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: GameConstants.primaryDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: DialogueComponent(
          speakerName: gladiator.name,
          speakerTitle: 'Gladyatorun',
          speakerImage: gladiator.imagePath,
          dialogueText: dialogue['text'],
          accentColor: accentColor,
          options: options.map((opt) => DialogueOption(
            text: opt['text'],
            morale: opt['morale'] ?? 0,
          )).toList(),
          onOptionSelected: (morale) {
            moraleBonus = morale;
            Navigator.pop(context);
            _startFight(context, gladiator);
          },
        ),
      ),
    );
  }

  void _startFight(BuildContext context, Gladiator gladiator) {
    final reward = widget.fighter['reward'] ?? 0;
    final reputationReward = widget.fighter['reputation_reward'] ?? 0;
    final enemyName = widget.fighter['name'] ?? 'Rakip';

    // Bahis miktarini dus (yeralti icin)
    if (widget.betAmount > 0) {
      widget.game.state.modifyGold(-widget.betAmount);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FightScreen(
          player: gladiator,
          enemyName: enemyName,
          enemyTitle: widget.fighter['title'] ?? '',
          enemyImage: widget.fighter['image'],
          enemyHealth: widget.fighter['health'] ?? 50,
          enemyStrength: widget.fighter['strength'] ?? 50,
          enemyIntelligence: widget.fighter['intelligence'] ?? 50,
          enemyStamina: widget.fighter['stamina'] ?? 50,
          goldReward: widget.isArena ? reward : (reward + widget.betAmount),
          reputationReward: widget.isArena ? reputationReward : 0,
          fightType: widget.isArena ? 'arena' : 'underground',
          moraleBonus: moraleBonus,
          onFightEnd: (outcome) {
            // Sonuclari uygula
            if (outcome.playerWon) {
              widget.game.state.modifyGold(outcome.goldReward);
              widget.game.state.modifyReputation(outcome.reputationReward);
              // Bahis kazanildiysa 2x ver
              if (widget.betAmount > 0) {
                widget.game.state.modifyGold(widget.betAmount);
              }
            }

            // Hasar uygula
            gladiator.takeDamage(outcome.playerDamage);

            // Olum kontrolu
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

// YERALTI - BAHIS VE SAVASCI SECIM EKRANI
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

  @override
  Widget build(BuildContext context) {
    final accentColor = GameConstants.bloodRed;
    final maxBet = widget.game.state.gold;

    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameConstants.primaryDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: accentColor.withAlpha(60)),
      ),
      child: Column(
        children: [
          // Baslik
          Text(
            '${widget.fighter['name']}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor),
          ),
          Text(
            'ile savasacaksin',
            style: TextStyle(fontSize: 11, color: GameConstants.textMuted),
          ),

          const SizedBox(height: 16),

          // BAHIS BOLUMU
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
                        Text('BAHIS', style: TextStyle(fontSize: 11, color: GameConstants.textMuted)),
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
                    'Kazanirsan: +${betAmount * 2} (2x)',
                    style: TextStyle(fontSize: 12, color: GameConstants.success, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Gladyator secim ekranini ac
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (ctx) => _GladiatorSelectionSheet(
                    fighter: widget.fighter,
                    game: widget.game,
                    availableGladiators: widget.availableGladiators,
                    isArena: false,
                    betAmount: betAmount,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                betAmount > 0 ? 'DEVAM (Bahis: $betAmount)' : 'DEVAM',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
