import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../gladiator_game.dart';
import 'components/roman_dialogue_box.dart';

/// Haftalık hikaye ekranı - RomanDialogueScreen kullanır
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

class _WeeklyStoryScreenState extends State<WeeklyStoryScreen> {
  int _currentDialogueIndex = 0;
  List<Map<String, dynamic>> _dialogues = [];
  bool _showChoice = false;

  @override
  void initState() {
    super.initState();
    _loadDialogues();
  }

  void _loadDialogues() {
    final game = context.read<GladiatorGame>();
    _dialogues = game.getStoryDialogues(widget.story);
  }

  void _nextDialogue() {
    if (_currentDialogueIndex < _dialogues.length - 1) {
      setState(() => _currentDialogueIndex++);
    } else {
      if (widget.story['choice'] != null) {
        setState(() => _showChoice = true);
      } else {
        _completeStory();
      }
    }
  }

  void _makeChoice(Map<String, dynamic> option) {
    final game = context.read<GladiatorGame>();
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
    final game = context.watch<GladiatorGame>();
    final week = widget.story['week'] as int? ?? game.state.week;

    // Hata durumu
    if (_dialogues.isEmpty && !_showChoice) {
      return RomanDialogueScreen(
        dialogueText: 'Hikaye yüklenemedi',
        topRightWidget: RomanWeekBadge(week: week),
        choices: [
          DialogueChoice(
            text: 'Devam',
            onSelect: widget.onComplete,
          ),
        ],
      );
    }

    // Seçim ekranı
    if (_showChoice) {
      final choice = widget.story['choice'] as Map<String, dynamic>;
      final question = choice['question'] as String;
      final options = choice['options'] as List;

      return RomanDialogueScreen(
        dialogueText: question,
        topRightWidget: RomanWeekBadge(week: week, customText: 'Hikaye'),
        choices: options.map((opt) {
          final option = opt as Map<String, dynamic>;
          return DialogueChoice(
            text: option['text'] as String,
            onSelect: () => _makeChoice(option),
          );
        }).toList(),
      );
    }

    // Diyalog ekranı
    final currentDialogue = _dialogues[_currentDialogueIndex];
    final speaker = currentDialogue['speaker'] as String? ?? '';
    final speakerImage = currentDialogue['speaker_image'] as String?;
    final text = currentDialogue['text'] as String? ?? '';

    return RomanDialogueScreen(
      speakerName: speaker.isNotEmpty ? speaker : null,
      speakerImage: speakerImage,
      dialogueText: text,
      topRightWidget: RomanWeekBadge(week: week, customText: 'Hikaye'),
      progressText: '${_currentDialogueIndex + 1}/${_dialogues.length}',
      onTapContinue: _nextDialogue,
      showContinuePrompt: true,
    );
  }
}
