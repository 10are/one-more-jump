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
    _initializeStoryWeeks();
    notifyListeners();
  }

  // Story haftalarını başlat (rastgele belirle)
  void _initializeStoryWeeks() {
    if (state.storyWeeks.isNotEmpty) return; // Zaten belirlenmişse tekrar yapma
    
    state.storyWeeks = [];
    state.seenStories = {};
    
    // JSON'dan story'leri yükle ve rastgele haftalar belirle
    // Bu kısım hafta geçişinde kontrol edilecek
  }

  // Mevcut hafta için story var mı kontrol et
  String? getCurrentWeekStoryId() {
    // Story haftaları henüz belirlenmemişse belirle
    if (state.storyWeeks.isEmpty) {
      _determineStoryWeeks();
    }
    
    // Bu hafta için story var mı?
    if (state.storyWeeks.contains(state.week)) {
      return _getStoryIdForWeek(state.week);
    }
    return null;
  }

  // Hafta için story ID'sini döndür
  String? _getStoryIdForWeek(int week) {
    // Story haftaları sıralı, hangi story bu haftaya ait?
    final allStories = _loadAllStoryIds();
    final weekIndex = state.storyWeeks.indexOf(week);
    
    if (weekIndex >= 0 && weekIndex < allStories.length) {
      return allStories[weekIndex];
    }
    return null;
  }

  // Story haftalarını rastgele belirle
  void _determineStoryWeeks() {
    state.storyWeeks = [];
    
    // İlk story her zaman 5. haftada
    state.storyWeeks.add(5);
    
    // JSON'dan tüm story'leri yükle
    final allStories = _loadAllStoryIds();
    
    // Kalan story'ler için rastgele haftalar belirle
    int lastStoryWeek = 5;
    
    for (int i = 1; i < allStories.length; i++) {
      int minGap;
      int extraGap;
      
      // 10. haftadan önce: 3-4 hafta arası
      // 10. haftadan sonra: minimum 5 hafta arası
      if (lastStoryWeek < 10) {
        minGap = 3; // Minimum 3 hafta
        extraGap = 1; // Ekstra 0-1 hafta (toplam 3-4 hafta)
      } else {
        minGap = 5; // Minimum 5 hafta
        extraGap = 2; // Ekstra 0-2 hafta (toplam 5-7 hafta)
      }
      
      // Son story'den en az minGap + extraGap hafta sonra
      int nextWeek = lastStoryWeek + minGap + _random.nextInt(extraGap + 1);
      nextWeek = nextWeek.clamp(1, 200); // Maksimum 200. haftaya kadar
      state.storyWeeks.add(nextWeek);
      lastStoryWeek = nextWeek;
    }
    
    state.storyWeeks.sort();
  }

  // JSON'dan tüm story ID'lerini yükle
  List<String> _loadAllStoryIds() {
    try {
      // JSON'dan story'leri yükle (async olmadan, cache'lenmiş olabilir)
      // Şimdilik basit bir yöntem - ileride cache'lenebilir
      return ['story_1', 'story_2', 'story_3', 'story_4', 'story_5', 'story_6', 'story_7', 'story_8', 'story_9', 'story_10', 'story_11', 'story_12', 'story_13', 'story_14', 'story_15'];
    } catch (e) {
      debugPrint('Story ID yükleme hatası: $e');
      return ['story_1', 'story_2', 'story_3'];
    }
  }

  // JSON'dan story sayısını al (async)
  Future<int> _getStoryCount() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/weekly_stories.json');
      final data = json.decode(jsonString);
      final stories = data['weekly_stories'] as List;
      return stories.length;
    } catch (e) {
      debugPrint('Story sayısı yükleme hatası: $e');
      return 6; // Varsayılan
    }
  }

  // Story görüldü olarak işaretle
  void markStoryAsSeen(String storyId) {
    state.seenStories.add(storyId);
    notifyListeners();
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
  bool tryForChild() {
    if (state.wifeMorale >= 100 && !state.hasChild) {
      state.hasChild = true;
      state.reputation += 50; // Varis = itibar
      notifyListeners();
      return true;
    }
    return false;
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

  // Hafta geçişinde story kontrolü
  void _checkForWeeklyStory() {
    // Story haftaları henüz belirlenmemişse belirle
    if (state.storyWeeks.isEmpty) {
      _determineStoryWeeks();
    }
    
    // Bu hafta için story var mı?
    final storyId = _getStoryIdForWeek(state.week);
    if (storyId != null && !state.seenStories.contains(storyId)) {
      // Story gösterilecek, bu bilgi home_screen'de kontrol edilecek
      // Burada sadece hazırlık yapıyoruz
    }
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
