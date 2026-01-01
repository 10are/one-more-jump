import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../gladiator_game.dart';
import '../constants.dart';
import '../models/gladiator.dart';

/// Haftalık event ekranı (eş, doctore, gladyatör eventleri)
class WeeklyEventScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  final Gladiator? targetGladiator;
  final VoidCallback onComplete;

  const WeeklyEventScreen({
    super.key,
    required this.event,
    this.targetGladiator,
    required this.onComplete,
  });

  @override
  State<WeeklyEventScreen> createState() => _WeeklyEventScreenState();
}

class _WeeklyEventScreenState extends State<WeeklyEventScreen>
    with SingleTickerProviderStateMixin {
  bool _showResult = false;
  String _resultMessage = '';
  bool _resultSuccess = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String get _speakerName {
    if (widget.event['speaker_from_gladiator'] == true && widget.targetGladiator != null) {
      return widget.targetGladiator!.name;
    }
    return widget.event['speaker'] as String? ?? 'Bilinmeyen';
  }

  void _makeChoice(Map<String, dynamic> option) {
    final game = context.read<GladiatorGame>();

    // Altın gereksinimi kontrolü
    if (option['requires_gold'] != null) {
      final requiredGold = option['requires_gold'] as int;
      if (game.state.gold < requiredGold) {
        setState(() {
          _showResult = true;
          _resultMessage = 'Yeterli altinin yok! ($requiredGold altin gerekli)';
          _resultSuccess = false;
        });
        return;
      }
    }

    // Seçimi uygula
    final result = game.applyEventChoice(widget.event, option, widget.targetGladiator);

    setState(() {
      _showResult = true;
      _resultMessage = result.message;
      _resultSuccess = !_resultMessage.toLowerCase().contains('dustu') &&
          !_resultMessage.toLowerCase().contains('uzuldu') &&
          !_resultMessage.toLowerCase().contains('hayal kirikligi');

      // Çocuk doğduysa özel mesaj
      if (result.child != null) {
        final genderText = result.child!.isMale ? 'erkek' : 'kız';
        _resultMessage += '\n\nBir $genderText cocugunuz oldu: ${result.child!.name}!';
      }
    });
  }

  void _closeResult() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final speakerImage = widget.event['speaker_image'] as String?;
    final dialogue = widget.event['dialogue'] as String;
    final choice = widget.event['choice'] as Map<String, dynamic>;
    final options = choice['options'] as List;

    return Scaffold(
      backgroundColor: GameConstants.primaryDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Arka plan
            Positioned.fill(
              child: Image.asset(
                'assets/unnamed.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: GameConstants.primaryDark,
                ),
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
                      Colors.black.withAlpha(150),
                      Colors.black.withAlpha(200),
                    ],
                  ),
                ),
              ),
            ),

            // İçerik
            Column(
              children: [
                const SizedBox(height: 20),

                // Event tipi badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getEventColor().withAlpha(50),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getEventColor(), width: 1),
                  ),
                  child: Text(
                    _getEventTypeText(),
                    style: TextStyle(
                      color: _getEventColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Konuşmacı portresi
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getEventColor(),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _getEventColor().withAlpha(80),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            speakerImage ?? 'assets/defaultasker.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: GameConstants.primaryBrown,
                              child: Icon(
                                _getEventIcon(),
                                size: 60,
                                color: _getEventColor(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Konuşmacı ismi
                Text(
                  _speakerName,
                  style: TextStyle(
                    color: _getEventColor(),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // Diyalog veya sonuç
                Expanded(
                  child: _showResult ? _buildResultPanel() : _buildDialoguePanel(dialogue, options),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialoguePanel(String dialogue, List options) {
    final game = context.watch<GladiatorGame>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Diyalog kutusu
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(200),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: GameConstants.bronze,
                width: 2,
              ),
            ),
            child: Text(
              dialogue,
              style: TextStyle(
                color: GameConstants.textLight,
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // Seçenekler
          ...options.map((option) {
            final opt = option as Map<String, dynamic>;
            final requiresGold = opt['requires_gold'] as int?;
            final canAfford = requiresGold == null || game.state.gold >= requiresGold;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _makeChoice(opt),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: canAfford
                          ? GameConstants.primaryBrown.withAlpha(200)
                          : Colors.black.withAlpha(100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: canAfford
                            ? _getEventColor().withAlpha(150)
                            : GameConstants.textMuted.withAlpha(50),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            opt['text'] as String,
                            style: TextStyle(
                              color: canAfford
                                  ? GameConstants.textLight
                                  : GameConstants.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!canAfford)
                          Icon(
                            Icons.lock,
                            color: GameConstants.textMuted,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Sonuç ikonu
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _resultSuccess
                  ? GameConstants.success.withAlpha(50)
                  : GameConstants.danger.withAlpha(50),
              border: Border.all(
                color: _resultSuccess ? GameConstants.success : GameConstants.danger,
                width: 3,
              ),
            ),
            child: Icon(
              _resultSuccess ? Icons.check : Icons.sentiment_dissatisfied,
              size: 40,
              color: _resultSuccess ? GameConstants.success : GameConstants.danger,
            ),
          ),

          const SizedBox(height: 20),

          // Sonuç mesajı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(200),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _resultSuccess ? GameConstants.success : GameConstants.danger,
                width: 2,
              ),
            ),
            child: Text(
              _resultMessage,
              style: TextStyle(
                color: GameConstants.textLight,
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),

          // Devam butonu
          ElevatedButton(
            onPressed: _closeResult,
            style: ElevatedButton.styleFrom(
              backgroundColor: GameConstants.primaryBrown,
              foregroundColor: GameConstants.textLight,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: GameConstants.bronze, width: 2),
              ),
            ),
            child: const Text(
              'DEVAM ET',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getEventColor() {
    final type = widget.event['type'] as String?;
    switch (type) {
      case 'wife':
        return Colors.pink.shade300;
      case 'doctore':
        return GameConstants.bronze;
      case 'gladiator':
        return GameConstants.bloodRed;
      default:
        return GameConstants.gold;
    }
  }

  String _getEventTypeText() {
    final type = widget.event['type'] as String?;
    switch (type) {
      case 'wife':
        return 'ES';
      case 'doctore':
        return 'DOCTORE';
      case 'gladiator':
        return 'GLADYATOR';
      default:
        return 'EVENT';
    }
  }

  IconData _getEventIcon() {
    final type = widget.event['type'] as String?;
    switch (type) {
      case 'wife':
        return Icons.favorite;
      case 'doctore':
        return Icons.sports_kabaddi;
      case 'gladiator':
        return Icons.person;
      default:
        return Icons.event;
    }
  }
}
