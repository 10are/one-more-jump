import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../gladiator_game.dart';
import '../models/game_state.dart';
import 'components/roman_dialogue_box.dart';

/// Ana hikaye ekranı - RomanDialogueScreen kullanır
class MainStoryScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  final VoidCallback onComplete;

  const MainStoryScreen({
    super.key,
    required this.event,
    required this.onComplete,
  });

  @override
  State<MainStoryScreen> createState() => _MainStoryScreenState();
}

class _MainStoryScreenState extends State<MainStoryScreen> {
  int _currentDialogueIndex = 0;
  bool _showChoices = false;
  bool _showResult = false;
  String _resultText = '';
  String? _pathChosen;

  List<Map<String, dynamic>> _getDialogues() {
    final game = Provider.of<GladiatorGame>(context, listen: false);
    final path = game.state.mainStory.path;

    if (widget.event['path_specific'] != null) {
      final pathSpecific = widget.event['path_specific'] as Map<String, dynamic>;
      String pathKey = 'none';
      if (path == StoryPath.vengeance) pathKey = 'vengeance';
      if (path == StoryPath.loyalty) pathKey = 'loyalty';

      if (pathSpecific.containsKey(pathKey)) {
        final pathData = pathSpecific[pathKey] as Map<String, dynamic>;
        if (pathData['dialogue'] != null) {
          return List<Map<String, dynamic>>.from(pathData['dialogue']);
        }
      }
    }

    if (widget.event['dialogue'] != null) {
      return List<Map<String, dynamic>>.from(widget.event['dialogue']);
    }

    return [];
  }

  List<Map<String, dynamic>> _getChoices() {
    final game = Provider.of<GladiatorGame>(context, listen: false);
    final path = game.state.mainStory.path;

    if (widget.event['path_specific'] != null) {
      final pathSpecific = widget.event['path_specific'] as Map<String, dynamic>;
      String pathKey = 'none';
      if (path == StoryPath.vengeance) pathKey = 'vengeance';
      if (path == StoryPath.loyalty) pathKey = 'loyalty';

      if (pathSpecific.containsKey(pathKey)) {
        final pathData = pathSpecific[pathKey] as Map<String, dynamic>;
        if (pathData['choices'] != null) {
          return List<Map<String, dynamic>>.from(pathData['choices']);
        }
      }
    }

    if (widget.event['choices'] != null) {
      return List<Map<String, dynamic>>.from(widget.event['choices']);
    }

    return [];
  }

  void _nextDialogue() {
    final dialogues = _getDialogues();

    if (_currentDialogueIndex < dialogues.length - 1) {
      setState(() => _currentDialogueIndex++);
    } else {
      setState(() => _showChoices = true);
    }
  }

  void _selectChoice(Map<String, dynamic> choice) {
    final game = Provider.of<GladiatorGame>(context, listen: false);

    if (choice['requires'] != null) {
      final requires = choice['requires'] as Map<String, dynamic>;

      if (requires['min_gold'] != null) {
        if (game.state.gold < (requires['min_gold'] as int)) {
          _showRequirementError('Yeterli altının yok!');
          return;
        }
      }

      if (requires['min_gladiators'] != null) {
        if (game.state.gladiators.length < (requires['min_gladiators'] as int)) {
          _showRequirementError('Yeterli gladyatörün yok!');
          return;
        }
      }

      if (requires['min_family_loyalty'] != null) {
        if (game.state.mainStory.familyLoyalty < (requires['min_family_loyalty'] as int)) {
          _showRequirementError('Aile sadakati yetersiz!');
          return;
        }
      }
    }

    if (choice['requires_path'] != null) {
      final requiredPath = choice['requires_path'] as String;
      if (requiredPath == 'vengeance' && game.state.mainStory.path != StoryPath.vengeance) {
        return;
      }
      if (requiredPath == 'loyalty' && game.state.mainStory.path != StoryPath.loyalty) {
        return;
      }
    }

    final result = game.applyMainStoryChoice(widget.event, choice);

    setState(() {
      _showChoices = false;
      _showResult = true;
      _resultText = result.consequence;
      _pathChosen = result.pathChosen;
    });
  }

  void _showRequirementError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getSpeakerName(String speaker) {
    switch (speaker) {
      case 'narrator': return 'Anlatıcı';
      case 'wife': return 'Karın';
      case 'caesar': return 'Sezar';
      case 'brutus': return 'Brutus';
      case 'cassius': return 'Cassius';
      case 'praetorian_commander': return 'Quintus Maximus';
      case 'egyptian_merchant': return 'Ptolemy';
      case 'fathers_friend': return 'Marcus Aurelius';
      case 'spy': return 'Corvus';
      case 'doctore': return 'Doctore';
      case 'gladiator': return 'Gladyatör';
      case 'guard': return 'Muhafız';
      case 'servant': return 'Uşak';
      case 'stranger': return 'Yabancı';
      case 'fathers_letter': return 'Babanın Mektubu';
      case 'letter': return 'Mektup';
      case 'herald': return 'Tellal';
      case 'crowd': return 'Kalabalık';
      case 'old_friend': return 'Eski Dost';
      case 'senator': return 'Senatör';
      case 'tax_collector': return 'Vergi Tahsildarı';
      case 'merchant': return 'Tüccar';
      case 'patron': return 'Patron';
      case 'doctor': return 'Doktor';
      case 'midwife': return 'Ebe';
      case 'solonius': return 'Solonius';
      default: return speaker;
    }
  }

  String? _getSpeakerImage(String speaker) {
    switch (speaker) {
      case 'wife': return 'assets/karin.jpg';
      case 'doctore': return 'assets/defaultasker.png';
      case 'caesar': return 'assets/21.jpg';
      default: return null;
    }
  }

  String get _chapterText {
    final game = Provider.of<GladiatorGame>(context, listen: false);
    final chapter = game.state.mainStory.chapter;
    switch (chapter) {
      case StoryChapter.prologue: return 'Prolog';
      case StoryChapter.chapter1: return 'Bölüm I';
      case StoryChapter.chapter2: return 'Bölüm II';
      case StoryChapter.chapter3: return 'Bölüm III';
      case StoryChapter.chapter4: return 'Bölüm IV';
      case StoryChapter.finale: return 'Final';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dialogues = _getDialogues();
    final game = context.watch<GladiatorGame>();

    // Diyalog yoksa ve seçim yoksa direkt tamamla
    if (dialogues.isEmpty && !_showChoices && !_showResult) {
      final choices = _getChoices();
      if (choices.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onComplete();
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_showChoices) {
          setState(() => _showChoices = true);
        }
      });
    }

    // Sonuç ekranı
    if (_showResult) {
      String resultDisplay = _resultText;
      if (_pathChosen != null) {
        final pathText = _pathChosen == 'vengeance'
            ? '⚔️ İNTİKAM YOLUNU SEÇTİN'
            : '🛡️ SADAKAT YOLUNU SEÇTİN';
        resultDisplay = '$pathText\n\n$_resultText';
      }

      return RomanDialogueScreen(
        dialogueText: resultDisplay,
        topRightWidget: RomanWeekBadge(week: game.state.week, customText: _chapterText),
        choices: [
          DialogueChoice(
            text: 'Devam',
            onSelect: widget.onComplete,
          ),
        ],
      );
    }

    // Seçim ekranı
    if (_showChoices) {
      final choices = _getChoices();
      final title = widget.event['title'] as String? ?? 'Ne yapacaksın?';

      return RomanDialogueScreen(
        dialogueText: title,
        topRightWidget: RomanWeekBadge(week: game.state.week, customText: _chapterText),
        choices: choices.map((choice) {
          final text = choice['text'] as String? ?? '';
          final pathChoice = choice['path'] as String?;
          final requiresPath = choice['requires_path'] as String?;

          bool isAvailable = true;
          if (requiresPath != null) {
            if (requiresPath == 'vengeance' && game.state.mainStory.path != StoryPath.vengeance) {
              isAvailable = false;
            }
            if (requiresPath == 'loyalty' && game.state.mainStory.path != StoryPath.loyalty) {
              isAvailable = false;
            }
          }
          if (choice['requires'] != null) {
            final requires = choice['requires'] as Map<String, dynamic>;
            if (requires['min_gold'] != null && game.state.gold < (requires['min_gold'] as int)) {
              isAvailable = false;
            }
          }

          String displayText = text;
          if (pathChoice == 'vengeance') {
            displayText = '[İNTİKAM] $text';
          } else if (pathChoice == 'loyalty') {
            displayText = '[SADAKAT] $text';
          }

          return DialogueChoice(
            text: displayText,
            enabled: isAvailable,
            onSelect: () => _selectChoice(choice),
          );
        }).toList(),
      );
    }

    // Diyalog ekranı
    final currentDialogue = dialogues[_currentDialogueIndex];
    final speaker = currentDialogue['speaker'] as String? ?? 'narrator';
    final speakerName = _getSpeakerName(speaker);
    final speakerImage = _getSpeakerImage(speaker);
    final text = currentDialogue['text'] as String? ?? '';

    return RomanDialogueScreen(
      speakerName: speaker != 'narrator' ? speakerName : null,
      speakerImage: speakerImage,
      dialogueText: text,
      topRightWidget: RomanWeekBadge(week: game.state.week, customText: _chapterText),
      progressText: '${_currentDialogueIndex + 1}/${dialogues.length}',
      onTapContinue: _nextDialogue,
      showContinuePrompt: true,
    );
  }
}
