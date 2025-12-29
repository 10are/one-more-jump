import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../gladiator_game.dart';
import '../constants.dart';

class WeeklyStoryScreen extends StatefulWidget {
  final String storyId;
  final VoidCallback onComplete;

  const WeeklyStoryScreen({
    super.key,
    required this.storyId,
    required this.onComplete,
  });

  @override
  State<WeeklyStoryScreen> createState() => _WeeklyStoryScreenState();
}

class _WeeklyStoryScreenState extends State<WeeklyStoryScreen> with SingleTickerProviderStateMixin {
  int _currentDialogueIndex = 0;
  Map<String, dynamic>? _storyData;
  bool _isLoading = true;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadStoryData();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
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

  Future<void> _loadStoryData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/weekly_stories.json');
      final data = json.decode(jsonString);
      final stories = data['weekly_stories'] as List;
      
      final story = stories.firstWhere(
        (s) => s['id'] == widget.storyId,
        orElse: () => null,
      );
      
      if (story != null) {
        setState(() {
          _storyData = story;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Story data yukleme hatasi: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _dialogues {
    if (_storyData == null) return [];
    return List<Map<String, dynamic>>.from(_storyData!['dialogues'] ?? []);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: GameConstants.primaryDark,
        body: Center(
          child: CircularProgressIndicator(color: GameConstants.gold),
        ),
      );
    }

    if (_storyData == null || _dialogues.isEmpty) {
      return Scaffold(
        backgroundColor: GameConstants.primaryDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: GameConstants.danger, size: 48),
              const SizedBox(height: 16),
              Text(
                'Hikaye yüklenemedi',
                style: TextStyle(color: GameConstants.textLight),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.onComplete,
                child: const Text('Devam Et'),
              ),
            ],
          ),
        ),
      );
    }

    final currentDialogue = _dialogues[_currentDialogueIndex.clamp(0, _dialogues.length - 1)];

    return Consumer<GladiatorGame>(
      builder: (context, game, child) {
        return Scaffold(
          backgroundColor: GameConstants.primaryDark,
          body: SafeArea(
            child: GestureDetector(
              onTap: _advanceDialogue,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                children: [
                  // Arka plan resmi
                  Positioned.fill(
                    child: Image.asset(
                      'assets/unnamed.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: GameConstants.primaryDark,
                      ),
                    ),
                  ),

                  // Hafif karartma
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha(120),
                            Colors.black.withAlpha(180),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Geri butonu
                  if (_currentDialogueIndex > 0)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: GestureDetector(
                        onTap: _goBackDialogue,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(200),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: GameConstants.bronze,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: GameConstants.textLight,
                            size: 18,
                          ),
                        ),
                      ),
                    ),

                  // Ana içerik
                  Column(
                    children: [
                      const SizedBox(height: 40),
                      
                      // Karakter portresi
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 200,
                          height: 200,
                          margin: const EdgeInsets.only(right: 16, top: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: GameConstants.bronze,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: GameConstants.bronze.withAlpha(50),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  'assets/defaultasker.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: GameConstants.primaryBrown,
                                    child: Icon(
                                      Icons.person,
                                      size: 80,
                                      color: GameConstants.gold.withAlpha(150),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withAlpha(60),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Diyalog kutusu
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.35,
                        ),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: GameConstants.bronze,
                            width: 2,
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              currentDialogue['text'] ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: GameConstants.textLight,
                                letterSpacing: 0.4,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      const SizedBox(height: 12),

                      // "Devam etmek için dokunun" butonu - animasyonlu
                        GestureDetector(
                          onTap: _advanceDialogue,
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: GameConstants.bronze.withOpacity(0.5 + (_pulseAnimation.value - 0.8) * 2.5),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: GameConstants.gold.withOpacity((_pulseAnimation.value - 0.8) * 2.5 * 0.3),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.touch_app,
                                        size: 22,
                                        color: GameConstants.gold.withOpacity(0.7 + (_pulseAnimation.value - 0.8) * 2.5 * 0.3),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Devam etmek için dokunun',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: GameConstants.textLight,
                                          letterSpacing: 0.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _advanceDialogue() {
    if (!mounted) return;
    
    if (_dialogues.isEmpty) {
      if (mounted) {
        widget.onComplete();
      }
      return;
    }
    
    if (_currentDialogueIndex < _dialogues.length - 1) {
      setState(() {
        _currentDialogueIndex++;
      });
    } else {
      // Tüm diyaloglar bitti, oyuna devam et
      if (mounted) {
        widget.onComplete();
      }
    }
  }

  void _goBackDialogue() {
    if (_currentDialogueIndex > 0) {
      setState(() {
        _currentDialogueIndex--;
      });
    }
  }
}

