import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../gladiator_game.dart';
import '../constants.dart';
import '../models/gladiator.dart';
import 'fight_screen.dart';
import 'components/dialogue_component.dart' show DialogueComponent, DialogueOption, PreFightDialogueHelper;

class ColosseumScreen extends StatefulWidget {
  const ColosseumScreen({super.key});

  @override
  State<ColosseumScreen> createState() => _ColosseumScreenState();
}

class _ColosseumScreenState extends State<ColosseumScreen> {
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
      final String jsonString = await rootBundle.loadString('assets/data/colosseum_fighters.json');
      final Map<String, dynamic> data = json.decode(jsonString);

      setState(() {
        fighters = List<Map<String, dynamic>>.from(data['colosseum_fighters']);
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
        final currentWeek = game.state.week;
        final isColosseumOpen = currentWeek % 5 == 0;

        return Scaffold(
          body: Stack(
            children: [
              // Arka plan görseli
              Positioned.fill(
                child: Image.asset(
                  'assets/buyukarena.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [GameConstants.warmOrange.withAlpha(80), GameConstants.primaryDark],
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
                    _buildTopBar(context, game, isColosseumOpen, currentWeek),

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
                                return _ColosseumFighterCard(
                                  fighter: fighter,
                                  game: game,
                                  index: index + 1,
                                  total: fighters.length,
                                  currentWeek: currentWeek,
                                  isColosseumOpen: isColosseumOpen,
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

  Widget _buildTopBar(BuildContext context, GladiatorGame game, bool isOpen, int currentWeek) {
    final nextOpenWeek = ((currentWeek ~/ 5) + 1) * 5;

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

          const SizedBox(width: 8),

          // Başlık
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COLOSSEUM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GameConstants.gold,
                    letterSpacing: 2,
                    shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                  ),
                ),
                Text(
                  isOpen ? 'AÇIK!' : '$nextOpenWeek. haftada',
                  style: TextStyle(
                    fontSize: 9,
                    color: isOpen ? GameConstants.success : GameConstants.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Hafta
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOpen ? GameConstants.gold.withAlpha(40) : Colors.black.withAlpha(120),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isOpen ? GameConstants.gold : Colors.transparent),
            ),
            child: Text(
              '${game.state.week}. H',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isOpen ? GameConstants.gold : GameConstants.textLight,
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Altın
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(120),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.paid, color: GameConstants.gold, size: 14),
                const SizedBox(width: 3),
                Text(
                  '${game.state.gold}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GameConstants.gold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Colosseum Savaşçı Kartı - Arena kartı ile aynı tasarım
class _ColosseumFighterCard extends StatelessWidget {
  final Map<String, dynamic> fighter;
  final GladiatorGame game;
  final int index;
  final int total;
  final int currentWeek;
  final bool isColosseumOpen;

  const _ColosseumFighterCard({
    required this.fighter,
    required this.game,
    required this.index,
    required this.total,
    required this.currentWeek,
    required this.isColosseumOpen,
  });

  @override
  Widget build(BuildContext context) {
    final int fighterWeek = fighter['week'] ?? 5;
    final bool isUnlocked = currentWeek >= fighterWeek;
    final bool canFight = isColosseumOpen && isUnlocked;
    final bool isDefeated = fighter['defeated'] ?? false;
    final String? imagePath = fighter['image'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(isUnlocked ? 180 : 200),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: !isUnlocked
              ? GameConstants.textMuted.withAlpha(30)
              : isDefeated
                  ? GameConstants.textMuted.withAlpha(50)
                  : GameConstants.gold.withAlpha(100),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColorFiltered(
          colorFilter: !isUnlocked || isDefeated
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
                          color: GameConstants.gold.withAlpha(30),
                          child: Icon(Icons.person, size: 50, color: GameConstants.gold.withAlpha(100)),
                        ),
                      )
                    else
                      Container(
                        color: GameConstants.gold.withAlpha(30),
                        child: Icon(Icons.person, size: 50, color: GameConstants.gold.withAlpha(100)),
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
                          color: GameConstants.gold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$index/$total',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                    ),

                    // Hafta badge
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isUnlocked ? GameConstants.success : GameConstants.textMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: isUnlocked
                            ? const Icon(Icons.lock_open, size: 12, color: Colors.white)
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock, size: 10, color: Colors.white),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$fighterWeek',
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    // Kilitli overlay
                    if (!isUnlocked)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withAlpha(120),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock, size: 30, color: GameConstants.textMuted),
                                const SizedBox(height: 4),
                                Text(
                                  '$fighterWeek. HAFTA',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: GameConstants.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                        color: isUnlocked ? GameConstants.textLight : GameConstants.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      fighter['title'] ?? '',
                      style: TextStyle(
                        fontSize: 9,
                        color: isUnlocked ? GameConstants.gold : GameConstants.textMuted.withAlpha(150),
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
                    if (canFight && !isDefeated)
                      GestureDetector(
                        onTap: () => _showGladiatorSelection(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: GameConstants.gold,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SAVAŞ',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else if (isDefeated)
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
                      )
                    else if (!isUnlocked)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: GameConstants.textMuted.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'KİLİTLİ',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: GameConstants.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: GameConstants.textMuted.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'KAPALI',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: GameConstants.textMuted),
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

  void _showGladiatorSelection(BuildContext context) {
    final availableGladiators = game.state.availableForFight;

    if (availableGladiators.isEmpty) {
      _showCustomPopup(context, 'UYARI', 'Savaşabilecek gladyatör yok!', false);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ColosseumGladiatorSelectionSheet(
        fighter: fighter,
        game: game,
        availableGladiators: availableGladiators,
      ),
    );
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

// Gladyatör seçim ekranı
class _ColosseumGladiatorSelectionSheet extends StatefulWidget {
  final Map<String, dynamic> fighter;
  final GladiatorGame game;
  final List availableGladiators;

  const _ColosseumGladiatorSelectionSheet({
    required this.fighter,
    required this.game,
    required this.availableGladiators,
  });

  @override
  State<_ColosseumGladiatorSelectionSheet> createState() => _ColosseumGladiatorSelectionSheetState();
}

class _ColosseumGladiatorSelectionSheetState extends State<_ColosseumGladiatorSelectionSheet> {
  String? selectedGladiatorId;
  bool showDialogue = false;
  int moraleBonus = 0;
  Map<String, dynamic>? currentDialogue;

  @override
  void initState() {
    super.initState();
    PreFightDialogueHelper.loadDialogues();
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.fighter['reward'] ?? 0;
    final reputationReward = widget.fighter['reputation_reward'] ?? 0;
    final accentColor = GameConstants.gold;

    // Diyalog gosteriliyor mu?
    if (showDialogue && selectedGladiatorId != null) {
      return _buildDialogueView(context);
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
              child: const Text(
                'COLOSSEUM\'A GIR',
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

  Widget _buildDialogueView(BuildContext context) {
    final gladiator = widget.availableGladiators.firstWhere((g) => g.id == selectedGladiatorId) as Gladiator;
    final dialogue = currentDialogue!;
    final options = List<Map<String, dynamic>>.from(dialogue['options']);

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
          accentColor: GameConstants.gold,
          options: options.map((opt) => DialogueOption(
            text: opt['text'],
            morale: opt['morale'] ?? 0,
          )).toList(),
          onOptionSelected: (morale) {
            moraleBonus = morale;
            Navigator.pop(context);
            _startColosseumFight(context, gladiator);
          },
        ),
      ),
    );
  }

  void _startColosseumFight(BuildContext context, Gladiator gladiator) {
    final reward = widget.fighter['reward'] ?? 500;
    final reputationReward = widget.fighter['reputation_reward'] ?? 50;
    final enemyName = widget.fighter['name'] ?? 'Sampiyon';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FightScreen(
          player: gladiator,
          enemyName: enemyName,
          enemyTitle: widget.fighter['title'] ?? 'Colosseum Savascisi',
          enemyImage: widget.fighter['image'],
          enemyHealth: widget.fighter['health'] ?? 80,
          enemyStrength: widget.fighter['strength'] ?? 70,
          enemyIntelligence: widget.fighter['intelligence'] ?? 60,
          enemyStamina: widget.fighter['stamina'] ?? 70,
          goldReward: reward,
          reputationReward: reputationReward,
          fightType: 'colosseum',
          moraleBonus: moraleBonus,
          onFightEnd: (outcome) {
            // Sonuclari uygula
            if (outcome.playerWon) {
              widget.game.state.modifyGold(outcome.goldReward);
              widget.game.state.modifyReputation(outcome.reputationReward);
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
