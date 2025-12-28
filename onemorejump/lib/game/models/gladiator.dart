import '../constants.dart';

class Gladiator {
  final String id;
  String name;
  String? imagePath;

  // 4 Ana Parametre
  int health; // Sağlık (0-100)
  int strength; // Güç (1-100)
  int intelligence; // Zeka (1-100)
  int stamina; // Kondisyon (1-100)

  // Kişisel bilgiler
  int age; // Yaş (değişmez)
  String origin; // Köken (Galya, Trakya, Germania vs)

  // Ekonomi
  int salary; // Haftalık maaş (oyuncu belirler)
  int morale; // Moral (maaştan etkilenir) 0-100
  int? price; // Pazardaki fiyatı (null ise sahip olduğumuz gladyatör)

  // İstatistikler
  int wins;
  int losses;
  bool isInjured;

  Gladiator({
    required this.id,
    required this.name,
    this.imagePath,
    this.health = 100,
    this.strength = 30,
    this.intelligence = 30,
    this.stamina = 30,
    this.age = 25,
    this.origin = 'Roma',
    this.salary = 50,
    this.morale = 50,
    this.price,
    this.wins = 0,
    this.losses = 0,
    this.isInjured = false,
  });

  // Genel güç puanı (dövüş için)
  int get overallPower {
    final healthFactor = health / 100;
    final moraleFactor = 0.5 + (morale / 200); // 0.5 - 1.0
    return ((strength + (intelligence * 0.5) + (stamina * 0.3)) * healthFactor * moraleFactor).toInt();
  }

  // Dövüşebilir mi?
  bool get canFight => !isInjured && health > 20 && morale > 10;

  // Eğitilebilir mi?
  bool get canTrain => !isInjured && health > 30 && stamina > 20;

  // Stat artırma
  void trainStat(String stat, int amount) {
    switch (stat) {
      case 'strength':
        strength = (strength + amount).clamp(GameConstants.minStat, GameConstants.maxStat);
        break;
      case 'intelligence':
        intelligence = (intelligence + amount).clamp(GameConstants.minStat, GameConstants.maxStat);
        break;
      case 'stamina':
        stamina = (stamina + amount).clamp(GameConstants.minStat, GameConstants.maxStat);
        break;
    }
    // Eğitim kondisyonu düşürür
    stamina = (stamina - 3).clamp(GameConstants.minStat, GameConstants.maxStat);
  }

  // Hasar alma
  void takeDamage(int damage) {
    health = (health - damage).clamp(0, 100);
    if (health < 25) {
      isInjured = true;
    }
  }

  // İyileşme
  void heal(int amount) {
    health = (health + amount).clamp(0, 100);
    if (health >= 50) {
      isInjured = false;
    }
  }

  // Moral değişimi
  void changeMorale(int amount) {
    morale = (morale + amount).clamp(0, 100);
  }

  // Dövüş sonrası
  void recordFight(bool won, int damageReceived) {
    if (won) {
      wins++;
      changeMorale(15);
    } else {
      losses++;
      changeMorale(-10);
    }
    takeDamage(damageReceived);
  }

  // Haftalık dinlenme
  void weeklyRest() {
    heal(10);
    stamina = (stamina + 5).clamp(0, 100);
  }

  // Maaş ayarla
  void setSalary(int newSalary) {
    final oldSalary = salary;
    salary = newSalary.clamp(10, 500);

    if (salary > oldSalary) {
      changeMorale(10);
    } else if (salary < oldSalary) {
      changeMorale(-15);
    }
  }

  // Haftalık maaş kontrolü
  bool checkSalaryPayment(int paidAmount) {
    if (paidAmount >= salary) {
      changeMorale(5);
      return true;
    } else if (paidAmount >= salary * 0.5) {
      changeMorale(-10);
      return true;
    } else {
      changeMorale(-25);
      return false; // İsyan riski
    }
  }
}

// Başlangıç gladyatörleri
List<Gladiator> createStartingGladiators() {
  return [
    Gladiator(
      id: 'glad_1',
      name: 'Marcus',
      imagePath: 'assets/defaultasker.png',
      strength: 35,
      intelligence: 25,
      stamina: 40,
      age: 28,
      origin: 'Roma',
      salary: 60,
      morale: 55,
    ),
    Gladiator(
      id: 'glad_2',
      name: 'Crixus',
      imagePath: 'assets/defaultasker.png',
      strength: 45,
      intelligence: 20,
      stamina: 35,
      age: 32,
      origin: 'Galya',
      salary: 70,
      morale: 50,
    ),
    Gladiator(
      id: 'glad_3',
      name: 'Oenomaus',
      imagePath: 'assets/defaultasker.png',
      strength: 30,
      intelligence: 40,
      stamina: 30,
      age: 35,
      origin: 'Numidia',
      salary: 55,
      morale: 60,
    ),
  ];
}
