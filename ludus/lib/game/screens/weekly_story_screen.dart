import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../gladiator_game.dart';
import '../constants.dart';

/// Haftalık interaktif hikaye ekranı
class WeeklyStoryScreen extends StatefulWidget {
  final Map<String, dynamic> story;
  final VoidCallback onComplete;

  const WeeklyStoryScreen({
    super.key,
    required this.story,
    required this.onComplete,
  });

  @override
  State<WeeklyStoryScreen> createState() => _WeeklyStoryScreenState();
}

class _WeeklyStoryScreenState extends State<WeeklyStoryScreen>
    with SingleTickerProviderStateMixin {
  int _currentDialogueIndex = 0;
  List<Map<String, dynamic>> _dialogues = [];
  bool _showChoice = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadDialogues();

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

  void _loadDialogues() {
    final game = context.read<GladiatorGame>();
    _dialogues = game.getStoryDialogues(widget.story);
  }

  void _nextDialogue() {
    if (_currentDialogueIndex < _dialogues.length - 1) {
      setState(() {
        _currentDialogueIndex++;
      });
    } else {
      // Diyaloglar bitti, seçim var mı kontrol et
      if (widget.story['choice'] != null) {
        setState(() {
          _showChoice = true;
        });
      } else {
        _completeStory();
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

  void _makeChoice(Map<String, dynamic> option) {
    final game = context.read<GladiatorGame>();

    // Seçimi kaydet
    final variable = option['sets_variable'] as String;
    final value = option['value'] as bool;
    game.setStoryChoice(variable, value);

    _completeStory();
  }

  void _completeStory() {
    final game = context.read<GladiatorGame>();
    final storyId = widget.story['id'] as String;
    game.markStoryAsSeen(storyId);

    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundPath = widget.story['background'] as String?;

    if (_dialogues.isEmpty && !_showChoice) {
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

    return Scaffold(
      backgroundColor: GameConstants.primaryDark,
      body: SafeArea(
        child: GestureDetector(
          onTap: _showChoice ? null : _nextDialogue,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // Arka plan resmi
              Positioned.fill(
                child: backgroundPath != null
                    ? Image.asset(
                        backgroundPath,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Image.asset(
                          'assets/unnamed.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: GameConstants.primaryDark,
                          ),
                        ),
                      )
                    : Image.asset(
                        'assets/unnamed.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
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
              if (_currentDialogueIndex > 0 && !_showChoice)
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

              // Hafta bilgisi
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(200),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: GameConstants.gold,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Hafta ${widget.story['week']}',
                    style: TextStyle(
                      color: GameConstants.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Ana içerik
              Column(
                children: [
                  const SizedBox(height: 60),

                  // Karakter portresi
                  if (!_showChoice) _buildCharacterPortrait(),

                  const SizedBox(height: 20),

                  // Diyalog veya seçim
                  Expanded(
                    child: _showChoice
                        ? _buildChoicePanel()
                        : _buildDialoguePanel(),
                  ),

                  // Devam butonu (sadece diyalog modunda)
                  if (!_showChoice) ...[
                    const SizedBox(height: 12),
                    _buildContinueButton(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterPortrait() {
    if (_dialogues.isEmpty) return const SizedBox.shrink();

    final dialogue = _dialogues[_currentDialogueIndex];
    final speakerImage = dialogue['speaker_image'] as String?;
    final speaker = dialogue['speaker'] as String?;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 180,
        height: 180,
        margin: const EdgeInsets.only(right: 16),
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
                speakerImage ?? 'assets/defaultasker.png',
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
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(120),
                      ],
                    ),
                  ),
                ),
              ),
              // Konuşmacı ismi
              if (speaker != null)
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Text(
                    speaker,
                    style: TextStyle(
                      color: GameConstants.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialoguePanel() {
    if (_dialogues.isEmpty) return const SizedBox.shrink();

    final dialogue = _dialogues[_currentDialogueIndex];
    final text = dialogue['text'] as String;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.35,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(220),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GameConstants.bronze,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
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
          const SizedBox(height: 8),
          // İlerleme göstergesi
          Text(
            '${_currentDialogueIndex + 1} / ${_dialogues.length}',
            style: TextStyle(
              color: Colors.white.withAlpha(128),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoicePanel() {
    final choice = widget.story['choice'] as Map<String, dynamic>;
    final question = choice['question'] as String;
    final options = choice['options'] as List;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(230),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GameConstants.gold,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: GameConstants.gold.withAlpha(77),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Soru
          Text(
            question,
            style: TextStyle(
              color: GameConstants.gold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Seçenekler
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index] as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildChoiceButton(option),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceButton(Map<String, dynamic> option) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _makeChoice(option),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: GameConstants.primaryBrown.withAlpha(200),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: GameConstants.gold.withAlpha(178),
              width: 1.5,
            ),
          ),
          child: Text(
            option['text'] as String,
            style: TextStyle(
              color: GameConstants.textLight,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return GestureDetector(
      onTap: _nextDialogue,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final pulseAlpha = (0.5 + (_pulseAnimation.value - 0.8) * 2.5) * 255;
          final glowAlpha = ((_pulseAnimation.value - 0.8) * 2.5 * 0.3) * 255;
          final iconAlpha = (0.7 + (_pulseAnimation.value - 0.8) * 2.5 * 0.3) * 255;

          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: GameConstants.bronze.withAlpha(pulseAlpha.toInt()),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: GameConstants.gold.withAlpha(glowAlpha.toInt()),
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
                    color: GameConstants.gold.withAlpha(iconAlpha.toInt()),
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
    );
  }
}
