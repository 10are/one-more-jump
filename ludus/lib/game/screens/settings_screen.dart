import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../gladiator_game.dart';
import '../constants.dart';
import '../services/save_service.dart';
import '../services/audio_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _saveInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSaveInfo();
  }

  Future<void> _loadSaveInfo() async {
    final info = await SaveService.getSaveInfo();
    if (mounted) {
      setState(() {
        _saveInfo = info;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();

    return Scaffold(
      backgroundColor: GameConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: GameConstants.primaryBrown,
        title: Row(
          children: [
            Icon(Icons.settings, color: GameConstants.gold),
            const SizedBox(width: 10),
            Text(
              'AYARLAR',
              style: TextStyle(
                color: GameConstants.gold,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: GameConstants.textLight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<GladiatorGame>(
        builder: (context, game, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // SES AYARLARI
              _buildSectionHeader('SES AYARLARI', Icons.volume_up),
              const SizedBox(height: 12),

              // Müzik aç/kapat
              ListenableBuilder(
                listenable: audioService,
                builder: (context, child) {
                  return _SettingsTile(
                    icon: Icons.music_note,
                    title: 'Müzik',
                    subtitle: audioService.isMusicEnabled ? 'Açık' : 'Kapalı',
                    trailing: Switch(
                      value: audioService.isMusicEnabled,
                      onChanged: (value) {
                        audioService.toggleMusic();
                      },
                      activeColor: GameConstants.gold,
                      activeTrackColor: GameConstants.gold.withAlpha(100),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // KAYIT YÖNETİMİ
              _buildSectionHeader('KAYIT YÖNETİMİ', Icons.save),
              const SizedBox(height: 12),

              // Mevcut kayıt bilgisi
              if (_isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: GameConstants.gold),
                  ),
                )
              else if (_saveInfo != null)
                _SaveInfoCard(saveInfo: _saveInfo!)
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: GameConstants.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GameConstants.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: GameConstants.textMuted),
                      const SizedBox(width: 12),
                      Text(
                        'Kayıtlı oyun bulunamadı',
                        style: TextStyle(color: GameConstants.textMuted),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Auto-save bilgisi
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GameConstants.success.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: GameConstants.success.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_mode, color: GameConstants.success, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Oyun otomatik kaydediliyor',
                        style: TextStyle(
                          color: GameConstants.success,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Kaydı sil
              if (_saveInfo != null)
                _ActionButton(
                  icon: Icons.delete_forever,
                  label: 'KAYDI SİL',
                  color: GameConstants.danger,
                  onTap: () => _showDeleteConfirmation(context),
                ),

              const SizedBox(height: 24),

              // OYUN SEÇENEKLERİ
              _buildSectionHeader('OYUN SEÇENEKLERİ', Icons.gamepad),
              const SizedBox(height: 12),

              // Yeni oyun
              _ActionButton(
                icon: Icons.add,
                label: 'YENİ OYUN BAŞLAT',
                color: GameConstants.bloodRed,
                onTap: () => _showNewGameConfirmation(context, game),
              ),

              const SizedBox(height: 12),

              // Ana menüye dön
              _ActionButton(
                icon: Icons.home,
                label: 'ANA MENÜYE DÖN',
                color: GameConstants.secondaryBrown,
                onTap: () => _showReturnToMenuConfirmation(context, game),
              ),

              const SizedBox(height: 40),

              // Versiyon bilgisi
              Center(
                child: Text(
                  'Ludus Simülatör v1.0.0',
                  style: TextStyle(
                    color: GameConstants.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: GameConstants.gold, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: GameConstants.gold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: GameConstants.gold.withAlpha(40),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GameConstants.primaryBrown,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: GameConstants.danger, size: 28),
            const SizedBox(width: 12),
            Text('Kaydı Sil', style: TextStyle(color: GameConstants.danger)),
          ],
        ),
        content: Text(
          'Kayıtlı oyun kalıcı olarak silinecek. Bu işlem geri alınamaz!',
          style: TextStyle(color: GameConstants.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İPTAL', style: TextStyle(color: GameConstants.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GameConstants.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await SaveService.deleteSave();
              _loadSaveInfo();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kayıt silindi'),
                    backgroundColor: GameConstants.danger,
                  ),
                );
              }
            },
            child: Text('SİL', style: TextStyle(color: GameConstants.textLight)),
          ),
        ],
      ),
    );
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
            Text('Yeni Oyun', style: TextStyle(color: GameConstants.gold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mevcut ilerleme kaybolacak!',
              style: TextStyle(
                color: GameConstants.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni oyun başlatmadan önce kaydetmeyi unutmayın.',
              style: TextStyle(color: GameConstants.textLight),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İPTAL', style: TextStyle(color: GameConstants.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GameConstants.bloodRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await SaveService.deleteSave();
              game.startGame();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: Text('YENİ OYUN', style: TextStyle(color: GameConstants.textLight)),
          ),
        ],
      ),
    );
  }

  void _showReturnToMenuConfirmation(BuildContext context, GladiatorGame game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GameConstants.primaryBrown,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.home, color: GameConstants.gold, size: 28),
            const SizedBox(width: 12),
            Text('Ana Menü', style: TextStyle(color: GameConstants.gold)),
          ],
        ),
        content: Text(
          'Ana menüye dönmeden önce oyunu kaydetmek ister misiniz?',
          style: TextStyle(color: GameConstants.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İPTAL', style: TextStyle(color: GameConstants.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              game.returnToMenu();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text('KAYDETMEDEN ÇIK', style: TextStyle(color: GameConstants.danger)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GameConstants.success),
            onPressed: () async {
              Navigator.pop(ctx);
              await SaveService.autoSave(game.state);
              game.returnToMenu();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: Text('KAYDET VE ÇIK', style: TextStyle(color: GameConstants.textLight)),
          ),
        ],
      ),
    );
  }
}

// Kayıt bilgi kartı
class _SaveInfoCard extends StatelessWidget {
  final Map<String, dynamic> saveInfo;

  const _SaveInfoCard({required this.saveInfo});

  @override
  Widget build(BuildContext context) {
    final week = saveInfo['week'] ?? 1;
    final gold = saveInfo['gold'] ?? 0;
    final reputation = saveInfo['reputation'] ?? 0;
    final gladiatorCount = saveInfo['gladiatorCount'] ?? 0;
    final savedAt = saveInfo['savedAt'] as String?;

    String formattedDate = 'Bilinmiyor';
    if (savedAt != null) {
      try {
        final date = DateTime.parse(savedAt);
        formattedDate = '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameConstants.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameConstants.gold.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.save, color: GameConstants.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                'MEVCUT KAYIT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: GameConstants.gold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoItem(icon: Icons.calendar_today, label: 'Hafta', value: '$week'),
              _InfoItem(icon: Icons.paid, label: 'Altın', value: '$gold'),
              _InfoItem(icon: Icons.star, label: 'İtibar', value: '$reputation'),
              _InfoItem(icon: Icons.sports_mma, label: 'Gladyatör', value: '$gladiatorCount'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, color: GameConstants.textMuted, size: 14),
              const SizedBox(width: 6),
              Text(
                'Son kayıt: $formattedDate',
                style: TextStyle(
                  fontSize: 12,
                  color: GameConstants.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: GameConstants.gold, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: GameConstants.textLight,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: GameConstants.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// Ayarlar tile
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: GameConstants.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameConstants.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: GameConstants.gold, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GameConstants.textLight,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: GameConstants.textMuted,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

// Aksiyon butonu
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GameConstants.gold.withAlpha(60)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(40),
              blurRadius: 8,
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
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: GameConstants.textLight,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
