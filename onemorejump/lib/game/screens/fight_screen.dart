import 'dart:math';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/gladiator.dart';

// Dövüş sonucu
class FightOutcome {
  final bool playerWon;
  final int playerDamage;
  final int enemyDamage;
  final bool playerDied;
  final bool enemyDied;
  final int goldReward;
  final int reputationReward;

  FightOutcome({
    required this.playerWon,
    required this.playerDamage,
    required this.enemyDamage,
    required this.playerDied,
    required this.enemyDied,
    required this.goldReward,
    required this.reputationReward,
  });
}

// Dövüş hesaplama
class FightCalculator {
  static final Random _random = Random();

  static FightOutcome calculate({
    required Gladiator player,
    required int enemyHealth,
    required int enemyStrength,
    required int enemyIntelligence,
    required int enemyStamina,
    required int goldReward,
    required int reputationReward,
  }) {
    final playerTotalStats = player.health + player.strength + player.intelligence + player.stamina;
    final enemyTotalStats = enemyHealth + enemyStrength + enemyIntelligence + enemyStamina;

    final statDiff = (playerTotalStats - enemyTotalStats) ~/ 10;
    final playerBonus = statDiff > 0 ? statDiff : 0;
    final enemyBonus = statDiff < 0 ? -statDiff : 0;

    final playerStaminaPenalty = player.stamina < 30 ? 1 : 0;
    final enemyStaminaPenalty = enemyStamina < 30 ? 1 : 0;

    int playerRoll = _random.nextInt(10) + 1 - playerStaminaPenalty;
    int enemyRoll = _random.nextInt(10) + 1 - enemyStaminaPenalty;
    playerRoll = playerRoll.clamp(1, 10);
    enemyRoll = enemyRoll.clamp(1, 10);

    final playerCritical = playerRoll == 10;
    final enemyCritical = enemyRoll == 10;

    final playerTotal = playerRoll + playerBonus;
    final enemyTotal = enemyRoll + enemyBonus;

    final playerWon = playerTotal > enemyTotal;
    final isDraw = playerTotal == enemyTotal;

    int baseDamage = (playerTotal - enemyTotal).abs();
    if (isDraw) baseDamage = 5;

    int playerDamage = 0;
    int enemyDamage = 0;

    if (playerWon) {
      enemyDamage = baseDamage * (playerCritical ? 2 : 1);
    } else if (!isDraw) {
      playerDamage = baseDamage * (enemyCritical ? 2 : 1);
    } else {
      playerDamage = 5;
      enemyDamage = 5;
    }

    if (player.intelligence > 50) {
      playerDamage = (playerDamage * 0.8).round();
    }
    if (enemyIntelligence > 50) {
      enemyDamage = (enemyDamage * 0.8).round();
    }

    if (!playerWon && !isDraw) playerDamage = max(5, playerDamage);
    if (playerWon) enemyDamage = max(5, enemyDamage);

    final playerNewHealth = player.health - playerDamage;
    final enemyNewHealth = enemyHealth - enemyDamage;
    final playerDied = playerNewHealth <= 0;
    final enemyDied = enemyNewHealth <= 0;

    return FightOutcome(
      playerWon: playerWon || (isDraw && !playerDied),
      playerDamage: playerDamage,
      enemyDamage: enemyDamage,
      playerDied: playerDied,
      enemyDied: enemyDied,
      goldReward: playerWon ? goldReward : 0,
      reputationReward: playerWon ? reputationReward : 0,
    );
  }
}

// Dövüş Ekranı
class FightScreen extends StatefulWidget {
  final Gladiator player;
  final String enemyName;
  final String enemyTitle;
  final String? enemyImage;
  final int enemyHealth;
  final int enemyStrength;
  final int enemyIntelligence;
  final int enemyStamina;
  final int goldReward;
  final int reputationReward;
  final String fightType;
  final Function(FightOutcome) onFightEnd;

  const FightScreen({
    super.key,
    required this.player,
    required this.enemyName,
    required this.enemyTitle,
    this.enemyImage,
    required this.enemyHealth,
    required this.enemyStrength,
    required this.enemyIntelligence,
    required this.enemyStamina,
    required this.goldReward,
    required this.reputationReward,
    required this.fightType,
    required this.onFightEnd,
  });

  @override
  State<FightScreen> createState() => _FightScreenState();
}

class _FightScreenState extends State<FightScreen> {
  bool _showResult = false;
  FightOutcome? _outcome;

  @override
  void initState() {
    super.initState();
    _startFight();
  }

  void _startFight() async {
    // Hesapla
    _outcome = FightCalculator.calculate(
      player: widget.player,
      enemyHealth: widget.enemyHealth,
      enemyStrength: widget.enemyStrength,
      enemyIntelligence: widget.enemyIntelligence,
      enemyStamina: widget.enemyStamina,
      goldReward: widget.goldReward,
      reputationReward: widget.reputationReward,
    );

    // 2 saniye bekle
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _showResult = true);
    }
  }

  Color get _accentColor {
    switch (widget.fightType) {
      case 'arena':
        return GameConstants.gold;
      case 'underground':
        return GameConstants.bloodRed;
      case 'colosseum':
        return const Color(0xFFE91E63);
      default:
        return GameConstants.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _showResult ? _buildResultScene() : _buildLoadingScene(),
    );
  }

  Widget _buildLoadingScene() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'DÖVÜŞ',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _accentColor,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: _accentColor,
              strokeWidth: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScene() {
    final outcome = _outcome!;
    final won = outcome.playerWon;
    final playerDied = outcome.playerDied;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            playerDied
                ? GameConstants.danger.withAlpha(40)
                : (won ? GameConstants.success.withAlpha(40) : GameConstants.danger.withAlpha(40)),
            Colors.black,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Sonuç başlığı
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              decoration: BoxDecoration(
                color: won ? GameConstants.success.withAlpha(40) : GameConstants.danger.withAlpha(40),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: won ? GameConstants.success : GameConstants.danger,
                  width: 3,
                ),
              ),
              child: Text(
                won ? 'ZAFER!' : 'YENİLGİ!',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: won ? GameConstants.success : GameConstants.danger,
                  letterSpacing: 8,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Kazanan dövüşçü
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: won ? GameConstants.success : GameConstants.danger,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (won ? GameConstants.success : GameConstants.danger).withAlpha(80),
                    blurRadius: 25,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  won ? 'assets/defaultasker.png' : (widget.enemyImage ?? 'assets/defaultasker.png'),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.person,
                    size: 60,
                    color: won ? GameConstants.success : GameConstants.danger,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              won ? widget.player.name : widget.enemyName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: GameConstants.textLight,
              ),
            ),
            Text(
              'KAZANDI!',
              style: TextStyle(
                fontSize: 14,
                color: won ? GameConstants.success : GameConstants.danger,
                letterSpacing: 3,
              ),
            ),

            const SizedBox(height: 30),

            // Hasar bilgisi
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(180),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _accentColor.withAlpha(80)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDamageColumn(
                          widget.player.name,
                          outcome.playerDamage,
                          outcome.playerDied,
                          true,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 80,
                        color: _accentColor.withAlpha(50),
                      ),
                      Expanded(
                        child: _buildDamageColumn(
                          widget.enemyName,
                          outcome.enemyDamage,
                          outcome.enemyDied,
                          false,
                        ),
                      ),
                    ],
                  ),

                  // Ödüller
                  if (won && (outcome.goldReward > 0 || outcome.reputationReward > 0)) ...[
                    const SizedBox(height: 16),
                    Divider(color: _accentColor.withAlpha(50)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (outcome.goldReward > 0)
                          _buildReward(Icons.paid, '+${outcome.goldReward}', GameConstants.gold),
                        if (outcome.reputationReward > 0)
                          _buildReward(Icons.star, '+${outcome.reputationReward}', GameConstants.warmOrange),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Gladyatör öldü uyarısı
            if (playerDied) ...[
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: GameConstants.danger.withAlpha(60),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GameConstants.danger, width: 3),
                ),
                child: Column(
                  children: [
                    Icon(Icons.dangerous, color: GameConstants.danger, size: 50),
                    const SizedBox(height: 12),
                    Text(
                      'GLADYATÖR KAYBI',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: GameConstants.danger,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.player.name} arenada hayatını kaybetti!',
                      style: TextStyle(
                        fontSize: 14,
                        color: GameConstants.textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bu gladyatör artık kullanılamaz.',
                      style: TextStyle(
                        fontSize: 12,
                        color: GameConstants.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Devam butonu
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onFightEnd(outcome);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'DEVAM',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDamageColumn(String name, int damage, bool died, bool isPlayer) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isPlayer ? GameConstants.success : GameConstants.danger,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        if (died)
          Column(
            children: [
              Icon(Icons.dangerous, color: GameConstants.danger, size: 32),
              const SizedBox(height: 4),
              Text(
                'ÖLDÜ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: GameConstants.danger,
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              Text(
                '-$damage',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: GameConstants.healthColor,
                ),
              ),
              Text(
                'HP',
                style: TextStyle(
                  fontSize: 12,
                  color: GameConstants.textMuted,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildReward(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
