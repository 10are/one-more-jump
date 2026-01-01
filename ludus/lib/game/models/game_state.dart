import 'gladiator.dart';
import '../constants.dart';

enum GamePhase { menu, playing, gameOver }

// Dövüş türleri
enum FightType { underground, smallArena, bigArena }

// Dövüş fırsatı
class FightOpportunity {
  final String id;
  final String title;
  final String description;
  final FightType type;
  final int reward;
  final int difficulty;
  final int enemyPower;
  final int requiredReputation; // Gerekli itibar
  bool isAvailable;

  FightOpportunity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.reward,
    required this.difficulty,
    required this.enemyPower,
    this.requiredReputation = 0,
    this.isAvailable = true,
  });
}

// Rakip türleri
enum RivalType { lanista, politician, military }

// Rakip ev sahibi
class Rival {
  final String id;
  final String name;
  final String title; // Lanista, Senator, Legatus
  final RivalType type;
  int wealth;
  int influence;
  int relationship; // -100 to 100
  final String personality;
  final String description;
  final String? imagePath;

  Rival({
    required this.id,
    required this.name,
    required this.title,
    required this.type,
    required this.wealth,
    required this.influence,
    this.relationship = 0,
    required this.personality,
    required this.description,
    this.imagePath,
  });
}

// Personel rolleri
enum StaffRole { doctor, trainer, servant }

// Görev türleri
enum MissionType { fixFight, rentGladiator, sabotage, senatorFavor, training, poison, bribe, patronage }

// Çocuk sınıfı
class Child {
  final String id;
  final String name;
  final bool isMale; // true = erkek, false = kız
  int birthWeek; // Doğduğu hafta

  Child({
    required this.id,
    required this.name,
    required this.isMale,
    required this.birthWeek,
  });

  // Çocuğun yaşı (hafta olarak)
  int ageInWeeks(int currentWeek) => currentWeek - birthWeek;
}

// Aktif görev
class ActiveMission {
  final String id;
  final String missionId;
  final MissionType type;
  final String title;
  final String giverId;
  final String? targetGladiatorId;
  final int rewardGold;
  final int penaltyReputation;
  final int? healthDamage;
  final int? moraleChange;
  final int? riskCaught;
  final int? costGold;
  final int? durationWeeks;
  int remainingWeeks;
  bool isCompleted;
  bool isFailed;

  ActiveMission({
    required this.id,
    required this.missionId,
    required this.type,
    required this.title,
    required this.giverId,
    this.targetGladiatorId,
    this.rewardGold = 0,
    this.penaltyReputation = 0,
    this.healthDamage,
    this.moraleChange,
    this.riskCaught,
    this.costGold,
    this.durationWeeks,
    this.remainingWeeks = 1,
    this.isCompleted = false,
    this.isFailed = false,
  });
}

// Ev personeli
class Staff {
  final String id;
  final String name;
  final StaffRole role;
  int salary;
  int skill;
  int bonus; // Doktor: tedavi bonusu, Eğitmen: eğitim bonusu
  final String description;
  final String? imagePath;

  Staff({
    required this.id,
    required this.name,
    required this.role,
    required this.salary,
    required this.skill,
    this.bonus = 0,
    required this.description,
    this.imagePath,
  });
}

class GameState {
  GamePhase phase;
  int gold;
  int week;
  int reputation;

  List<Gladiator> gladiators;
  List<FightOpportunity> fights;
  List<Rival> rivals;
  List<Staff> staff;
  List<ActiveMission> activeMissions;

  // Ev / Okul
  bool hasWife;
  String wifeName;
  int wifeMorale; // Eşin morali (0-100)
  List<Child> children; // Çocuklar listesi
  int dialogueIndex; // Hangi diyalogda (haftalık)

  // Haftalık hikayeler
  Set<String> seenStories; // Görülen story ID'leri
  Set<String> seenEvents; // Görülen event ID'leri

  // İnteraktif hikaye seçimleri (oyuncunun kararları)
  Map<String, bool> storyChoices; // Örn: {"helped_stranger": true, "trusted_uncle": false}

  GameState({
    this.phase = GamePhase.menu,
    this.gold = GameConstants.startingGold,
    this.week = 1,
    this.reputation = 0,
    List<Gladiator>? gladiators,
    List<FightOpportunity>? fights,
    List<Rival>? rivals,
    List<Staff>? staff,
    List<ActiveMission>? activeMissions,
    this.hasWife = true,
    this.wifeName = 'Lucretia',
    this.wifeMorale = 50,
    List<Child>? children,
    this.dialogueIndex = 0,
    Set<String>? seenStories,
    Set<String>? seenEvents,
    Map<String, bool>? storyChoices,
  })  : gladiators = gladiators ?? createStartingGladiators(),
        fights = fights ?? _createInitialFights(),
        rivals = rivals ?? _createRivals(),
        staff = staff ?? _createInitialStaff(),
        activeMissions = activeMissions ?? [],
        children = children ?? [],
        seenStories = seenStories ?? {},
        seenEvents = seenEvents ?? {},
        storyChoices = storyChoices ?? {};

  // Savaşabilir gladyatörler
  List<Gladiator> get availableForFight => gladiators.where((g) => g.canFight).toList();

  // Eğitilebilir gladyatörler
  List<Gladiator> get availableForTraining => gladiators.where((g) => g.canTrain).toList();

  // Toplam haftalık maaş
  int get totalWeeklySalary {
    int total = 0;
    for (final g in gladiators) {
      total += g.salary;
    }
    for (final s in staff) {
      total += s.salary;
    }
    return total;
  }

  // Altın ekle/çıkar
  void modifyGold(int amount) {
    gold = (gold + amount).clamp(0, 999999);
  }

  // İtibar ekle/çıkar
  void modifyReputation(int amount) {
    reputation = (reputation + amount).clamp(0, 999999);
  }

  // Hafta geçir
  void advanceWeek() {
    week++;

    // Gladyatörler dinlensin
    for (final glad in gladiators) {
      glad.weeklyRest();
      glad.resetNutrition(); // Beslenme durumu resetle
    }

    // Yeni dövüşler oluştur
    _regenerateFights();
  }

  void _regenerateFights() {
    fights = _createInitialFights();
  }

  // Eş morali değiştir
  void modifyWifeMorale(int amount) {
    wifeMorale = (wifeMorale + amount).clamp(0, 100);
  }

  // Çocuk var mı?
  bool get hasChild => children.isNotEmpty;

  // Çocuk sahibi ol (moral 80+ olmalı)
  Child? addChild(String name, bool isMale) {
    if (wifeMorale >= 80 && hasWife) {
      final child = Child(
        id: 'child_${children.length + 1}',
        name: name,
        isMale: isMale,
        birthWeek: week,
      );
      children.add(child);
      return child;
    }
    return null;
  }

  // Oyunu sıfırla
  void reset() {
    phase = GamePhase.playing;
    gold = GameConstants.startingGold;
    week = 1;
    reputation = 0;
    gladiators = createStartingGladiators();
    fights = _createInitialFights();
    rivals = _createRivals();
    staff = _createInitialStaff();
    activeMissions = [];
    hasWife = true;
    wifeName = 'Lucretia';
    wifeMorale = 50;
    children = [];
    dialogueIndex = 0;
    seenStories = {};
    seenEvents = {};
    storyChoices = {};
  }
}

// Başlangıç dövüşleri
List<FightOpportunity> _createInitialFights() {
  return [
    FightOpportunity(
      id: 'fight_underground_1',
      title: 'Yeraltı Dövüşü',
      description: 'Karanlık bir mahzende yasadışı dövüş',
      type: FightType.underground,
      reward: GameConstants.undergroundFightReward,
      difficulty: 1,
      enemyPower: 25,
    ),
    FightOpportunity(
      id: 'fight_underground_2',
      title: 'Gece Arenası',
      description: 'Gizli kumarhane dövüşü',
      type: FightType.underground,
      reward: GameConstants.undergroundFightReward + 50,
      difficulty: 2,
      enemyPower: 35,
    ),
    FightOpportunity(
      id: 'fight_small_1',
      title: 'Yerel Arena',
      description: 'Kasaba arenasında halka açık dövüş',
      type: FightType.smallArena,
      reward: GameConstants.smallArenaReward,
      difficulty: 2,
      enemyPower: 40,
    ),
    FightOpportunity(
      id: 'fight_big_1',
      title: 'Colosseum',
      description: 'Roma\'nın kalbinde büyük gösteri',
      type: FightType.bigArena,
      reward: GameConstants.bigArenaReward,
      difficulty: 4,
      enemyPower: 60,
      isAvailable: false, // Sonra açılacak
    ),
  ];
}

// Rakipler
List<Rival> _createRivals() {
  return [
    Rival(
      id: 'rival_1',
      name: 'Quintus Batiatus',
      title: 'Lanista',
      type: RivalType.lanista,
      wealth: 2000,
      influence: 40,
      relationship: -10,
      personality: 'cunning',
      description: 'Capua\'nın en kurnaz ludus sahibi',
    ),
    Rival(
      id: 'rival_2',
      name: 'Solonius',
      title: 'Lanista',
      type: RivalType.lanista,
      wealth: 1500,
      influence: 35,
      relationship: -20,
      personality: 'aggressive',
      description: 'Acımasız ve hırslı bir rakip',
    ),
    Rival(
      id: 'rival_3',
      name: 'Senator Albinius',
      title: 'Senator',
      type: RivalType.politician,
      wealth: 5000,
      influence: 80,
      relationship: 0,
      personality: 'cautious',
      description: 'Roma senatosunun güçlü isimlerinden',
    ),
    Rival(
      id: 'rival_4',
      name: 'Legatus Glaber',
      title: 'Legatus',
      type: RivalType.military,
      wealth: 3000,
      influence: 70,
      relationship: 5,
      personality: 'proud',
      description: 'Roma lejyonlarının komutanı',
    ),
  ];
}

// Başlangıç personeli
List<Staff> _createInitialStaff() {
  return [
    Staff(
      id: 'staff_1',
      name: 'Doctore',
      role: StaffRole.trainer,
      salary: 30,
      skill: 40,
      bonus: 2,
      description: 'Gladyatör eğitmeni',
    ),
  ];
}
