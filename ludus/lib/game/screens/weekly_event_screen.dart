import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../gladiator_game.dart';
import '../models/gladiator.dart';
import 'components/roman_dialogue_box.dart';

/// Haftalık event ekranı - RomanDialogueScreen kullanır
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

class _WeeklyEventScreenState extends State<WeeklyEventScreen> {
  bool _showResult = false;
  String _resultMessage = '';

  String get _speakerName {
    if (widget.event['speaker_from_gladiator'] == true && widget.targetGladiator != null) {
      return widget.targetGladiator!.name;
    }
    return widget.event['speaker'] as String? ?? 'Bilinmeyen';
  }

  String? get _speakerImage {
    final image = widget.event['speaker_image'] as String?;
    if (image != null) return image;
    if (widget.event['speaker_from_gladiator'] == true) {
      return 'assets/defaultasker.png';
    }
    return null;
  }

  void _makeChoice(Map<String, dynamic> option) {
    final game = context.read<GladiatorGame>();

    if (option['requires_gold'] != null) {
      final requiredGold = option['requires_gold'] as int;
      if (game.state.gold < requiredGold) {
        setState(() {
          _showResult = true;
          _resultMessage = 'Yeterli altının yok! ($requiredGold altın gerekli)';
        });
        return;
      }
    }

    final result = game.applyEventChoice(widget.event, option, widget.targetGladiator);

    setState(() {
      _showResult = true;
      _resultMessage = result.message;

      if (result.child != null) {
        final genderText = result.child!.isMale ? 'erkek' : 'kız';
        _resultMessage += '\n\nBir $genderText çocuğunuz oldu: ${result.child!.name}!';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dialogue = widget.event['dialogue'] as String? ?? '';
    final choice = widget.event['choice'] as Map<String, dynamic>;
    final options = choice['options'] as List;
    final game = context.watch<GladiatorGame>();

    // Sonuç ekranı
    if (_showResult) {
      return RomanDialogueScreen(
        speakerName: _speakerName,
        speakerImage: _speakerImage,
        dialogueText: _resultMessage,
        topRightWidget: RomanWeekBadge(week: game.state.week),
        choices: [
          DialogueChoice(
            text: 'Devam',
            onSelect: widget.onComplete,
          ),
        ],
      );
    }

    // Seçim ekranı
    return RomanDialogueScreen(
      speakerName: _speakerName,
      speakerImage: _speakerImage,
      dialogueText: dialogue,
      topRightWidget: RomanWeekBadge(week: game.state.week),
      choices: options.map((opt) {
        final option = opt as Map<String, dynamic>;
        final requiresGold = option['requires_gold'] as int?;
        final canAfford = requiresGold == null || game.state.gold >= requiresGold;

        return DialogueChoice(
          text: option['text'] as String,
          enabled: canAfford,
          onSelect: () => _makeChoice(option),
        );
      }).toList(),
    );
  }
}
