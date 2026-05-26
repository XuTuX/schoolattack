enum CharacterGrade { normal, rare, epic, legendary }

enum CharacterType {
  normalStudent,
  iljin,
  shuttle,
  captain,
  studious,
  prefect,
  lunchLady,
  storeKeeper,
  chemTeacher,
  peTeacher
}

class CharacterTemplate {
  final CharacterType type;
  final String name;
  final CharacterGrade grade;
  final int cost;
  final int maxHp;
  final int attack;
  final String emoji;
  final String description;

  const CharacterTemplate({
    required this.type,
    required this.name,
    required this.grade,
    required this.cost,
    required this.maxHp,
    required this.attack,
    required this.emoji,
    required this.description,
  });

  static const List<CharacterTemplate> templates = [
    CharacterTemplate(
      type: CharacterType.normalStudent,
      name: '일반 학생',
      grade: CharacterGrade.normal,
      cost: 2,
      maxHp: 100,
      attack: 15,
      emoji: '🧑‍🎓',
      description: '평범하지만 든든한 학급의 기둥입니다. (스킬: 칠판 지우개 투척)',
    ),
    CharacterTemplate(
      type: CharacterType.shuttle,
      name: '빵셔틀',
      grade: CharacterGrade.normal,
      cost: 2,
      maxHp: 80,
      attack: 10,
      emoji: '🍞',
      description: '사망 시 눈물의 매점 질주! 아군 전체에게 공격력 +5 버프를 부여합니다.',
    ),
    CharacterTemplate(
      type: CharacterType.iljin,
      name: '일진',
      grade: CharacterGrade.rare,
      cost: 3,
      maxHp: 150,
      attack: 20,
      emoji: '😈',
      description: '싸울수록 달아오릅니다. 공격할 때마다 자신의 공격력이 5씩 증가합니다.',
    ),
    CharacterTemplate(
      type: CharacterType.prefect,
      name: '선도부장',
      grade: CharacterGrade.rare,
      cost: 3,
      maxHp: 240,
      attack: 12,
      emoji: '👮',
      description: '아군을 통제하며 지킵니다. 전투 시작 시 아군 전체에게 보호막 40을 부여합니다. (스킬: 추가 배리어)',
    ),
    CharacterTemplate(
      type: CharacterType.studious,
      name: '전교 1등',
      grade: CharacterGrade.epic,
      cost: 4,
      maxHp: 110,
      attack: 30,
      emoji: '📝',
      description: '정밀 타격! 마나가 가득 차면 체력이 가장 낮은 적을 저격하여 2배의 피해를 줍니다.',
    ),
    CharacterTemplate(
      type: CharacterType.captain,
      name: '축구부 주장',
      grade: CharacterGrade.epic,
      cost: 4,
      maxHp: 180,
      attack: 25,
      emoji: '⚽',
      description:
          '강력한 캐논 슛! 마나가 가득 차면 정면 일직선(동일 행) 상의 모든 적을 꿰뚫어 1.5배 피해를 줍니다.',
    ),
    CharacterTemplate(
      type: CharacterType.chemTeacher,
      name: '화학 선생님',
      grade: CharacterGrade.epic,
      cost: 4,
      maxHp: 120,
      attack: 22,
      emoji: '🧪',
      description: '독성 화합물 투척! 마나가 가득 차면 무작위 적 3명에게 3턴 동안 매 턴 15의 독 피해를 입힙니다.',
    ),
    CharacterTemplate(
      type: CharacterType.lunchLady,
      name: '급식 이모',
      grade: CharacterGrade.legendary,
      cost: 5,
      maxHp: 200,
      attack: 15,
      emoji: '🧑‍🍳',
      description: '따뜻한 고기반찬! 마나가 가득 차면 체력이 가장 낮은 아군 1명을 50만큼 치유합니다.',
    ),
    CharacterTemplate(
      type: CharacterType.storeKeeper,
      name: '매점 아주머니',
      grade: CharacterGrade.legendary,
      cost: 5,
      maxHp: 140,
      attack: 18,
      emoji: '🏪',
      description: '매점 특가 세일! 전장 또는 대기석에 존재할 시 매 라운드 골드 +2, 리롤 비용 -1이 됩니다.',
    ),
    CharacterTemplate(
      type: CharacterType.peTeacher,
      name: '체육 선생님',
      grade: CharacterGrade.legendary,
      cost: 5,
      maxHp: 300,
      attack: 35,
      emoji: '🏋️',
      description: '밀착 체력 훈련! 배치 시 인접한(상하좌우) 아군 캐릭터들의 체력을 50씩 올려줍니다.',
    ),
  ];

  static CharacterTemplate getByType(CharacterType type) {
    return templates.firstWhere((t) => t.type == type);
  }
}

class CharacterInstance {
  final String id;
  final CharacterTemplate template;
  int starLevel; // 1, 2, 3성
  int mana; // 0 ~ 100 마나 게이지
  int currentHp;
  int currentMaxHp;
  int currentAttack;
  int shield;
  int poisonDuration;
  int poisonDamage;
  bool deathHandled;

  CharacterInstance({
    required this.id,
    required this.template,
    this.starLevel = 1,
    this.mana = 0,
    int? currentHp,
    int? currentMaxHp,
    int? currentAttack,
    this.shield = 0,
    this.poisonDuration = 0,
    this.poisonDamage = 0,
    this.deathHandled = false,
  })  : currentHp = currentHp ?? _scaleHp(template.maxHp, starLevel),
        currentMaxHp = currentMaxHp ?? _scaleHp(template.maxHp, starLevel),
        currentAttack =
            currentAttack ?? _scaleAttack(template.attack, starLevel);

  // 성급에 따른 체력 증폭 공식
  static int _scaleHp(int baseHp, int star) {
    if (star == 2) return (baseHp * 1.8).toInt();
    if (star == 3) return (baseHp * 3.2).toInt();
    return baseHp;
  }

  // 성급에 따른 공격력 증폭 공식
  static int _scaleAttack(int baseAttack, int star) {
    if (star == 2) return (baseAttack * 1.6).toInt();
    if (star == 3) return (baseAttack * 2.8).toInt();
    return baseAttack;
  }

  CharacterType get type => template.type;
  String get name => template.name;
  CharacterGrade get grade => template.grade;
  int get cost => template.cost;
  String get emoji => template.emoji;
  String get description => template.description;

  bool get isDead => currentHp <= 0;

  // 진급/합성 시 호출
  void upgradeStar() {
    if (starLevel >= 3) return;
    starLevel++;
    currentMaxHp = _scaleHp(template.maxHp, starLevel);
    currentHp = currentMaxHp; // HP 완전히 회복
    currentAttack = _scaleAttack(template.attack, starLevel);
  }

  void takeDamage(int amount) {
    if (amount <= 0) return;
    if (shield >= amount) {
      shield -= amount;
    } else {
      final remain = amount - shield;
      shield = 0;
      currentHp -= remain;
      if (currentHp < 0) currentHp = 0;
    }
  }

  void heal(int amount) {
    if (isDead) return;
    currentHp += amount;
    if (currentHp > currentMaxHp) {
      currentHp = currentMaxHp;
    }
  }

  CharacterInstance clone() {
    return CharacterInstance(
      id: id,
      template: template,
      starLevel: starLevel,
      mana: mana,
      currentHp: currentHp,
      currentMaxHp: currentMaxHp,
      currentAttack: currentAttack,
      shield: shield,
      poisonDuration: poisonDuration,
      poisonDamage: poisonDamage,
      deathHandled: deathHandled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': template.type.name,
      'starLevel': starLevel,
      'mana': mana,
      'currentHp': currentHp,
      'currentMaxHp': currentMaxHp,
      'currentAttack': currentAttack,
      'deathHandled': deathHandled,
    };
  }

  factory CharacterInstance.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String;
    final type = CharacterType.values.firstWhere((e) => e.name == typeName);
    final template = CharacterTemplate.getByType(type);
    return CharacterInstance(
      id: json['id'] as String,
      template: template,
      starLevel: json['starLevel'] as int? ?? 1,
      mana: json['mana'] as int? ?? 0,
      currentHp: json['currentHp'] as int,
      currentMaxHp: json['currentMaxHp'] as int,
      currentAttack: json['currentAttack'] as int,
      deathHandled: json['deathHandled'] as bool? ?? false,
    );
  }
}
