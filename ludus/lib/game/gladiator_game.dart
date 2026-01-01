import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/game_state.dart';
import 'models/gladiator.dart';
import 'constants.dart';

class GladiatorGame extends ChangeNotifier {
  GameState state = GameState();
  final Random _random = Random();

  // State yenile (UI güncellemesi için)
  void refreshState() {
    notifyListeners();
  }

  // Oyunu başlat
  void startGame() {
    state.reset();
    notifyListeners();
  }

  // === İNTERAKTİF HİKAYE SİSTEMİ ===

  // Cache for loaded stories
  List<Map<String, dynamic>>? _cachedStories;

  // JSON'dan story'leri yükle (async)
  Future<List<Map<String, dynamic>>> loadStories() async {
    if (_cachedStories != null) return _cachedStories!;

    try {
      final String jsonString = await rootBundle.loadString('assets/data/weekly_stories.json');
      final data = json.decode(jsonString);
      _cachedStories = List<Map<String, dynamic>>.from(data['weekly_stories']);
      return _cachedStories!;
    } catch (e) {
      debugPrint('Story yükleme hatası: $e');
      return [];
    }
  }

  // Mevcut hafta için story var mı kontrol et (JSON'daki week alanına göre)
  Future<Map<String, dynamic>?> getCurrentWeekStory() async {
    final stories = await loadStories();

    for (final story in stories) {
      final storyWeek = story['week'] as int;
      final storyId = story['id'] as String;

      // Bu haftanın story'si mi ve henüz görülmemiş mi?
      if (storyWeek == state.week && !state.seenStories.contains(storyId)) {
        return story;
      }
    }
    return null;
  }

  // Story'nin diyaloglarını al (koşullara göre)
  List<Map<String, dynamic>> getStoryDialogues(Map<String, dynamic> story) {
    // Eğer conditions varsa, oyuncunun seçimlerine göre doğru diyalogları getir
    if (story.containsKey('conditions') && story['conditions'] != null) {
      final conditions = story['conditions'] as List;

      for (final condition in conditions) {
        final variable = condition['variable'] as String;
        final requiredValue = condition['value'] as bool;

        // Oyuncunun bu değişken için seçimi var mı?
        if (state.storyChoices.containsKey(variable)) {
          final playerChoice = state.storyChoices[variable];
          if (playerChoice == requiredValue) {
            return List<Map<String, dynamic>>.from(condition['dialogues']);
          }
        }
      }

      // Eğer eşleşen koşul yoksa, ilk koşulun diyaloglarını döndür
      if (conditions.isNotEmpty) {
        return List<Map<String, dynamic>>.from(conditions[0]['dialogues']);
      }
    }

    // Normal diyaloglar (koşulsuz)
    if (story.containsKey('dialogues') && story['dialogues'] != null) {
      return List<Map<String, dynamic>>.from(story['dialogues']);
    }

    return [];
  }

  // Story görüldü olarak işaretle
  void markStoryAsSeen(String storyId) {
    state.seenStories.add(storyId);
    notifyListeners();
  }

  // Oyuncunun seçimini kaydet
  void setStoryChoice(String variable, bool value) {
    state.storyChoices[variable] = value;
    notifyListeners();
  }

  // Belirli bir story değişkeninin değerini al
  bool? getStoryChoice(String variable) {
    return state.storyChoices[variable];
  }

  // === HAFTALIK EVENT SİSTEMİ ===

  // Cache for loaded events
  List<Map<String, dynamic>>? _cachedEvents;

  // JSON'dan event'leri yükle
  Future<List<Map<String, dynamic>>> loadEvents() async {
    if (_cachedEvents != null) return _cachedEvents!;

    try {
      final String jsonString = await rootBundle.loadString('assets/data/weekly_events.json');
      final data = json.decode(jsonString);
      _cachedEvents = List<Map<String, dynamic>>.from(data['weekly_events']);
      return _cachedEvents!;
    } catch (e) {
      debugPrint('Event yükleme hatası: $e');
      return [];
    }
  }

  // Mevcut hafta için uygun event getir (rastgele seçim)
  Future<Map<String, dynamic>?> getRandomWeeklyEvent() async {
    final events = await loadEvents();
    final eligibleEvents = <Map<String, dynamic>>[];

    for (final event in events) {
      if (_isEventEligible(event)) {
        eligibleEvents.add(event);
      }
    }

    if (eligibleEvents.isEmpty) return null;

    // Şansa göre seçim yap
    final shuffled = List<Map<String, dynamic>>.from(eligibleEvents)..shuffle(_random);

    for (final event in shuffled) {
      final chance = event['chance'] as int? ?? 100;
      if (_random.nextInt(100) < chance) {
        return event;
      }
    }

    // Hiçbiri şansı tutmadıysa ilk uygun eventi döndür
    return eligibleEvents.isNotEmpty ? eligibleEvents[_random.nextInt(eligibleEvents.length)] : null;
  }

  // Event uygun mu kontrol et
  bool _isEventEligible(Map<String, dynamic> event) {
    final eventId = event['id'] as String;

    // Zaten görülmüş mü?
    if (state.seenEvents.contains(eventId)) return false;

    // Hafta aralığı kontrolü
    final weekMin = event['week_min'] as int? ?? 1;
    final weekMax = event['week_max'] as int? ?? 999;
    if (state.week < weekMin || state.week > weekMax) return false;

    // Eş gereksinimi
    if (event['requires_wife'] == true && !state.hasWife) return false;

    // Çocuk yok gereksinimi
    if (event['requires_no_child'] == true && state.hasChild) return false;

    // Minimum eş morali
    if (event['min_wife_morale'] != null) {
      if (state.wifeMorale < (event['min_wife_morale'] as int)) return false;
    }

    // Gladyatör gereksinimi
    if (event['requires_gladiator'] == true && state.gladiators.isEmpty) return false;

    // Minimum gladyatör galibiyeti
    if (event['min_gladiator_wins'] != null) {
      final minWins = event['min_gladiator_wins'] as int;
      final hasEligibleGladiator = state.gladiators.any((g) => g.wins >= minWins);
      if (!hasEligibleGladiator) return false;
    }

    return true;
  }

  // Event için konuşmacı gladyatörü seç
  Gladiator? getEventGladiator(Map<String, dynamic> event) {
    if (event['speaker_from_gladiator'] != true) return null;
    if (state.gladiators.isEmpty) return null;

    // Minimum galibiyet gereksinimi varsa ona göre seç
    if (event['min_gladiator_wins'] != null) {
      final minWins = event['min_gladiator_wins'] as int;
      final eligible = state.gladiators.where((g) => g.wins >= minWins).toList();
      if (eligible.isNotEmpty) {
        return eligible[_random.nextInt(eligible.length)];
      }
    }

    // Rastgele bir gladyatör seç
    return state.gladiators[_random.nextInt(state.gladiators.length)];
  }

  // Event seçimi sonucunu uygula
  EventResult applyEventChoice(Map<String, dynamic> event, Map<String, dynamic> option, Gladiator? targetGladiator) {
    final effects = option['effects'] as Map<String, dynamic>? ?? {};
    final resultMessage = option['result_message'] as String? ?? 'Seçim yapıldı.';

    // Altın etkisi
    if (effects['gold'] != null) {
      state.modifyGold(effects['gold'] as int);
    }

    // Eş morali etkisi
    if (effects['wife_morale'] != null) {
      state.modifyWifeMorale(effects['wife_morale'] as int);
    }

    // İtibar etkisi
    if (effects['reputation'] != null) {
      state.modifyReputation(effects['reputation'] as int);
    }

    // Gladyatör moral etkisi
    if (effects['gladiator_morale'] != null && targetGladiator != null) {
      targetGladiator.changeMorale(effects['gladiator_morale'] as int);
    }

    // Gladyatör sağlık etkisi
    if (effects['gladiator_health'] != null && targetGladiator != null) {
      targetGladiator.takeDamage(-(effects['gladiator_health'] as int));
    }

    // Gladyatörü kaldır (özgürlük)
    if (effects['remove_gladiator'] == true && targetGladiator != null) {
      state.gladiators.removeWhere((g) => g.id == targetGladiator.id);
    }

    // Çocuk tetikle
    Child? newChild;
    if (effects['trigger_child'] == true) {
      // Rastgele isim ve cinsiyet
      final isMale = _random.nextBool();
      final names = isMale
          ? ['Marcus', 'Lucius', 'Gaius', 'Titus', 'Quintus', 'Decimus']
          : ['Julia', 'Livia', 'Cornelia', 'Aurelia', 'Claudia', 'Octavia'];
      final name = names[_random.nextInt(names.length)];
      newChild = state.addChild(name, isMale);
    }

    // Eventi görüldü olarak işaretle
    markEventAsSeen(event['id'] as String);

    notifyListeners();

    return EventResult(
      message: resultMessage,
      child: newChild,
    );
  }

  // Event görüldü olarak işaretle
  void markEventAsSeen(String eventId) {
    state.seenEvents.add(eventId);
  }

  // Kayıttan yükle
  void loadFromState(GameState loadedState) {
    state = loadedState;
    notifyListeners();
  }

  // Ana menüye dön
  void returnToMenu() {
    state.phase = GamePhase.menu;
    notifyListeners();
  }

  // === EĞİTİM SİSTEMİ ===
  bool trainGladiator(String gladiatorId, String stat) {
    final gladiator = state.gladiators.firstWhere((g) => g.id == gladiatorId);

    if (!gladiator.canTrain) return false;
    if (state.gold < GameConstants.trainingCostBase) return false;

    state.modifyGold(-GameConstants.trainingCostBase);

    int gainAmount = GameConstants.trainingStatGain;
    // Eğitmen varsa bonus
    final hasTrainer = state.staff.any((s) => s.role == StaffRole.trainer);
    if (hasTrainer) gainAmount += 2;

    // Beslenme bonusu (yemek +2, su +1)
    gainAmount += gladiator.nutritionBonus;

    gladiator.trainStat(stat, gainAmount);

    notifyListeners();
    return true;
  }

  // === BESLENME SİSTEMİ ===
  bool buyFood(String gladiatorId, int price) {
    if (state.gold < price) return false;

    final gladiator = state.gladiators.firstWhere((g) => g.id == gladiatorId);
    if (gladiator.hasFood) return false; // Zaten alınmış

    state.modifyGold(-price);
    gladiator.hasFood = true;

    notifyListeners();
    return true;
  }

  bool buyWater(String gladiatorId, int price) {
    if (state.gold < price) return false;

    final gladiator = state.gladiators.firstWhere((g) => g.id == gladiatorId);
    if (gladiator.hasWater) return false; // Zaten alınmış

    state.modifyGold(-price);
    gladiator.hasWater = true;

    notifyListeners();
    return true;
  }

  // === DOKTOR - İYİLEŞTİRME ===
  bool healGladiator(String gladiatorId) {
    if (state.gold < GameConstants.doctorCost) return false;

    final gladiator = state.gladiators.firstWhere((g) => g.id == gladiatorId);

    state.modifyGold(-GameConstants.doctorCost);

    int healAmount = GameConstants.doctorHealAmount;
    final hasDoctor = state.staff.any((s) => s.role == StaffRole.doctor);
    if (hasDoctor) healAmount += 15;

    gladiator.heal(healAmount);

    notifyListeners();
    return true;
  }

  // === ÖZEL İLAÇ İLE İYİLEŞTİRME ===
  bool healGladiatorWithMedicine(String gladiatorId, int price, int healAmount) {
    if (state.gold < price) return false;

    final gladiator = state.gladiators.firstWhere((g) => g.id == gladiatorId);

    state.modifyGold(-price);

    // Doktor varsa bonus
    final hasDoctor = state.staff.any((s) => s.role == StaffRole.doctor);
    final totalHeal = hasDoctor ? healAmount + 15 : healAmount;

    gladiator.heal(totalHeal);

    notifyListeners();
    return true;
  }

  // === DÖVÜŞ SİSTEMİ ===
  FightResult fight(String gladiatorId, FightOpportunity fight) {
    final gladiator = state.gladiators.firstWhere((g) => g.id == gladiatorId);

    if (!gladiator.canFight) {
      return FightResult(
        won: false,
        message: '${gladiator.name} dövüşemez durumda!',
        damageReceived: 0,
        reward: 0,
      );
    }

    // Dövüş simülasyonu
    final gladiatorRoll = gladiator.overallPower + _random.nextInt(30);
    final enemyRoll = fight.enemyPower + _random.nextInt(30);

    final won = gladiatorRoll > enemyRoll;
    final damage = won ? 10 + _random.nextInt(15) : 20 + _random.nextInt(25);

    gladiator.recordFight(won, damage);

    String message;
    int reward = 0;

    if (won) {
      reward = fight.reward;
      state.modifyGold(reward);
      state.reputation += fight.difficulty * 5;
      fight.isAvailable = false;
      message = '${gladiator.name} zaferle döndü! +$reward altın';
    } else {
      message = '${gladiator.name} yenildi... Hasar: $damage';
    }

    notifyListeners();

    return FightResult(
      won: won,
      message: message,
      damageReceived: damage,
      reward: reward,
    );
  }

  // === DİPLOMASİ SİSTEMİ ===
  BluffResult negotiate(String rivalId, int betAmount) {
    if (state.gold < betAmount) {
      return BluffResult(
        success: false,
        message: 'Yeterli altının yok!',
        goldChange: 0,
      );
    }

    final rival = state.rivals.firstWhere((r) => r.id == rivalId);

    // Zar at (2d6)
    final playerRoll = _random.nextInt(6) + 1 + _random.nextInt(6) + 1;
    final rivalRoll = _random.nextInt(6) + 1 + _random.nextInt(6) + 1;

    // Bonuslar
    int rivalBonus = 0;
    switch (rival.personality) {
      case 'aggressive':
        rivalBonus = 2;
        break;
      case 'cautious':
        rivalBonus = -1;
        break;
      case 'cunning':
        rivalBonus = 1;
        break;
      case 'proud':
        rivalBonus = 0;
        break;
    }

    final reputationBonus = state.reputation ~/ 50;
    final relationshipBonus = rival.relationship ~/ 20;

    final playerTotal = playerRoll + reputationBonus + relationshipBonus;
    final rivalTotal = rivalRoll + rivalBonus;

    final success = playerTotal > rivalTotal;
    int goldChange;
    String message;

    if (success) {
      goldChange = betAmount;
      state.modifyGold(betAmount);
      state.reputation += 5;
      rival.relationship += 10;
      message = 'Pazarlık başarılı! ${rival.name} ikna oldu.';
    } else {
      goldChange = -betAmount;
      state.modifyGold(-betAmount);
      rival.relationship -= 5;
      message = '${rival.name} teklifini reddetti.';
    }

    notifyListeners();

    return BluffResult(
      success: success,
      message: message,
      goldChange: goldChange,
      playerRoll: playerRoll,
      rivalRoll: rivalRoll,
    );
  }

  // === MAAŞ SİSTEMİ ===
  SalaryResult paySalaries() {
    final totalSalary = state.totalWeeklySalary;

    if (state.gold >= totalSalary) {
      // Tam maaş öde
      state.modifyGold(-totalSalary);
      for (final g in state.gladiators) {
        g.changeMorale(5);
      }
      state.advanceWeek();
      _checkForWeeklyStory();
      notifyListeners();
      return SalaryResult(
        paid: true,
        totalPaid: totalSalary,
        message: 'Maaşlar ödendi. Herkes memnun.',
        rebellionRisk: false,
      );
    } else if (state.gold >= totalSalary ~/ 2) {
      // Yarım maaş
      state.modifyGold(-state.gold);
      for (final g in state.gladiators) {
        g.changeMorale(-10);
      }
      state.advanceWeek();
      _checkForWeeklyStory();
      notifyListeners();
      return SalaryResult(
        paid: true,
        totalPaid: state.gold,
        message: 'Kısmi ödeme yapıldı. Moral düştü.',
        rebellionRisk: false,
      );
    } else {
      // Maaş ödenemedi - isyan riski
      for (final g in state.gladiators) {
        g.changeMorale(-25);
      }

      // İsyan kontrolü
      final rebellionChance = state.gladiators.where((g) => g.morale < 20).length;
      final rebellion = _random.nextInt(10) < rebellionChance;

      if (rebellion) {
        // İsyan! Bir gladyatör kaçar
        if (state.gladiators.isNotEmpty) {
          final escapee = state.gladiators.firstWhere(
            (g) => g.morale < 20,
            orElse: () => state.gladiators.first,
          );
          state.gladiators.remove(escapee);
        }
        state.advanceWeek();
        _checkForWeeklyStory();
        notifyListeners();
        return SalaryResult(
          paid: false,
          totalPaid: 0,
          message: 'İSYAN! Bir gladyatör kaçtı!',
          rebellionRisk: true,
        );
      }

      state.advanceWeek();
      _checkForWeeklyStory();
      notifyListeners();
      return SalaryResult(
        paid: false,
        totalPaid: 0,
        message: 'Maaşlar ödenmedi. İsyan tehlikesi var!',
        rebellionRisk: true,
      );
    }
  }

  // === GLADYATÖR MAAŞI AYARLA ===
  void setGladiatorSalary(String gladiatorId, int newSalary) {
    final gladiator = state.gladiators.firstWhere((g) => g.id == gladiatorId);
    gladiator.setSalary(newSalary);
    notifyListeners();
  }

  // === PERSONEL İŞE AL ===
  bool hireStaff(Staff newStaff) {
    // İşe alma ücreti (maaşın 5 katı)
    final hireCost = newStaff.salary * 5;
    if (state.gold < hireCost) return false;

    state.modifyGold(-hireCost);
    state.staff.add(newStaff);
    notifyListeners();
    return true;
  }

  // === PERSONEL İŞE AL (FİYATLI) ===
  bool hireStaffWithPrice(Staff newStaff, int price) {
    if (state.gold < price) return false;

    state.modifyGold(-price);
    state.staff.add(newStaff);
    notifyListeners();
    return true;
  }

  // === PERSONEL KOVMA ===
  void fireStaff(String staffId) {
    state.staff.removeWhere((s) => s.id == staffId);
    notifyListeners();
  }

  // === GLADYATÖR SATIN AL ===
  bool buyGladiator(Gladiator gladiator, int price) {
    if (state.gold < price) return false;

    state.modifyGold(-price);
    state.gladiators.add(gladiator);
    notifyListeners();
    return true;
  }

  // === GLADYATÖR SAT / KOV ===
  void sellGladiator(String gladiatorId, int price) {
    state.gladiators.removeWhere((g) => g.id == gladiatorId);
    state.modifyGold(price);
    notifyListeners();
  }

  // === GLADYATÖR KOV (Diğerlerinin morali düşer) ===
  void fireGladiator(String gladiatorId) {
    state.gladiators.removeWhere((g) => g.id == gladiatorId);

    // Diğer gladyatörlerin morali düşer (zar mekaniği)
    for (final g in state.gladiators) {
      final moraleLoss = 5 + _random.nextInt(10); // 5-15 arası kayıp
      g.changeMorale(-moraleLoss);
    }

    notifyListeners();
  }

  // === OYUN BİTTİ Mİ? ===
  void checkGameOver() {
    final allDead = state.gladiators.every((g) => g.health <= 0);
    final noGladiators = state.gladiators.isEmpty;

    if (allDead || noGladiators) {
      state.phase = GamePhase.gameOver;
      notifyListeners();
    }
  }

  // === ZİYAFET VER (Tüm gladyatörlerin morali artar) ===
  bool giveFeast(int price, int moraleBonus) {
    if (state.gold < price) return false;

    state.modifyGold(-price);

    for (final g in state.gladiators) {
      g.changeMorale(moraleBonus);
    }

    notifyListeners();
    return true;
  }

  // === EŞE HEDİYE VER ===
  bool giveGiftToWife(int price, int moraleBonus) {
    if (state.gold < price) return false;

    state.modifyGold(-price);
    state.modifyWifeMorale(moraleBonus);

    notifyListeners();
    return true;
  }

  // === ÇOCUK SAHİBİ OLMAYI DENE ===
  Child? tryForChild() {
    if (state.wifeMorale >= 80 && state.hasWife) {
      // Rastgele isim ve cinsiyet
      final isMale = _random.nextBool();
      final names = isMale
          ? ['Marcus', 'Lucius', 'Gaius', 'Titus', 'Quintus', 'Decimus']
          : ['Julia', 'Livia', 'Cornelia', 'Aurelia', 'Claudia', 'Octavia'];
      final name = names[_random.nextInt(names.length)];
      final child = state.addChild(name, isMale);
      if (child != null) {
        state.reputation += 50; // Varis = itibar
        notifyListeners();
      }
      return child;
    }
    return null;
  }

  // === DİYALOG İNDEKSİNİ İLERLET ===
  void advanceDialogue(int totalDialogues) {
    state.dialogueIndex = (state.dialogueIndex + 1) % totalDialogues;
    notifyListeners();
  }

  // === GÖREV SİSTEMİ ===
  void addMission(ActiveMission mission) {
    state.activeMissions.add(mission);
    notifyListeners();
  }

  void removeMission(String missionId) {
    state.activeMissions.removeWhere((m) => m.id == missionId);
    notifyListeners();
  }

  // Görev tamamla
  void completeMission(String missionId) {
    final missionIndex = state.activeMissions.indexWhere((m) => m.id == missionId);
    if (missionIndex != -1) {
      final mission = state.activeMissions[missionIndex];
      mission.isCompleted = true;
      state.modifyGold(mission.rewardGold);
      state.activeMissions.removeAt(missionIndex);
      notifyListeners();
    }
  }

  // Görev başarısız
  void failMission(String missionId) {
    final missionIndex = state.activeMissions.indexWhere((m) => m.id == missionId);
    if (missionIndex != -1) {
      final mission = state.activeMissions[missionIndex];
      mission.isFailed = true;
      state.modifyReputation(mission.penaltyReputation);
      state.activeMissions.removeAt(missionIndex);
      notifyListeners();
    }
  }

  // Şikeli dövüş kontrolü - gladyatör kaybederse görev tamamlanır
  ActiveMission? getFixFightMission() {
    try {
      return state.activeMissions.firstWhere(
        (m) => m.type == MissionType.fixFight && !m.isCompleted && !m.isFailed,
      );
    } catch (_) {
      return null;
    }
  }

  // Haftalık görev güncellemesi
  void updateMissionsOnWeekEnd() {
    final toRemove = <String>[];

    for (final mission in state.activeMissions) {
      if (mission.durationWeeks != null) {
        mission.remainingWeeks--;
        if (mission.remainingWeeks <= 0) {
          // Süre doldu - başarısız
          mission.isFailed = true;
          state.modifyReputation(mission.penaltyReputation);
          toRemove.add(mission.id);
        }
      }
    }

    for (final id in toRemove) {
      state.activeMissions.removeWhere((m) => m.id == id);
    }

    notifyListeners();
  }

  // Hafta geçişinde story kontrolü (artık JSON'dan hafta bazlı kontrol ediliyor)
  // Bu metod sadece bir placeholder - asıl kontrol getCurrentWeekStory() ile yapılıyor
  void _checkForWeeklyStory() {
    // Story kontrolü artık home_screen'de getCurrentWeekStory() ile yapılıyor
    // Bu metod geriye dönük uyumluluk için bırakıldı
  }
}

// Dövüş sonucu
class FightResult {
  final bool won;
  final String message;
  final int damageReceived;
  final int reward;

  FightResult({
    required this.won,
    required this.message,
    required this.damageReceived,
    required this.reward,
  });
}

// Pazarlık sonucu
class BluffResult {
  final bool success;
  final String message;
  final int goldChange;
  final int playerRoll;
  final int rivalRoll;

  BluffResult({
    required this.success,
    required this.message,
    required this.goldChange,
    this.playerRoll = 0,
    this.rivalRoll = 0,
  });
}

// Maaş ödeme sonucu
class SalaryResult {
  final bool paid;
  final int totalPaid;
  final String message;
  final bool rebellionRisk;

  SalaryResult({
    required this.paid,
    required this.totalPaid,
    required this.message,
    required this.rebellionRisk,
  });
}

// Event sonucu
class EventResult {
  final String message;
  final Child? child;

  EventResult({
    required this.message,
    this.child,
  });
}
