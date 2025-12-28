import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../gladiator_game.dart';
import '../models/gladiator.dart';
import '../models/game_state.dart';
import '../constants.dart';
import '../services/save_service.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  Map<String, dynamic>? weekData;
  bool isLoading = true;
  int selectedTab = 0; // 0: Köleler, 1: Personel
  final PageController _slaveController = PageController(viewportFraction: 0.5);
  final PageController _staffController = PageController(viewportFraction: 0.6);

  // Satın alınan köleler ve personel (bu oturumda)
  final Set<String> _purchasedSlaves = {};
  final Set<String> _purchasedStaff = {};

  @override
  void initState() {
    super.initState();
    _loadMarketData();
  }

  Future<void> _loadMarketData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/market_weeks.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      final weeks = data['market_weeks'] as List;

      // Mevcut haftaya göre veri al (döngüsel)
      final game = Provider.of<GladiatorGame>(context, listen: false);
      final currentWeek = game.state.week;
      final weekIndex = (currentWeek - 1) % weeks.length;

      setState(() {
        weekData = weeks[weekIndex];
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
              // Arka plan görseli
              Positioned.fill(
                child: Image.asset(
                  'assets/pazar.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          GameConstants.primaryBrown.withAlpha(100),
                          GameConstants.primaryDark,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Güneş efekti
              Positioned(
                top: -80,
                left: -30,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFD700).withAlpha(50),
                        const Color(0xFFFF8C00).withAlpha(25),
                        Colors.transparent,
                      ],
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

                    const SizedBox(height: 12),

                    // Hafta başlığı
                    if (weekData != null) ...[
                      Text(
                        'HAFTA ${game.state.week}',
                        style: TextStyle(
                          fontSize: 12,
                          color: GameConstants.textMuted,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        weekData!['title'] ?? 'PAZAR',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: GameConstants.gold,
                          letterSpacing: 3,
                          shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                        ),
                      ),
                      Text(
                        weekData!['description'] ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: GameConstants.textMuted,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Tab seçimi
                    _buildTabSelector(),

                    // Boşluk - arka plan görünsün
                    const Spacer(),

                    // Alt kısımda kartlar
                    if (isLoading)
                      Center(child: CircularProgressIndicator(color: GameConstants.gold))
                    else if (weekData != null)
                      selectedTab == 0
                          ? _buildSlaveCards(game)
                          : _buildStaffCards(game),

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
            'PAZAR',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: GameConstants.gold,
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

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildTab(0, Icons.sports_mma, 'Köleler', GameConstants.gold),
          _buildTab(1, Icons.people, 'Personel', GameConstants.copper),
        ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label, Color color) {
    final isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.black : GameConstants.textMuted),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : GameConstants.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlaveCards(GladiatorGame game) {
    final allSlaves = weekData!['slaves'] as List? ?? [];
    // Satın alınmamış köleleri filtrele
    final slaves = allSlaves.where((s) => !_purchasedSlaves.contains(s['id'])).toList();

    if (slaves.isEmpty) {
      return Container(
        height: 320,
        alignment: Alignment.center,
        child: Text('Tüm köleler satın alındı!', style: TextStyle(color: GameConstants.textMuted)),
      );
    }

    return SizedBox(
      height: 320,
      child: PageView.builder(
        controller: _slaveController,
        itemCount: slaves.length,
        itemBuilder: (context, index) {
          final slave = slaves[index];
          return _SlaveCard(
            slave: slave,
            game: game,
            index: index + 1,
            total: slaves.length,
            onPurchased: () {
              setState(() {
                _purchasedSlaves.add(slave['id']);
              });
              _showPurchasePopup(context, slave['name'], true);
            },
            onFailed: () {
              _showPurchasePopup(context, slave['name'], false);
            },
          );
        },
      ),
    );
  }

  // Özel satın alma popup'ı
  void _showPurchasePopup(BuildContext context, String name, bool success) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: GameConstants.primaryDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: success ? GameConstants.gold : GameConstants.danger,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (success ? GameConstants.gold : GameConstants.danger).withAlpha(50),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? GameConstants.gold : GameConstants.danger,
                size: 50,
              ),
              const SizedBox(height: 12),
              Text(
                success ? 'SATIN ALINDI!' : 'BAŞARISIZ!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: success ? GameConstants.gold : GameConstants.danger,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                success ? '$name artık senin!' : 'Yeterli altın yok!',
                style: TextStyle(
                  fontSize: 14,
                  color: GameConstants.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  decoration: BoxDecoration(
                    color: success ? GameConstants.gold : GameConstants.danger,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'TAMAM',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffCards(GladiatorGame game) {
    final allStaff = weekData!['staff'] as List? ?? [];
    // Satın alınmamış personeli filtrele
    final staff = allStaff.where((s) => !_purchasedStaff.contains(s['id'])).toList();

    if (staff.isEmpty) {
      return Container(
        height: 280,
        alignment: Alignment.center,
        child: Text('Tüm personel işe alındı!', style: TextStyle(color: GameConstants.textMuted)),
      );
    }

    return SizedBox(
      height: 280,
      child: PageView.builder(
        controller: _staffController,
        itemCount: staff.length,
        itemBuilder: (context, index) {
          final s = staff[index];
          return _StaffCard(
            staff: s,
            game: game,
            index: index + 1,
            total: staff.length,
            onPurchased: () {
              setState(() {
                _purchasedStaff.add(s['id']);
              });
              _showPurchasePopup(context, s['name'], true);
            },
            onFailed: () {
              _showPurchasePopup(context, s['name'], false);
            },
          );
        },
      ),
    );
  }
}

// Köle kartı
class _SlaveCard extends StatelessWidget {
  final Map<String, dynamic> slave;
  final GladiatorGame game;
  final int index;
  final int total;
  final VoidCallback onPurchased;
  final VoidCallback onFailed;

  const _SlaveCard({
    required this.slave,
    required this.game,
    required this.index,
    required this.total,
    required this.onPurchased,
    required this.onFailed,
  });

  @override
  Widget build(BuildContext context) {
    final price = slave['price'] ?? 0;
    final canAfford = game.state.gold >= price;
    final String? imagePath = slave['image'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: canAfford ? GameConstants.gold.withAlpha(100) : GameConstants.cardBorder,
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
                  if (imagePath != null)
                    Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: GameConstants.bloodRed.withAlpha(30),
                        child: Icon(Icons.person, size: 50, color: GameConstants.bloodRed.withAlpha(100)),
                      ),
                    )
                  else
                    Container(
                      color: GameConstants.bloodRed.withAlpha(30),
                      child: Icon(Icons.person, size: 50, color: GameConstants.bloodRed.withAlpha(100)),
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
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bilgiler
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // İsim ve köken
                  Text(
                    slave['name'] ?? 'Bilinmeyen',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: GameConstants.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${slave['origin'] ?? ''} | ${slave['age'] ?? 0} yaş',
                    style: TextStyle(fontSize: 9, color: GameConstants.textMuted),
                  ),

                  const SizedBox(height: 4),

                  // Statlar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMiniStat(Icons.favorite, slave['health'] ?? 0, Colors.red),
                      _buildMiniStat(Icons.flash_on, slave['strength'] ?? 0, Colors.orange),
                      _buildMiniStat(Icons.psychology, slave['intelligence'] ?? 0, Colors.blue),
                      _buildMiniStat(Icons.directions_run, slave['stamina'] ?? 0, Colors.green),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Fiyat
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.paid, color: GameConstants.gold, size: 11),
                      const SizedBox(width: 2),
                      Text(
                        '$price',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: canAfford ? GameConstants.gold : GameConstants.danger,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Satın al butonu
                  GestureDetector(
                    onTap: canAfford ? () => _buySlave(context) : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: canAfford ? GameConstants.gold : GameConstants.cardBorder,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SATIN AL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: canAfford ? Colors.black : GameConstants.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
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

  void _buySlave(BuildContext context) {
    final gladiator = Gladiator(
      id: 'glad_${DateTime.now().millisecondsSinceEpoch}',
      name: slave['name'] ?? 'Köle',
      health: slave['health'] ?? 100,
      strength: slave['strength'] ?? 30,
      intelligence: slave['intelligence'] ?? 30,
      stamina: slave['stamina'] ?? 30,
      age: slave['age'] ?? 25,
      origin: slave['origin'] ?? 'Roma',
      salary: 50,
      morale: 40,
    );

    final price = slave['price'] ?? 0;
    final success = game.buyGladiator(gladiator, price);

    if (success) {
      SaveService.autoSave(game.state);
      onPurchased();
    } else {
      onFailed();
    }
  }
}

// Personel kartı
class _StaffCard extends StatelessWidget {
  final Map<String, dynamic> staff;
  final GladiatorGame game;
  final int index;
  final int total;
  final VoidCallback onPurchased;
  final VoidCallback onFailed;

  const _StaffCard({
    required this.staff,
    required this.game,
    required this.index,
    required this.total,
    required this.onPurchased,
    required this.onFailed,
  });

  @override
  Widget build(BuildContext context) {
    final price = staff['price'] ?? 0;
    final canAfford = game.state.gold >= price;
    final role = staff['role'] ?? 'trainer';
    final isDoctor = role == 'doctor';
    final alreadyHas = game.state.staff.any((s) =>
      (isDoctor && s.role == StaffRole.doctor) || (!isDoctor && s.role == StaffRole.trainer)
    );
    final String? imagePath = staff['image'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: alreadyHas
              ? GameConstants.success.withAlpha(100)
              : (canAfford ? GameConstants.copper.withAlpha(100) : GameConstants.cardBorder),
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
                  if (imagePath != null)
                    Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: GameConstants.copper.withAlpha(30),
                        child: Icon(
                          isDoctor ? Icons.local_hospital : Icons.fitness_center,
                          size: 50,
                          color: GameConstants.copper.withAlpha(100),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: GameConstants.copper.withAlpha(30),
                      child: Icon(
                        isDoctor ? Icons.local_hospital : Icons.fitness_center,
                        size: 50,
                        color: GameConstants.copper.withAlpha(100),
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
                        color: GameConstants.copper,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$index/$total',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ),

                  // Rol badge
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDoctor ? Colors.red.withAlpha(200) : Colors.blue.withAlpha(200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isDoctor ? 'DOKTOR' : 'EĞİTMEN',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bilgiler
            Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  // İsim
                  Text(
                    staff['name'] ?? 'Bilinmeyen',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: GameConstants.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    staff['description'] ?? '',
                    style: TextStyle(fontSize: 9, color: GameConstants.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Bonus ve maaş
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            '+${staff['bonus'] ?? 0}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: GameConstants.success),
                          ),
                          Text(
                            isDoctor ? 'Tedavi' : 'Eğitim',
                            style: TextStyle(fontSize: 9, color: GameConstants.textMuted),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 25, color: GameConstants.cardBorder),
                      Column(
                        children: [
                          Text(
                            '${staff['salary'] ?? 0}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: GameConstants.gold),
                          ),
                          Text('Haftalık', style: TextStyle(fontSize: 9, color: GameConstants.textMuted)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // İşe al / Mevcut butonu
                  if (alreadyHas)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: GameConstants.success.withAlpha(50),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'MEVCUT',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GameConstants.success),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: canAfford ? () => _hireStaff(context) : null,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: canAfford ? GameConstants.copper : GameConstants.cardBorder,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'İŞE AL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: canAfford ? Colors.black : GameConstants.textMuted,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.paid, size: 11, color: canAfford ? Colors.black : GameConstants.textMuted),
                            Text(
                              '$price',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: canAfford ? Colors.black : GameConstants.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _hireStaff(BuildContext context) {
    final role = staff['role'] ?? 'trainer';
    final isDoctor = role == 'doctor';

    final staffObj = Staff(
      id: 'staff_${DateTime.now().millisecondsSinceEpoch}',
      name: staff['name'] ?? 'Personel',
      role: isDoctor ? StaffRole.doctor : StaffRole.trainer,
      salary: staff['salary'] ?? 30,
      skill: staff['skill'] ?? 50,
      bonus: staff['bonus'] ?? 0,
      description: staff['description'] ?? '',
    );

    final price = staff['price'] ?? 0;
    final success = game.hireStaffWithPrice(staffObj, price);

    if (success) {
      SaveService.autoSave(game.state);
      onPurchased();
    } else {
      onFailed();
    }
  }
}
