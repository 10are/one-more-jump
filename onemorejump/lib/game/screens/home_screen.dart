import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../gladiator_game.dart';
import '../constants.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';
import 'arena_screen.dart';
import 'diplomacy_screen.dart';
import 'school_screen.dart';
import 'market_screen.dart';
import 'colosseum_screen.dart';
import 'gambling_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    // Müziği başlat
    _audioService.init().then((_) {
      _audioService.playBackgroundMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GladiatorGame>(
      builder: (context, game, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Arka plan resmi
              Positioned.fill(
                child: Image.asset(
                  'assets/unnamed.jpg',
                  fit: BoxFit.cover,
                ),
              ),

              // Güneş efekti - sağ üstten yayılan sıcak ışık
              Positioned(
                top: -100,
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFD700).withAlpha(80), // Altın sarısı
                        const Color(0xFFFF8C00).withAlpha(50), // Turuncu
                        const Color(0xFFFF4500).withAlpha(20), // Kırmızımsı
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              ),

              // İkinci güneş halkası - daha büyük ve soluk
              Positioned(
                top: -150,
                right: -100,
                child: Container(
                  width: 450,
                  height: 450,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFD700).withAlpha(30),
                        const Color(0xFFFF8C00).withAlpha(15),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // Hafif karartma overlay (güneşi engellemeyecek şekilde)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.black.withAlpha(30),  // Güneş tarafı daha açık
                        Colors.black.withAlpha(120), // Karşı taraf daha koyu
                      ],
                    ),
                  ),
                ),
              ),

              // SafeArea içindeki içerik
              SafeArea(
                child: Stack(
                  children: [
                    // Üst bar - Hafta, İtibar, Altın (en üstte ortada)
                    Positioned(
                      top: 8,
                      left: 12,
                      right: 12,
                      child: _buildTopBar(game, _audioService),
                    ),

                    // Sol üst - ARENA
                    Positioned(
                      top: 90,
                      left: 20,
                      child: _CornerIcon(
                        label: 'Arena',
                        color: GameConstants.bloodRed,
                        imagePath: 'assets/arena.png',
                        onTap: () => _navigateTo(context, game, const ArenaScreen()),
                      ),
                    ),

                    // Sağ üst - DİPLOMASİ
                    Positioned(
                      top: 90,
                      right: 20,
                      child: _CornerIcon(
                        label: 'Diplomasi',
                        color: GameConstants.bronze,
                        imagePath: 'assets/diplomasi.jpg',
                        onTap: () => _navigateTo(context, game, const DiplomacyScreen()),
                      ),
                    ),

                    // Sol alt - PAZAR
                    Positioned(
                      bottom: 100,
                      left: 20,
                      child: _CornerIcon(
                        label: 'Pazar',
                        color: GameConstants.gold,
                        imagePath: 'assets/pazar.png',
                        onTap: () => _navigateTo(context, game, const MarketScreen()),
                      ),
                    ),

                    // Orta alt - KUMAR
                    Positioned(
                      bottom: 100,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _CornerIcon(
                          label: 'Kumar',
                          color: const Color(0xFF9C27B0),
                          imagePath: 'assets/21.jpg',
                          onTap: () => _navigateTo(context, game, const GamblingScreen()),
                        ),
                      ),
                    ),

                    // Sağ alt - OKUL (LUDUS)
                    Positioned(
                      bottom: 100,
                      right: 20,
                      child: _CornerIcon(
                        label: 'Ludus',
                        color: GameConstants.copper,
                        imagePath: 'assets/okul.jpg',
                        onTap: () => _navigateTo(context, game, const SchoolScreen()),
                      ),
                    ),

                    // ORTA - COLOSSEUM (5. hafta ve katlarında açık)
                    Positioned(
                      top: 0,
                      bottom: 80,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _ColosseumIcon(
                          isOpen: game.state.week % 5 == 0,
                          currentWeek: game.state.week,
                          onTap: () => _navigateTo(context, game, const ColosseumScreen()),
                        ),
                      ),
                    ),

                    // En alt orta - HAFTA GEÇİR
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _WeekButton(
                          onTap: () => _showWeeklyExpensesSheet(context, game),
                          salary: game.state.totalWeeklySalary,
                        ),
                      ),
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

  Widget _buildTopBar(GladiatorGame game, AudioService audioService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GameConstants.primaryDark.withAlpha(200),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GameConstants.gold.withAlpha(60)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Müzik ikonu
          ListenableBuilder(
            listenable: audioService,
            builder: (context, child) {
              return GestureDetector(
                onTap: () {
                  audioService.toggleMusic();
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: audioService.isMusicEnabled
                        ? GameConstants.gold.withAlpha(30)
                        : GameConstants.danger.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: audioService.isMusicEnabled
                          ? GameConstants.gold.withAlpha(60)
                          : GameConstants.danger.withAlpha(60),
                    ),
                  ),
                  child: Icon(
                    audioService.isMusicEnabled
                        ? Icons.music_note
                        : Icons.music_off,
                    color: audioService.isMusicEnabled
                        ? GameConstants.gold
                        : GameConstants.danger,
                    size: 20,
                  ),
                ),
              );
            },
          ),

          // Hafta
          _buildStatItem('', '${game.state.week}. HAFTA', null),

          // İtibar
          _buildStatItem('İTİBAR', '${game.state.reputation}', Icons.star),

          // Altın
          _buildStatItem('ALTIN', '${game.state.gold}', Icons.paid),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData? icon) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: GameConstants.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: GameConstants.gold, size: 16),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: icon != null ? GameConstants.gold : GameConstants.textLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateTo(BuildContext context, GladiatorGame game, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: game,
          child: screen,
        ),
      ),
    );
  }

  void _showWeeklyExpensesSheet(BuildContext context, GladiatorGame game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: game,
        child: const _WeeklyExpensesSheet(),
      ),
    );
  }
}

// Haftalık masraflar sayfası
class _WeeklyExpensesSheet extends StatelessWidget {
  const _WeeklyExpensesSheet();

  @override
  Widget build(BuildContext context) {
    return Consumer<GladiatorGame>(
      builder: (context, game, child) {
        final canPayFull = game.state.gold >= game.state.totalWeeklySalary;

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: GameConstants.primaryDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: GameConstants.gold.withAlpha(60)),
          ),
          child: Column(
            children: [
              // Başlık
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GameConstants.primaryBrown,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${game.state.week}. HAFTA - MASRAFLAR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: GameConstants.gold,
                        letterSpacing: 1,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: GameConstants.textMuted),
                    ),
                  ],
                ),
              ),

              // Mevcut altın
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: GameConstants.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: GameConstants.gold.withAlpha(80)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('MEVCUT ALTIN', style: TextStyle(color: GameConstants.textMuted, fontSize: 12)),
                    Row(
                      children: [
                        Icon(Icons.paid, color: GameConstants.gold, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${game.state.gold}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: GameConstants.gold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Masraf listesi
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    // Gladyatörler başlığı
                    if (game.state.gladiators.isNotEmpty) ...[
                      _buildSectionHeader('GLADYATÖRLER', Icons.sports_mma),
                      ...game.state.gladiators.map((g) => _ExpenseRow(
                        name: g.name,
                        subtitle: '${g.origin} • Moral: ${g.morale}',
                        salary: g.salary,
                        morale: g.morale,
                        onFire: () => _fireGladiator(context, game, g.id, g.name),
                        isGladiator: true,
                      )),
                    ],

                    const SizedBox(height: 12),

                    // Personel başlığı
                    if (game.state.staff.isNotEmpty) ...[
                      _buildSectionHeader('PERSONEL', Icons.people),
                      ...game.state.staff.map((s) => _ExpenseRow(
                        name: s.name,
                        subtitle: s.role == StaffRole.doctor ? 'Doktor' : s.role == StaffRole.trainer ? 'Eğitmen' : 'Hizmetçi',
                        salary: s.salary,
                        onFire: () => _fireStaff(context, game, s.id, s.name),
                        isGladiator: false,
                      )),
                    ],
                  ],
                ),
              ),

              // Alt toplam ve buton
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GameConstants.primaryBrown,
                  border: Border(top: BorderSide(color: GameConstants.gold.withAlpha(40))),
                ),
                child: Column(
                  children: [
                    // Toplam
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOPLAM MASRAF',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: GameConstants.textLight,
                          ),
                        ),
                        Text(
                          '${game.state.totalWeeklySalary} altın',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: canPayFull ? GameConstants.gold : GameConstants.danger,
                          ),
                        ),
                      ],
                    ),

                    if (!canPayFull)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: GameConstants.danger, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Yeterli altın yok! İsyan riski var.',
                              style: TextStyle(color: GameConstants.danger, fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Hafta geçir butonu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _payAndAdvance(context, game),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canPayFull ? GameConstants.buttonPrimary : GameConstants.danger.withAlpha(180),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.skip_next, color: GameConstants.textLight),
                            const SizedBox(width: 8),
                            Text(
                              canPayFull ? 'MAAŞLARI ÖDE VE HAFTAYI GEÇ' : 'RİSKLİ: HAFTAYI GEÇ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: GameConstants.textLight,
                                letterSpacing: 1,
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
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, color: GameConstants.gold, size: 16),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: GameConstants.textMuted,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _fireGladiator(BuildContext context, GladiatorGame game, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GameConstants.primaryBrown,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('$name\'ı Kov', style: TextStyle(color: GameConstants.danger)),
        content: Text(
          'Bu gladyatörü kovarsan diğer gladyatörlerin morali düşecek. Emin misin?',
          style: TextStyle(color: GameConstants.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İPTAL', style: TextStyle(color: GameConstants.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GameConstants.danger),
            onPressed: () {
              Navigator.pop(ctx);
              game.fireGladiator(id);
              _showCustomPopup(context, 'KOVULDU', '$name kovuldu. Diğer gladyatörlerin morali düştü.', false);
            },
            child: const Text('KOV'),
          ),
        ],
      ),
    );
  }

  void _fireStaff(BuildContext context, GladiatorGame game, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GameConstants.primaryBrown,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('$name\'ı Kov', style: TextStyle(color: GameConstants.danger)),
        content: Text(
          'Bu personeli kovmak istediğine emin misin?',
          style: TextStyle(color: GameConstants.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İPTAL', style: TextStyle(color: GameConstants.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GameConstants.danger),
            onPressed: () {
              Navigator.pop(ctx);
              game.fireStaff(id);
              _showCustomPopup(context, 'KOVULDU', '$name kovuldu.', false);
            },
            child: const Text('KOV'),
          ),
        ],
      ),
    );
  }

  void _payAndAdvance(BuildContext context, GladiatorGame game) {
    Navigator.pop(context);
    final result = game.paySalaries();

    _showCustomPopup(
      context,
      result.rebellionRisk ? 'TEHLİKE!' : 'HAFTA GEÇTİ',
      result.message,
      !result.rebellionRisk,
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

// Masraf satırı
class _ExpenseRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final int salary;
  final int? morale;
  final VoidCallback onFire;
  final bool isGladiator;

  const _ExpenseRow({
    required this.name,
    required this.subtitle,
    required this.salary,
    this.morale,
    required this.onFire,
    required this.isGladiator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GameConstants.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GameConstants.cardBorder),
      ),
      child: Row(
        children: [
          // Moral göstergesi (sadece gladyatörler için)
          if (isGladiator && morale != null)
            Container(
              width: 4,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: morale! >= 70
                    ? GameConstants.success
                    : morale! >= 40
                        ? GameConstants.warning
                        : GameConstants.danger,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

          // İsim ve alt bilgi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: GameConstants.textLight,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: GameConstants.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Maaş
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: GameConstants.gold.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.paid, color: GameConstants.gold, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$salary',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: GameConstants.gold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Kovma butonu
          GestureDetector(
            onTap: onFire,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GameConstants.danger.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GameConstants.danger.withAlpha(60)),
              ),
              child: Icon(Icons.person_remove, color: GameConstants.danger, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// Köşe ikonu - Sadece görsel
class _CornerIcon extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String imagePath;

  const _CornerIcon({
    required this.label,
    required this.color,
    required this.onTap,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(150), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(50),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: GameConstants.primaryDark,
                  child: Center(
                    child: Text(
                      label[0],
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: GameConstants.textLight,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Colosseum ikonu - ortada büyük
class _ColosseumIcon extends StatelessWidget {
  final bool isOpen;
  final int currentWeek;
  final VoidCallback onTap;

  const _ColosseumIcon({
    required this.isOpen,
    required this.currentWeek,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nextOpenWeek = ((currentWeek ~/ 5) + 1) * 5;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ana ikon container
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isOpen
                  ? GameConstants.gold.withAlpha(30)
                  : GameConstants.primaryDark.withAlpha(200),
              shape: BoxShape.circle,
              border: Border.all(
                color: isOpen ? GameConstants.gold : Colors.grey.shade600,
                width: 3,
              ),
              boxShadow: isOpen
                  ? [
                      BoxShadow(
                        color: GameConstants.gold.withAlpha(60),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Icon(
              Icons.stadium,
              size: 50,
              color: isOpen ? GameConstants.gold : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 10),

          // Başlık
          Text(
            'COLOSSEUM',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isOpen ? GameConstants.gold : Colors.grey.shade400,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 6,
                ),
              ],
            ),
          ),

          // Durum
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isOpen
                  ? GameConstants.success.withAlpha(50)
                  : Colors.grey.shade800.withAlpha(150),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOpen
                    ? GameConstants.success.withAlpha(100)
                    : Colors.grey.shade700,
              ),
            ),
            child: Text(
              isOpen ? 'AÇIK!' : '$nextOpenWeek. haftada açılır',
              style: TextStyle(
                fontSize: 11,
                color: isOpen ? GameConstants.success : Colors.grey.shade400,
                fontWeight: isOpen ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Hafta geçir butonu
class _WeekButton extends StatelessWidget {
  final VoidCallback onTap;
  final int salary;

  const _WeekButton({
    required this.onTap,
    required this.salary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [GameConstants.buttonPrimary, GameConstants.warmOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GameConstants.gold.withAlpha(100)),
          boxShadow: [
            BoxShadow(
              color: GameConstants.warmOrange.withAlpha(60),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.skip_next, size: 28, color: GameConstants.textLight),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HAFTA GEÇİR',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: GameConstants.textLight,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '-$salary altın',
                  style: TextStyle(
                    fontSize: 11,
                    color: GameConstants.gold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
