import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../gladiator_game.dart';
import '../services/save_service.dart';
import 'tutorial_screen.dart';
import 'home_screen.dart';
import 'components/roman_dialogue_box.dart';

/// Oyun başlangıç hikayesi - RomanDialogueScreen kullanır
class StoryIntroScreen extends StatefulWidget {
  const StoryIntroScreen({super.key});

  @override
  State<StoryIntroScreen> createState() => _StoryIntroScreenState();
}

class _StoryIntroScreenState extends State<StoryIntroScreen> {
  int _currentDialogueIndex = 0;
  bool _showResponses = false;
  bool _isWaitingForResponse = false;
  List<Map<String, dynamic>>? _currentResponseReactions;
  int _currentReactionIndex = 0;
  int _responseRound = 0;

  final List<Map<String, dynamic>> _initialDialogues = [
    {'text': 'Uzun yıllar önce, Roma\'nın karanlık sokaklarında bir sır saklanıyordu. Sen, küçük bir çocukken, annen sana gerçeği söyleyemedi.', 'speaker': 'Dayı'},
    {'text': 'Sezar... Roma İmparatoru Sezar, senin gerçek baban. Ama o, anneni kandırdı. Ona yalan söyledi, seni terk etti. Annen bunu öğrenince çıldırdı, seni bana bıraktı ve kaçtı.', 'speaker': 'Dayı'},
    {'text': 'Sezar, seni öldürmek istiyor. Çünkü sen onun tek varisi olacaksın ve o, tüm gücünü kaybetmek istemiyor. Şimdi burada, bu gladyatör okulunda güçlenmen lazım.', 'speaker': 'Dayı'},
    {'text': 'Ben sana yol göstereceğim. Bu gladyatör okulunda eğitileceksin, güçleneceksin ve sonunda Sezar\'ı yeneceksin.', 'speaker': 'Dayı'},
  ];

  final List<String> _initialResponseOptions = ['Siktir git', 'Sezar\'ı öldüreceğim', 'Sana inanmıyorum', 'Anlat devam et'];
  final List<String> _secondResponseOptions = ['Tamam, anladım', 'Hala sana inanmıyorum', 'Sezar\'ı öldüreceğim', 'Daha fazla anlat'];
  final List<String> _thirdResponseOptions = ['Peki, ne yapmalıyım?', 'Bu çok fazla, git', 'Sezar\'ı öldüreceğim', 'Kanıtları göster'];

  final Map<String, List<Map<String, dynamic>>> _responseReactions = {
    'Siktir git': [
      {'text': 'Anlıyorum, şoktasın. Bu ağır bir gerçek. Ama dinle beni... Annen seni bana bıraktı çünkü Sezar\'ın gerçek yüzünü öğrendi.', 'speaker': 'Dayı'},
      {'text': 'Sezar seni öldürmek istiyor. Eğer burada kalıp güçlenmezsen, o seni bulacak. Burada güvendesin.', 'speaker': 'Dayı'},
    ],
    'Sana inanmıyorum': [
      {'text': 'İnanmak zorunda değilsin. Ama gerçek bu. Annenin bıraktığı mektup, Sezar\'ın emirleri... hepsi burada.', 'speaker': 'Dayı'},
      {'text': 'Bir gün gerçekle yüzleşeceksin. O zaman beni hatırla.', 'speaker': 'Dayı'},
    ],
    'Anlat devam et': [
      {'text': 'İyi, dinliyorsun. Sezar seni öldürmek istiyor çünkü sen onun tek varisi olacaksın.', 'speaker': 'Dayı'},
      {'text': 'Bu gladyatör okulunda eğitileceksin ve sonunda Sezar\'ı yeneceksin. Hazır mısın?', 'speaker': 'Dayı'},
    ],
    'Hala sana inanmıyorum': [
      {'text': 'Annenin mektubu: "Oğlumu koru, Sezar onu öldürmek istiyor."', 'speaker': 'Dayı'},
      {'text': 'Sezar\'ın emri: "O çocuğu bulun ve öldürün." İşte gerçek bu.', 'speaker': 'Dayı'},
    ],
    'Daha fazla anlat': [
      {'text': 'Sezar Roma\'nın en güçlü imparatoru. Ama sen onun oğlusun. Sen de o kadar güçlü olabilirsin.', 'speaker': 'Dayı'},
      {'text': 'Burada kal ve eğitil. Her adımda yanında olacağım.', 'speaker': 'Dayı'},
    ],
    'Bu çok fazla, git': [
      {'text': 'Anlıyorum. Ama eğer gitmezsen Sezar seni bulacak. Burada güvendesin.', 'speaker': 'Dayı'},
      {'text': 'Düşün, karar ver. Zaman geçtikçe Sezar\'a daha yakın oluyorsun.', 'speaker': 'Dayı'},
    ],
    'Kanıtları göster': [
      {'text': 'Annenin mektubu: "Oğlumu koru, Sezar onu öldürmek istiyor. Lütfen onu koru."', 'speaker': 'Dayı'},
      {'text': 'Sezar\'ın emri: "O çocuğu bulun ve öldürün, tahtımı almayacak." İşte kanıt.', 'speaker': 'Dayı'},
    ],
    'Tamam, anladım': [
      {'text': 'İyi. Şimdi bu gladyatör okulunda eğitileceksin. Ben seninle olacağım.', 'speaker': 'Dayı'},
    ],
  };

  List<String> get _currentResponseOptions {
    if (_responseRound == 0) return _initialResponseOptions;
    if (_responseRound == 1) return _secondResponseOptions;
    return _thirdResponseOptions;
  }

  String get _currentText {
    if (_isWaitingForResponse && _currentResponseReactions != null) {
      return _currentResponseReactions![_currentReactionIndex]['text'] as String;
    }
    return _initialDialogues[_currentDialogueIndex.clamp(0, _initialDialogues.length - 1)]['text'] as String;
  }

  void _advanceDialogue() {
    if (_isWaitingForResponse && _currentResponseReactions != null) {
      if (_currentReactionIndex < _currentResponseReactions!.length - 1) {
        setState(() => _currentReactionIndex++);
      } else {
        setState(() {
          _isWaitingForResponse = false;
          _showResponses = true;
          _currentResponseReactions = null;
          _currentReactionIndex = 0;
          _responseRound++;
        });
      }
    } else {
      if (_currentDialogueIndex < _initialDialogues.length - 1) {
        setState(() => _currentDialogueIndex++);
      } else {
        setState(() => _showResponses = true);
      }
    }
  }

  void _handleResponse(String response, GladiatorGame game) {
    if (response == 'Sezar\'ı öldüreceğim' || response == 'Peki, ne yapmalıyım?' || response == 'Tamam, anladım') {
      _startGame(game);
      return;
    }

    final reactions = _responseReactions[response];
    if (reactions != null && reactions.isNotEmpty) {
      setState(() {
        _isWaitingForResponse = true;
        _showResponses = false;
        _currentResponseReactions = reactions;
        _currentReactionIndex = 0;
      });
    } else {
      _startGame(game);
    }
  }

  void _startGame(GladiatorGame game) async {
    game.startGame();
    await SaveService.autoSave(game.state);

    if (mounted) {
      final tutorialSeen = await SaveService.hasTutorialSeen();
      if (!tutorialSeen) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(value: game, child: TutorialScreen(onComplete: () { Navigator.pop(context); SaveService.setTutorialSeen(); })),
        ));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(value: game, child: const HomeScreen()),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GladiatorGame>(
      builder: (context, game, child) {
        // Seçenek ekranı
        if (_showResponses && !_isWaitingForResponse) {
          return RomanDialogueScreen(
            speakerName: 'Dayı',
            speakerImage: 'assets/defaultasker.png',
            dialogueText: 'Ne diyorsun?',
            choices: _currentResponseOptions.map((text) {
              return DialogueChoice(
                text: text,
                onSelect: () => _handleResponse(text, game),
              );
            }).toList(),
          );
        }

        // Diyalog ekranı
        return RomanDialogueScreen(
          speakerName: 'Dayı',
          speakerImage: 'assets/defaultasker.png',
          dialogueText: _currentText,
          progressText: _isWaitingForResponse
              ? '${_currentReactionIndex + 1}/${_currentResponseReactions?.length ?? 1}'
              : '${_currentDialogueIndex + 1}/${_initialDialogues.length}',
          onTapContinue: _advanceDialogue,
          showContinuePrompt: true,
        );
      },
    );
  }
}
