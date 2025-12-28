import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../models/gladiator.dart';

// Dovus sonucu
class FightOutcome {
  final bool playerWon;
  final int playerDamage;
  final int enemyDamage;
  final bool playerDied;
  final bool enemyDied;
  final int goldReward;
  final int reputationReward;
  final int playerRoll;
  final int enemyRoll;
  final bool playerCritical;
  final bool enemyCritical;

  FightOutcome({
    required this.playerWon,
    required this.playerDamage,
    required this.enemyDamage,
    required this.playerDied,
    required this.enemyDied,
    required this.goldReward,
    required this.reputationReward,
    required this.playerRoll,
    required this.enemyRoll,
    required this.playerCritical,
    required this.enemyCritical,
  });
}

// Dovus hesaplama
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
    int moraleBonus = 0,
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

    final playerTotal = playerRoll + playerBonus + moraleBonus;
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
      playerRoll: playerRoll,
      enemyRoll: enemyRoll,
      playerCritical: playerCritical,
      enemyCritical: enemyCritical,
    );
  }
}

// Spiker yorumlari
class FightCommentary {
  static Map<String, dynamic>? _data;
  static final Random _random = Random();

  static Future<void> load() async {
    if (_data != null) return;
    try {
      final jsonString = await rootBundle.loadString('assets/data/fight_commentary.json');
      _data = json.decode(jsonString);
    } catch (e) {
      _data = {};
    }
  }

  static String _get(String key, String player, String enemy) {
    if (_data == null || !_data!.containsKey(key)) return '';
    final list = List<String>.from(_data![key]);
    if (list.isEmpty) return '';
    final text = list[_random.nextInt(list.length)];
    return text.replaceAll('{player}', player).replaceAll('{enemy}', enemy);
  }

  static String fightStart(String player, String enemy) => _get('fight_start', player, enemy);
  static String playerAttack(String player, String enemy) => _get('round_player_attack', player, enemy);
  static String enemyAttack(String player, String enemy) => _get('round_enemy_attack', player, enemy);
  static String playerHit(String player, String enemy) => _get('player_hit', player, enemy);
  static String enemyHit(String player, String enemy) => _get('enemy_hit', player, enemy);
  static String criticalPlayer(String player, String enemy) => _get('critical_player', player, enemy);
  static String criticalEnemy(String player, String enemy) => _get('critical_enemy', player, enemy);
  static String tension(String player, String enemy) => _get('tension', player, enemy);
  static String finishPlayerWin(String player, String enemy) => _get('finish_player_win', player, enemy);
  static String finishPlayerLose(String player, String enemy) => _get('finish_player_lose', player, enemy);
  static String finishPlayerDeath(String player, String enemy) => _get('finish_player_death', player, enemy);
  static String finishEnemyDeath(String player, String enemy) => _get('finish_enemy_death', player, enemy);
}

// Dovus Ekrani - Sinematik
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
  final int moraleBonus;

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
    this.moraleBonus = 0,
  });

  @override
  State<FightScreen> createState() => _FightScreenState();
}

class _FightScreenState extends State<FightScreen> with TickerProviderStateMixin {
  FightOutcome? _outcome;
  List<String> _commentary = [];
  int _currentLine = 0;
  bool _showResult = false;
  bool _isLoading = true;
  String _currentText = '';

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _startFight();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _startFight() async {
    await FightCommentary.load();

    _outcome = FightCalculator.calculate(
      player: widget.player,
      enemyHealth: widget.enemyHealth,
      enemyStrength: widget.enemyStrength,
      enemyIntelligence: widget.enemyIntelligence,
      enemyStamina: widget.enemyStamina,
      goldReward: widget.goldReward,
      reputationReward: widget.reputationReward,
      moraleBonus: widget.moraleBonus,
    );

    _buildCommentary();

    setState(() => _isLoading = false);

    await _playCommentary();
  }

  void _buildCommentary() {
    final player = widget.player.name;
    final enemy = widget.enemyName;
    final outcome = _outcome!;

    _commentary = [];

    _commentary.add(FightCommentary.fightStart(player, enemy));
    _commentary.add(FightCommentary.playerAttack(player, enemy));
    _commentary.add(FightCommentary.enemyAttack(player, enemy));

    if (outcome.playerCritical) {
      _commentary.add(FightCommentary.criticalPlayer(player, enemy));
    } else if (outcome.enemyCritical) {
      _commentary.add(FightCommentary.criticalEnemy(player, enemy));
    }

    if (outcome.playerWon) {
      _commentary.add(FightCommentary.enemyHit(player, enemy));
    } else {
      _commentary.add(FightCommentary.playerHit(player, enemy));
    }

    _commentary.add(FightCommentary.tension(player, enemy));

    if (outcome.playerDied) {
      _commentary.add(FightCommentary.finishPlayerDeath(player, enemy));
    } else if (outcome.enemyDied) {
      _commentary.add(FightCommentary.finishEnemyDeath(player, enemy));
    } else if (outcome.playerWon) {
      _commentary.add(FightCommentary.finishPlayerWin(player, enemy));
    } else {
      _commentary.add(FightCommentary.finishPlayerLose(player, enemy));
    }
  }

  Future<void> _playCommentary() async {
    for (int i = 0; i < _commentary.length; i++) {
      if (!mounted) return;

      setState(() {
        _currentLine = i;
        _currentText = _commentary[i];
      });

      // Reset ve baslat
      _fadeController.reset();
      _slideController.reset();
      _fadeController.forward();
      _slideController.forward();

      // Gosterim suresi - son cumle daha uzun
      final duration = i == _commentary.length - 1 ? 2500 : 1800;
      await Future.delayed(Duration(milliseconds: duration));

      // Fade out
      if (mounted && i < _commentary.length - 1) {
        await _fadeController.reverse();
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _showResult = true);
    }
  }

  String get _backgroundImage {
    switch (widget.fightType) {
      case 'arena':
        return 'assets/arena.png';
      case 'underground':
        return 'assets/yeralti.png';
      case 'colosseum':
        return 'assets/buyukarena.jpg';
      default:
        return 'assets/arena.png';
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
      body: _isLoading
          ? _buildLoadingScene()
          : (_showResult ? _buildResultScene() : _buildCinematicScene()),
    );
  }

  Widget _buildLoadingScene() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Arka plan
        Image.asset(
          _backgroundImage,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.black),
        ),
        // Karanlik overlay
        Container(color: Colors.black.withAlpha(180)),
        // Loading
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_mma, size: 50, color: _accentColor.withAlpha(150)),
              const SizedBox(height: 16),
              Text(
                'HAZIRLANIYOR...',
                style: TextStyle(
                  fontSize: 14,
                  color: _accentColor,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCinematicScene() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Arka plan gorseli - TAM EKRAN
        Image.asset(
          _backgroundImage,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_accentColor.withAlpha(60), Colors.black],
              ),
            ),
          ),
        ),

        // Ust gradient - metin okunabilir olsun
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 200,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(200),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Alt gradient
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 300,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withAlpha(230),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Sinematik metin - ortada
        SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Ana metin alani
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(150),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _accentColor.withAlpha(60),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _currentText,
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 10,
                              ),
                              Shadow(
                                color: _accentColor.withAlpha(100),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Alt bilgi - zar sonuclari
              if (_outcome != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDiceDisplay(widget.player.name, _outcome!.playerRoll, _outcome!.playerCritical, true),
                      const SizedBox(width: 30),
                      Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 16,
                          color: _accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 30),
                      _buildDiceDisplay(widget.enemyName, _outcome!.enemyRoll, _outcome!.enemyCritical, false),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiceDisplay(String name, int roll, bool isCritical, bool isPlayer) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCritical ? _accentColor : Colors.black.withAlpha(180),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCritical ? _accentColor : _accentColor.withAlpha(100),
              width: 2,
            ),
            boxShadow: isCritical
                ? [BoxShadow(color: _accentColor.withAlpha(100), blurRadius: 12)]
                : null,
          ),
          child: Center(
            child: Text(
              '$roll',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isCritical ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name.length > 8 ? '${name.substring(0, 8)}...' : name,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withAlpha(180),
          ),
        ),
      ],
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

            // Sonuc basligi
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
                won ? 'ZAFER!' : 'YENILGI!',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: won ? GameConstants.success : GameConstants.danger,
                  letterSpacing: 8,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Kazanan
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
                  won
                      ? (widget.player.imagePath ?? 'assets/defaultasker.png')
                      : (widget.enemyImage ?? 'assets/defaultasker.png'),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: (won ? GameConstants.success : GameConstants.danger).withAlpha(40),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: won ? GameConstants.success : GameConstants.danger,
                    ),
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
                      'GLADYATOR KAYBI',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: GameConstants.danger,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.player.name} arenada hayatini kaybetti!',
                      style: TextStyle(
                        fontSize: 14,
                        color: GameConstants.textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

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
                'OLDU',
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
