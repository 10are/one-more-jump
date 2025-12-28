import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../gladiator_game.dart';
import '../constants.dart';
import '../services/save_service.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _hasSave = false;
  Map<String, dynamic>? _saveInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSaveData();
  }

  Future<void> _checkSaveData() async {
    final hasSave = await SaveService.hasSaveData();
    final saveInfo = await SaveService.getSaveInfo();

    if (mounted) {
      setState(() {
        _hasSave = hasSave;
        _saveInfo = saveInfo;
        _isLoading = false;
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
              // Arka plan resmi
              Positioned.fill(
                child: Image.asset(
                  'assets/unnamed.jpg',
                  fit: BoxFit.cover,
                ),
              ),

              // Karartma
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(100),
                        GameConstants.primaryDark.withAlpha(230),
                      ],
                    ),
                  ),
                ),
              ),

              // İçerik
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),

                        // Logo
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: GameConstants.gold.withAlpha(60),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/logo.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  color: GameConstants.primaryDark.withAlpha(200),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: GameConstants.gold, width: 3),
                                ),
                                child: Icon(
                                  Icons.gavel,
                                  size: 80,
                                  color: GameConstants.gold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Alt yazı
                        Text(
                          'Kendi gladyatör okulunu yönet',
                          style: TextStyle(
                            fontSize: 14,
                            color: GameConstants.textMuted,
                            letterSpacing: 1,
                          ),
                        ),

                        const Spacer(),

                        // Loading göstergesi
                        if (_isLoading)
                          CircularProgressIndicator(color: GameConstants.gold)
                        else ...[
                          // DEVAM ET butonu (save varsa)
                          if (_hasSave) ...[
                            _ContinueButton(
                              saveInfo: _saveInfo,
                              onTap: () => _continueGame(context, game),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // YENİ OYUN butonu
                          _MenuButton(
                            label: 'YENİ OYUN',
                            icon: Icons.add,
                            color: _hasSave ? GameConstants.secondaryBrown : GameConstants.bloodRed,
                            onTap: () => _hasSave
                                ? _showNewGameConfirmation(context, game)
                                : _startNewGame(game),
                          ),
                        ],

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _continueGame(BuildContext context, GladiatorGame game) async {
    final savedState = await SaveService.loadGame();
    if (savedState != null) {
      game.loadFromState(savedState);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt yüklenemedi!'),
            backgroundColor: GameConstants.danger,
          ),
        );
      }
    }
  }

  void _startNewGame(GladiatorGame game) {
    game.startGame();
  }

  void _showNewGameConfirmation(BuildContext context, GladiatorGame game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GameConstants.primaryBrown,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: GameConstants.warning, size: 28),
            const SizedBox(width: 12),
            Text(
              'Yeni Oyun',
              style: TextStyle(color: GameConstants.gold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mevcut kayıt silinecek!',
              style: TextStyle(
                color: GameConstants.danger,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni bir oyun başlatmak mevcut ilerlemenizi silecektir. Emin misiniz?',
              style: TextStyle(color: GameConstants.textLight),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'İPTAL',
              style: TextStyle(color: GameConstants.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GameConstants.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await SaveService.deleteSave();
              _startNewGame(game);
            },
            child: Text(
              'YENİ OYUN BAŞLAT',
              style: TextStyle(color: GameConstants.textLight),
            ),
          ),
        ],
      ),
    );
  }
}

// Devam Et butonu - kayıt bilgisi ile
class _ContinueButton extends StatelessWidget {
  final Map<String, dynamic>? saveInfo;
  final VoidCallback onTap;

  const _ContinueButton({
    required this.saveInfo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final week = saveInfo?['week'] ?? 1;
    final gold = saveInfo?['gold'] ?? 0;
    final gladiatorCount = saveInfo?['gladiatorCount'] ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GameConstants.bloodRed,
              GameConstants.buttonPrimary,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GameConstants.gold.withAlpha(150), width: 2),
          boxShadow: [
            BoxShadow(
              color: GameConstants.bloodRed.withAlpha(100),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow, color: GameConstants.textLight, size: 28),
                const SizedBox(width: 8),
                Text(
                  'DEVAM ET',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: GameConstants.textLight,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SaveInfoChip(icon: Icons.calendar_today, value: '$week. Hafta'),
                  const SizedBox(width: 12),
                  _SaveInfoChip(icon: Icons.paid, value: '$gold'),
                  const SizedBox(width: 12),
                  _SaveInfoChip(icon: Icons.sports_mma, value: '$gladiatorCount'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveInfoChip extends StatelessWidget {
  final IconData icon;
  final String value;

  const _SaveInfoChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: GameConstants.gold, size: 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: GameConstants.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Normal menu butonu
class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GameConstants.gold.withAlpha(80)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(60),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: GameConstants.textLight, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: GameConstants.textLight,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
