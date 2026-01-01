import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../gladiator_game.dart';
import '../constants.dart';
import '../services/save_service.dart';

class SchoolScreen extends StatefulWidget {
  const SchoolScreen({super.key});

  @override
  State<SchoolScreen> createState() => _SchoolScreenState();
}

class _SchoolScreenState extends State<SchoolScreen> {
  Map<String, dynamic>? schoolData;
  bool isLoading = true;
  int selectedTab = 0; // 0: Gladyatörler, 1: Domina, 2: Doctore, 3: Doktor
  final PageController _gladiatorController = PageController(viewportFraction: 0.55);
  int _doctoreDialogueIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSchoolData();
  }

  Future<void> _loadSchoolData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/school_data.json');
      final data = json.decode(jsonString);
      setState(() {
        schoolData = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('School data yukleme hatasi: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GladiatorGame>(
      builder: (context, game, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Arka plan
              Positioned.fill(
                child: Image.asset(
                  'assets/okul.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    color: GameConstants.primaryDark,
                  ),
                ),
              ),

              // Hafif karartma - arka plan gorunsun
              Positioned.fill(
                child: Container(
                  color: Colors.black.withAlpha(100),
                ),
              ),

              // Icerik
              SafeArea(
                child: Column(
                  children: [
                    // Ust bar - minimal
                    _buildTopBar(context, game),

                    const SizedBox(height: 8),

                    // Tab secici - minimal
                    _buildTabSelector(),

                    // Icerik
                    Expanded(
                      child: isLoading
                          ? Center(child: CircularProgressIndicator(color: GameConstants.gold))
                          : _buildContent(game),
                    ),
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_back, color: GameConstants.textLight, size: 20),
            ),
          ),

          const Spacer(),

          // Altin
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(120),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.paid, color: GameConstants.gold, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${game.state.gold}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GameConstants.gold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTab(0, 'Gladyatorler', Icons.sports_mma),
            const SizedBox(width: 6),
            _buildTab(1, 'Domina', Icons.favorite),
            const SizedBox(width: 6),
            _buildTab(2, 'Doctore', Icons.fitness_center),
            const SizedBox(width: 6),
            _buildTab(3, 'Doktor', Icons.healing),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon) {
    final isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? GameConstants.gold.withAlpha(40) : Colors.black.withAlpha(100),
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: GameConstants.gold.withAlpha(80)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? GameConstants.gold : GameConstants.textMuted, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? GameConstants.gold : GameConstants.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(GladiatorGame game) {
    if (schoolData == null) return const SizedBox();

    switch (selectedTab) {
      case 0:
        return _buildGladiatorsSection(game);
      case 1:
        return _buildDominaSection(game);
      case 2:
        return _buildDoctoreSection(game);
      case 3:
        return _buildDoctorSection(game);
      default:
        return const SizedBox();
    }
  }

  // === GLADYATORLER - KART TASARIMI ===
  Widget _buildGladiatorsSection(GladiatorGame game) {
    if (game.state.gladiators.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_mma, color: GameConstants.textMuted.withAlpha(100), size: 60),
            const SizedBox(height: 12),
            Text('Gladyator yok', style: TextStyle(color: GameConstants.textMuted, fontSize: 16)),
          ],
        ),
      );
    }

    final feasts = schoolData!['feasts'] as List? ?? [];

    return Column(
      children: [
        const SizedBox(height: 12),

        // Ziyafet bolumu - kompakt
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(120),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.restaurant, color: GameConstants.warmOrange, size: 16),
                  const SizedBox(width: 6),
                  Text('ZIYAFET', style: TextStyle(fontSize: 11, color: GameConstants.textMuted, letterSpacing: 1)),
                  const Spacer(),
                  Text(
                    'Ort. Moral: ${game.state.gladiators.isNotEmpty ? (game.state.gladiators.map((g) => g.morale).reduce((a, b) => a + b) / game.state.gladiators.length).round() : 0}',
                    style: TextStyle(fontSize: 11, color: GameConstants.gold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: feasts.map<Widget>((feast) {
                  final price = feast['price'] ?? 0;
                  final bonus = feast['morale_bonus'] ?? 0;
                  final canAfford = game.state.gold >= price;
                  return Expanded(
                    child: GestureDetector(
                      onTap: canAfford ? () => _giveFeast(game, price, bonus, feast['name']) : null,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: canAfford ? GameConstants.warmOrange.withAlpha(30) : Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: canAfford ? GameConstants.warmOrange.withAlpha(60) : Colors.transparent),
                        ),
                        child: Column(
                          children: [
                            Text('+$bonus', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: canAfford ? GameConstants.warmOrange : GameConstants.textMuted)),
                            Text('$price g', style: TextStyle(fontSize: 10, color: canAfford ? GameConstants.gold : GameConstants.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Gladyator kartlari - swipeable
        Expanded(
          child: PageView.builder(
            controller: _gladiatorController,
            itemCount: game.state.gladiators.length,
            itemBuilder: (context, index) {
              final gladiator = game.state.gladiators[index];
              return _buildGladiatorCard(gladiator, game, index);
            },
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGladiatorCard(dynamic gladiator, GladiatorGame game, int index) {
    final bool isInjured = gladiator.isInjured;
    final Color accentColor = GameConstants.bloodRed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInjured ? GameConstants.danger.withAlpha(100) : accentColor.withAlpha(100),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Görsel
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Asker görseli
                  Image.asset(
                    'assets/defaultasker.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: accentColor.withAlpha(30),
                      child: Icon(Icons.person, size: 50, color: accentColor.withAlpha(100)),
                    ),
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
                        '${index + 1}/${game.state.gladiators.length}',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),

                  // Yaralı badge
                  if (isInjured)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: GameConstants.danger,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.healing, size: 12, color: Colors.white),
                      ),
                    ),

                  // Maaş
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(150),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.paid, color: GameConstants.gold, size: 10),
                          const SizedBox(width: 2),
                          Text('${gladiator.salary}/h', style: TextStyle(fontSize: 9, color: GameConstants.gold)),
                        ],
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
                    gladiator.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: GameConstants.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    gladiator.origin ?? '',
                    style: TextStyle(
                      fontSize: 9,
                      color: accentColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Statlar - küçük ikonlarla
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMiniStat(Icons.favorite, gladiator.health, GameConstants.healthColor),
                      _buildMiniStat(Icons.flash_on, gladiator.strength, GameConstants.strengthColor),
                      _buildMiniStat(Icons.psychology, gladiator.intelligence, GameConstants.intelligenceColor),
                      _buildMiniStat(Icons.directions_run, gladiator.stamina, GameConstants.staminaColor),
                      _buildMiniStat(Icons.mood, gladiator.morale, GameConstants.gold),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Aksiyonlar
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: gladiator.canTrain ? () => _showTrainDialog(gladiator, game) : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: gladiator.canTrain ? GameConstants.strengthColor : Colors.black26,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'EĞİT',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: gladiator.canTrain ? Colors.black : GameConstants.textMuted),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showFireDialog(gladiator, game),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: GameConstants.danger.withAlpha(80),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'KOV',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: GameConstants.danger),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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

  // === DOMINA BOLUMU ===
  Widget _buildDominaSection(GladiatorGame game) {
    final wife = schoolData!['wife'];
    final dialogues = wife['dialogues'] as List;
    final gifts = wife['gifts'] as List;
    final currentDialogue = dialogues[game.state.dialogueIndex % dialogues.length];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Kart
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(150),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GameConstants.copper.withAlpha(60)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Foto
                    Container(
                      width: 80,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: GameConstants.copper.withAlpha(60)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.asset(
                          wife['image'] ?? 'assets/karin.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: GameConstants.copper.withAlpha(30),
                            child: Icon(Icons.person, color: GameConstants.copper, size: 40),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(game.state.wifeName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GameConstants.textLight)),
                          Text(wife['title'] ?? 'Domina', style: TextStyle(fontSize: 11, color: GameConstants.copper)),

                          const SizedBox(height: 10),

                          // Moral bar
                          Row(
                            children: [
                              Icon(Icons.favorite, color: Colors.pink, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(height: 8, decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(4))),
                                    FractionallySizedBox(
                                      widthFactor: game.state.wifeMorale / 100,
                                      child: Container(height: 8, decoration: BoxDecoration(color: Colors.pink, borderRadius: BorderRadius.circular(4))),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('${game.state.wifeMorale}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.pink)),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Cocuk durumu
                          if (game.state.hasChild)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: GameConstants.success.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.child_care, color: GameConstants.success, size: 12),
                                  const SizedBox(width: 4),
                                  Text('VARIS DOGDU', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: GameConstants.success)),
                                ],
                              ),
                            )
                          else if (game.state.wifeMorale >= 100)
                            GestureDetector(
                              onTap: () => _tryForChild(game),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.pink.withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.pink.withAlpha(60)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.child_care, color: Colors.pink, size: 12),
                                    const SizedBox(width: 4),
                                    Text('VARIS ICIN HAZIR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.pink)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Diyalog
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '"${currentDialogue['text']}"',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: GameConstants.textLight, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Hediyeler
          ...gifts.map((gift) => _buildGiftRow(gift, game)),
        ],
      ),
    );
  }

  Widget _buildGiftRow(Map<String, dynamic> gift, GladiatorGame game) {
    final price = gift['price'] ?? 0;
    final bonus = gift['morale_bonus'] ?? 0;
    final canAfford = game.state.gold >= price;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(120),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: canAfford ? GameConstants.copper.withAlpha(40) : Colors.transparent),
      ),
      child: Row(
        children: [
          Icon(Icons.card_giftcard, color: Colors.pink.withAlpha(canAfford ? 255 : 100), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gift['name'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: canAfford ? GameConstants.textLight : GameConstants.textMuted)),
                Text(gift['description'] ?? '', style: TextStyle(fontSize: 10, color: GameConstants.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.pink.withAlpha(20), borderRadius: BorderRadius.circular(4)),
            child: Text('+$bonus', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.pink)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: canAfford ? () => _giveGift(game, price, bonus, gift['name']) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: canAfford ? GameConstants.gold : Colors.black26,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('$price', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: canAfford ? Colors.black : GameConstants.textMuted)),
            ),
          ),
        ],
      ),
    );
  }

  // === DOCTORE BOLUMU ===
  Widget _buildDoctoreSection(GladiatorGame game) {
    final doctore = schoolData!['doctore'];
    final dialogues = doctore['dialogues'] as List;
    final currentDialogue = dialogues[_doctoreDialogueIndex % dialogues.length];

    // Egitmen var mi kontrol et
    final hasTrainer = game.state.staff.any((s) => s.role.toString().contains('trainer'));

    // Beslenme fiyatlari
    const foodPrice = 15;
    const waterPrice = 10;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Kart
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(150),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GameConstants.strengthColor.withAlpha(60)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: GameConstants.strengthColor.withAlpha(60)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.asset(
                          doctore['image'] ?? 'assets/doctore.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: GameConstants.strengthColor.withAlpha(30),
                            child: Icon(Icons.fitness_center, color: GameConstants.strengthColor, size: 40),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doctore['name'] ?? 'Doctore', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GameConstants.textLight)),
                          Text(doctore['title'] ?? 'Egitmen', style: TextStyle(fontSize: 11, color: GameConstants.strengthColor)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: hasTrainer ? GameConstants.success.withAlpha(30) : GameConstants.danger.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              hasTrainer ? 'GOREVDE' : 'ISE ALINMADI',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: hasTrainer ? GameConstants.success : GameConstants.danger),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Diyalog
                GestureDetector(
                  onTap: () => setState(() => _doctoreDialogueIndex++),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '"${currentDialogue['text']}"',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: GameConstants.textLight, height: 1.3),
                        ),
                        const SizedBox(height: 6),
                        Text('(Dokun - sonraki sozler)', style: TextStyle(fontSize: 9, color: GameConstants.textMuted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Beslenme Yonetimi Basligi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: GameConstants.warmOrange.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GameConstants.warmOrange.withAlpha(60)),
            ),
            child: Row(
              children: [
                Icon(Icons.restaurant, color: GameConstants.warmOrange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ANTRENMAN BESLENMESI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GameConstants.warmOrange, letterSpacing: 1)),
                      Text('Yemek +2, Su +1 egitim bonusu (haftalik)', style: TextStyle(fontSize: 9, color: GameConstants.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Gladyator listesi - beslenme secimi
          if (game.state.gladiators.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              child: Text('Gladyator yok', style: TextStyle(color: GameConstants.textMuted)),
            )
          else
            ...game.state.gladiators.map((gladiator) => _buildNutritionRow(gladiator, game, foodPrice, waterPrice)),

          const SizedBox(height: 16),

          // Bilgi
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(100),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: GameConstants.textMuted, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasTrainer
                        ? 'Doctore gladyatorlerini egitmene yardimci oluyor. Egitim bonusu: +2\nBeslenme bonuslari hafta sonunda sifirlanir.'
                        : 'Pazardan bir egitmen ise alarak gladyatorlerini daha hizli gelistirebilirsin.',
                    style: TextStyle(fontSize: 11, color: GameConstants.textMuted, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(dynamic gladiator, GladiatorGame game, int foodPrice, int waterPrice) {
    final canAffordFood = game.state.gold >= foodPrice;
    final canAffordWater = game.state.gold >= waterPrice;
    final totalBonus = gladiator.nutritionBonus;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(120),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: totalBonus > 0 ? GameConstants.warmOrange.withAlpha(60) : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          // Gladyator ismi ve bonus
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: GameConstants.bloodRed.withAlpha(30),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/defaultasker.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.person, color: GameConstants.bloodRed, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gladiator.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: GameConstants.textLight)),
                    Text(gladiator.origin ?? '', style: TextStyle(fontSize: 9, color: GameConstants.textMuted)),
                  ],
                ),
              ),
              if (totalBonus > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: GameConstants.success.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('+$totalBonus', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GameConstants.success)),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Yemek ve Su butonlari
          Row(
            children: [
              // Yemek
              Expanded(
                child: GestureDetector(
                  onTap: gladiator.hasFood
                      ? null
                      : canAffordFood
                          ? () {
                              final success = game.buyFood(gladiator.id, foodPrice);
                              if (success) {
                                SaveService.autoSave(game.state);
                                _showPopup('Yemek', true, '${gladiator.name} icin yemek alindi (+2 egitim)');
                              }
                            }
                          : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: gladiator.hasFood
                          ? GameConstants.success.withAlpha(40)
                          : canAffordFood
                              ? GameConstants.warmOrange.withAlpha(30)
                              : Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: gladiator.hasFood
                            ? GameConstants.success.withAlpha(80)
                            : canAffordFood
                                ? GameConstants.warmOrange.withAlpha(60)
                                : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          gladiator.hasFood ? Icons.check_circle : Icons.restaurant,
                          size: 14,
                          color: gladiator.hasFood
                              ? GameConstants.success
                              : canAffordFood
                                  ? GameConstants.warmOrange
                                  : GameConstants.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          gladiator.hasFood ? 'YEMEK OK' : 'YEMEK ($foodPrice)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: gladiator.hasFood
                                ? GameConstants.success
                                : canAffordFood
                                    ? GameConstants.warmOrange
                                    : GameConstants.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Su
              Expanded(
                child: GestureDetector(
                  onTap: gladiator.hasWater
                      ? null
                      : canAffordWater
                          ? () {
                              final success = game.buyWater(gladiator.id, waterPrice);
                              if (success) {
                                SaveService.autoSave(game.state);
                                _showPopup('Su', true, '${gladiator.name} icin su alindi (+1 egitim)');
                              }
                            }
                          : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: gladiator.hasWater
                          ? GameConstants.success.withAlpha(40)
                          : canAffordWater
                              ? Colors.blue.withAlpha(30)
                              : Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: gladiator.hasWater
                            ? GameConstants.success.withAlpha(80)
                            : canAffordWater
                                ? Colors.blue.withAlpha(60)
                                : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          gladiator.hasWater ? Icons.check_circle : Icons.water_drop,
                          size: 14,
                          color: gladiator.hasWater
                              ? GameConstants.success
                              : canAffordWater
                                  ? Colors.blue
                                  : GameConstants.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          gladiator.hasWater ? 'SU OK' : 'SU ($waterPrice)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: gladiator.hasWater
                                ? GameConstants.success
                                : canAffordWater
                                    ? Colors.blue
                                    : GameConstants.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // === DOKTOR BOLUMU ===
  Widget _buildDoctorSection(GladiatorGame game) {
    final doctor = schoolData!['doctor'];
    final medicines = doctor['medicines'] as List;

    // Doktor var mi kontrol et
    final hasDoctor = game.state.staff.any((s) => s.role.toString().contains('doctor'));

    // Yarali gladyatorler
    final injuredGladiators = game.state.gladiators.where((g) => g.health < 100).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Kart
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(150),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GameConstants.healthColor.withAlpha(60)),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GameConstants.healthColor.withAlpha(60)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      doctor['image'] ?? 'assets/doktor.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: GameConstants.healthColor.withAlpha(30),
                        child: Icon(Icons.healing, color: GameConstants.healthColor, size: 40),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctor['name'] ?? 'Medicus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GameConstants.textLight)),
                      Text(doctor['title'] ?? 'Doktor', style: TextStyle(fontSize: 11, color: GameConstants.healthColor)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasDoctor ? GameConstants.success.withAlpha(30) : GameConstants.danger.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          hasDoctor ? 'GOREVDE (+15 bonus)' : 'ISE ALINMADI',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: hasDoctor ? GameConstants.success : GameConstants.danger),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${injuredGladiators.length} yarali gladyator',
                        style: TextStyle(fontSize: 11, color: injuredGladiators.isNotEmpty ? GameConstants.danger : GameConstants.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Ilaclar
          Text('ILAC & BITKILER', style: TextStyle(fontSize: 11, color: GameConstants.textMuted, letterSpacing: 1)),
          const SizedBox(height: 8),

          ...medicines.map((med) => _buildMedicineRow(med, game, injuredGladiators)),
        ],
      ),
    );
  }

  Widget _buildMedicineRow(Map<String, dynamic> med, GladiatorGame game, List injuredGladiators) {
    final price = med['price'] ?? 0;
    final heal = med['heal_amount'] ?? 0;
    final canAfford = game.state.gold >= price;
    final hasInjured = injuredGladiators.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(120),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: canAfford && hasInjured ? GameConstants.healthColor.withAlpha(40) : Colors.transparent),
      ),
      child: Row(
        children: [
          Icon(Icons.local_pharmacy, color: GameConstants.healthColor.withAlpha(canAfford && hasInjured ? 255 : 100), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med['name'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: canAfford ? GameConstants.textLight : GameConstants.textMuted)),
                Text(med['description'] ?? '', style: TextStyle(fontSize: 10, color: GameConstants.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: GameConstants.healthColor.withAlpha(20), borderRadius: BorderRadius.circular(4)),
            child: Text('+$heal HP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GameConstants.healthColor)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: canAfford && hasInjured ? () => _showHealDialog(game, price, heal, med['name'], injuredGladiators) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: canAfford && hasInjured ? GameConstants.healthColor : Colors.black26,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('$price', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: canAfford && hasInjured ? Colors.white : GameConstants.textMuted)),
            ),
          ),
        ],
      ),
    );
  }

  // === AKSIYONLAR ===
  void _giveFeast(GladiatorGame game, int price, int bonus, String name) {
    final success = game.giveFeast(price, bonus);
    if (success) _showPopup('Ziyafet', true, 'Tum gladyatorlere +$bonus Moral');
  }

  void _giveGift(GladiatorGame game, int price, int bonus, String name) {
    final success = game.giveGiftToWife(price, bonus);
    if (success) _showPopup(name, true, 'Domina\'nin morali +$bonus');
  }

  void _tryForChild(GladiatorGame game) {
    final child = game.tryForChild();
    if (child != null) {
      final genderText = child.isMale ? 'erkek' : 'kız';
      _showPopup('VARIS', true, 'Bir $genderText cocugunuz oldu: ${child.name}! +50 Itibar');
    }
  }

  void _showTrainDialog(dynamic gladiator, GladiatorGame game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GameConstants.primaryDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('EGITIM SEC', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GameConstants.gold)),
            const SizedBox(height: 12),
            _buildTrainOption('Guc', 'strength', GameConstants.strengthColor, gladiator, game, ctx),
            _buildTrainOption('Zeka', 'intelligence', GameConstants.intelligenceColor, gladiator, game, ctx),
            _buildTrainOption('Kondisyon', 'stamina', GameConstants.staminaColor, gladiator, game, ctx),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainOption(String label, String stat, Color color, dynamic gladiator, GladiatorGame game, BuildContext ctx) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        final success = game.trainGladiator(gladiator.id, stat);
        if (success) SaveService.autoSave(game.state);
        _showPopup('Egitim', success, success ? '$label egitimi tamamlandi!' : 'Basarisiz!');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(Icons.fitness_center, color: color, size: 20),
            const SizedBox(width: 10),
            Text('$label Egitimi', style: TextStyle(fontSize: 14, color: GameConstants.textLight)),
            const Spacer(),
            Text('${GameConstants.trainingCostBase}g', style: TextStyle(fontSize: 12, color: GameConstants.gold)),
          ],
        ),
      ),
    );
  }

  void _showFireDialog(dynamic gladiator, GladiatorGame game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GameConstants.primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('KOV', style: TextStyle(color: GameConstants.danger)),
        content: Text('${gladiator.name} kovulsun mu?', style: TextStyle(color: GameConstants.textLight)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('IPTAL', style: TextStyle(color: GameConstants.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GameConstants.danger),
            onPressed: () {
              Navigator.pop(ctx);
              game.fireGladiator(gladiator.id);
            },
            child: const Text('KOV'),
          ),
        ],
      ),
    );
  }

  void _showHealDialog(GladiatorGame game, int price, int heal, String medName, List injuredGladiators) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GameConstants.primaryDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('KIMI TEDAVI ET?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GameConstants.healthColor)),
            const SizedBox(height: 12),
            ...injuredGladiators.map((g) => GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _healGladiator(game, g, price, heal, medName);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: GameConstants.healthColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: GameConstants.healthColor.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        Text(g.name, style: TextStyle(fontSize: 14, color: GameConstants.textLight)),
                        const Spacer(),
                        Text('HP: ${g.health}', style: TextStyle(fontSize: 12, color: GameConstants.danger)),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _healGladiator(GladiatorGame game, dynamic gladiator, int price, int heal, String medName) {
    final success = game.healGladiatorWithMedicine(gladiator.id, price, heal);
    if (success) {
      SaveService.autoSave(game.state);
      final hasDoctor = game.state.staff.any((s) => s.role.toString().contains('doctor'));
      final totalHeal = hasDoctor ? heal + 15 : heal;
      _showPopup(medName, true, '${gladiator.name} +$totalHeal HP');
    }
  }

  void _showPopup(String title, bool success, String message) {
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
