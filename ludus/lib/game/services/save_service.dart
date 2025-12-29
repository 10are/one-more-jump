import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';
import '../models/gladiator.dart';

/// Save/Load sistemi için servis
class SaveService {
  static const String _autoSaveKey = 'ludus_auto_save';
  static const String _settingsKey = 'ludus_settings';
  static const String _tutorialKey = 'ludus_tutorial_seen';

  /// Oyun kaydı var mı kontrol et
  static Future<bool> hasSaveData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_autoSaveKey);
  }

  /// Auto-save yap
  static Future<bool> autoSave(GameState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = _gameStateToJson(state);
      final jsonString = json.encode(jsonData);
      await prefs.setString(_autoSaveKey, jsonString);
      return true;
    } catch (e) {
      print('Auto-save error: $e');
      return false;
    }
  }

  /// Kayıtlı oyunu yükle
  static Future<GameState?> loadGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_autoSaveKey);
      if (jsonString == null) return null;

      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return _gameStateFromJson(jsonData);
    } catch (e) {
      print('Load game error: $e');
      return null;
    }
  }

  /// Kaydı sil
  static Future<bool> deleteSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_autoSaveKey);
      return true;
    } catch (e) {
      print('Delete save error: $e');
      return false;
    }
  }

  /// Ayarları kaydet
  static Future<bool> saveSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(settings);
      await prefs.setString(_settingsKey, jsonString);
      return true;
    } catch (e) {
      print('Save settings error: $e');
      return false;
    }
  }

  /// Ayarları yükle
  static Future<Map<String, dynamic>> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_settingsKey);
      if (jsonString == null) {
        return {'musicEnabled': true, 'sfxEnabled': true};
      }
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Load settings error: $e');
      return {'musicEnabled': true, 'sfxEnabled': true};
    }
  }

  /// Tutorial görüldü mü kontrol et
  static Future<bool> hasTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialKey) ?? false;
  }

  /// Tutorial görüldü olarak işaretle
  static Future<void> setTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialKey, true);
  }

  /// GameState -> JSON
  static Map<String, dynamic> _gameStateToJson(GameState state) {
    return {
      'phase': state.phase.index,
      'gold': state.gold,
      'week': state.week,
      'reputation': state.reputation,
      'gladiators': state.gladiators.map((g) => _gladiatorToJson(g)).toList(),
      'fights': state.fights.map((f) => _fightToJson(f)).toList(),
      'rivals': state.rivals.map((r) => _rivalToJson(r)).toList(),
      'staff': state.staff.map((s) => _staffToJson(s)).toList(),
      'activeMissions': state.activeMissions.map((m) => _missionToJson(m)).toList(),
      'hasWife': state.hasWife,
      'wifeName': state.wifeName,
      'wifeMorale': state.wifeMorale,
      'hasChild': state.hasChild,
      'dialogueIndex': state.dialogueIndex,
      'storyWeeks': state.storyWeeks,
      'seenStories': state.seenStories.toList(),
      'savedAt': DateTime.now().toIso8601String(),
    };
  }

  /// JSON -> GameState
  static GameState _gameStateFromJson(Map<String, dynamic> json) {
    final state = GameState(
      phase: GamePhase.values[json['phase'] as int],
      gold: json['gold'] as int,
      week: json['week'] as int,
      reputation: json['reputation'] as int,
      gladiators: (json['gladiators'] as List)
          .map((g) => _gladiatorFromJson(g as Map<String, dynamic>))
          .toList(),
      fights: (json['fights'] as List)
          .map((f) => _fightFromJson(f as Map<String, dynamic>))
          .toList(),
      rivals: (json['rivals'] as List)
          .map((r) => _rivalFromJson(r as Map<String, dynamic>))
          .toList(),
      staff: (json['staff'] as List)
          .map((s) => _staffFromJson(s as Map<String, dynamic>))
          .toList(),
      activeMissions: (json['activeMissions'] as List)
          .map((m) => _missionFromJson(m as Map<String, dynamic>))
          .toList(),
      hasWife: json['hasWife'] as bool,
      wifeName: json['wifeName'] as String,
      wifeMorale: json['wifeMorale'] as int,
      hasChild: json['hasChild'] as bool,
      dialogueIndex: json['dialogueIndex'] as int,
      storyWeeks: json['storyWeeks'] != null 
          ? List<int>.from(json['storyWeeks'] as List)
          : null,
      seenStories: json['seenStories'] != null
          ? Set<String>.from(json['seenStories'] as List)
          : null,
    );
    return state;
  }

  /// Gladiator -> JSON
  static Map<String, dynamic> _gladiatorToJson(Gladiator g) {
    return {
      'id': g.id,
      'name': g.name,
      'imagePath': g.imagePath,
      'health': g.health,
      'strength': g.strength,
      'intelligence': g.intelligence,
      'stamina': g.stamina,
      'age': g.age,
      'origin': g.origin,
      'salary': g.salary,
      'morale': g.morale,
      'price': g.price,
      'wins': g.wins,
      'losses': g.losses,
      'isInjured': g.isInjured,
      'hasFood': g.hasFood,
      'hasWater': g.hasWater,
    };
  }

  /// JSON -> Gladiator
  static Gladiator _gladiatorFromJson(Map<String, dynamic> json) {
    return Gladiator(
      id: json['id'] as String,
      name: json['name'] as String,
      imagePath: json['imagePath'] as String?,
      health: json['health'] as int,
      strength: json['strength'] as int,
      intelligence: json['intelligence'] as int,
      stamina: json['stamina'] as int,
      age: json['age'] as int,
      origin: json['origin'] as String,
      salary: json['salary'] as int,
      morale: json['morale'] as int,
      price: json['price'] as int?,
    )
      ..wins = json['wins'] as int
      ..losses = json['losses'] as int
      ..isInjured = json['isInjured'] as bool
      ..hasFood = json['hasFood'] as bool? ?? false
      ..hasWater = json['hasWater'] as bool? ?? false;
  }

  /// FightOpportunity -> JSON
  static Map<String, dynamic> _fightToJson(FightOpportunity f) {
    return {
      'id': f.id,
      'title': f.title,
      'description': f.description,
      'type': f.type.index,
      'reward': f.reward,
      'difficulty': f.difficulty,
      'enemyPower': f.enemyPower,
      'requiredReputation': f.requiredReputation,
      'isAvailable': f.isAvailable,
    };
  }

  /// JSON -> FightOpportunity
  static FightOpportunity _fightFromJson(Map<String, dynamic> json) {
    return FightOpportunity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: FightType.values[json['type'] as int],
      reward: json['reward'] as int,
      difficulty: json['difficulty'] as int,
      enemyPower: json['enemyPower'] as int,
      requiredReputation: json['requiredReputation'] as int? ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  /// Rival -> JSON
  static Map<String, dynamic> _rivalToJson(Rival r) {
    return {
      'id': r.id,
      'name': r.name,
      'title': r.title,
      'type': r.type.index,
      'wealth': r.wealth,
      'influence': r.influence,
      'relationship': r.relationship,
      'personality': r.personality,
      'description': r.description,
      'imagePath': r.imagePath,
    };
  }

  /// JSON -> Rival
  static Rival _rivalFromJson(Map<String, dynamic> json) {
    return Rival(
      id: json['id'] as String,
      name: json['name'] as String,
      title: json['title'] as String,
      type: RivalType.values[json['type'] as int],
      wealth: json['wealth'] as int,
      influence: json['influence'] as int,
      relationship: json['relationship'] as int? ?? 0,
      personality: json['personality'] as String,
      description: json['description'] as String,
      imagePath: json['imagePath'] as String?,
    );
  }

  /// Staff -> JSON
  static Map<String, dynamic> _staffToJson(Staff s) {
    return {
      'id': s.id,
      'name': s.name,
      'role': s.role.index,
      'salary': s.salary,
      'skill': s.skill,
      'bonus': s.bonus,
      'description': s.description,
      'imagePath': s.imagePath,
    };
  }

  /// JSON -> Staff
  static Staff _staffFromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'] as String,
      name: json['name'] as String,
      role: StaffRole.values[json['role'] as int],
      salary: json['salary'] as int,
      skill: json['skill'] as int,
      bonus: json['bonus'] as int? ?? 0,
      description: json['description'] as String,
      imagePath: json['imagePath'] as String?,
    );
  }

  /// ActiveMission -> JSON
  static Map<String, dynamic> _missionToJson(ActiveMission m) {
    return {
      'id': m.id,
      'missionId': m.missionId,
      'type': m.type.index,
      'title': m.title,
      'giverId': m.giverId,
      'targetGladiatorId': m.targetGladiatorId,
      'rewardGold': m.rewardGold,
      'penaltyReputation': m.penaltyReputation,
      'healthDamage': m.healthDamage,
      'moraleChange': m.moraleChange,
      'riskCaught': m.riskCaught,
      'costGold': m.costGold,
      'durationWeeks': m.durationWeeks,
      'remainingWeeks': m.remainingWeeks,
      'isCompleted': m.isCompleted,
      'isFailed': m.isFailed,
    };
  }

  /// JSON -> ActiveMission
  static ActiveMission _missionFromJson(Map<String, dynamic> json) {
    return ActiveMission(
      id: json['id'] as String,
      missionId: json['missionId'] as String,
      type: MissionType.values[json['type'] as int],
      title: json['title'] as String,
      giverId: json['giverId'] as String,
      targetGladiatorId: json['targetGladiatorId'] as String?,
      rewardGold: json['rewardGold'] as int? ?? 0,
      penaltyReputation: json['penaltyReputation'] as int? ?? 0,
      healthDamage: json['healthDamage'] as int?,
      moraleChange: json['moraleChange'] as int?,
      riskCaught: json['riskCaught'] as int?,
      costGold: json['costGold'] as int?,
      durationWeeks: json['durationWeeks'] as int?,
      remainingWeeks: json['remainingWeeks'] as int? ?? 1,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isFailed: json['isFailed'] as bool? ?? false,
    );
  }

  /// Save bilgisini al (tarih vs)
  static Future<Map<String, dynamic>?> getSaveInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_autoSaveKey);
      if (jsonString == null) return null;

      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return {
        'week': jsonData['week'],
        'gold': jsonData['gold'],
        'reputation': jsonData['reputation'],
        'gladiatorCount': (jsonData['gladiators'] as List).length,
        'savedAt': jsonData['savedAt'],
      };
    } catch (e) {
      return null;
    }
  }
}
