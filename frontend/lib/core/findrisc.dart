/// Score de risque FINDRISC calculé sur le téléphone (fonctionne hors ligne).
/// Identique au backend. Estimation statistique, jamais un diagnostic.
class RisqueInput {
  int age = 40;
  String sexe = 'F'; // M | F
  double tailleCm = 165;
  double poidsKg = 65;
  double tourTailleCm = 80;
  String activite = 'QUOTIDIEN'; // QUOTIDIEN | PARFOIS | RAREMENT
  bool fruitsLegumes = true;
  bool hypertension = false;
  bool glycemieElevee = false;
  String antecedents = 'AUCUN'; // AUCUN | SECOND_DEGRE | PREMIER_DEGRE

  Map<String, dynamic> toJson() => {
    'age': age,
    'sexe': sexe,
    'tailleCm': tailleCm,
    'poidsKg': poidsKg,
    'tourTailleCm': tourTailleCm,
    'activite': activite,
    'fruitsLegumesQuotidien': fruitsLegumes,
    'traitementHypertension': hypertension,
    'glycemieElevee': glycemieElevee,
    'antecedents': antecedents,
  };
}

class RisqueResult {
  static const int scoreMax = 26;
  final int score;
  final String niveau; // FAIBLE | LEGER | MODERE | ELEVE | TRES_ELEVE
  final List<String> codes;
  final DateTime date;

  const RisqueResult({
    required this.score,
    required this.niveau,
    required this.codes,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'score': score,
    'niveau': niveau,
    'codes': codes,
    'date': date.toUtc().toIso8601String(),
  };

  factory RisqueResult.fromJson(Map<String, dynamic> j) => RisqueResult(
    score: (j['score'] as num).toInt(),
    niveau: j['niveau'] as String,
    codes: (j['codes'] as List).map((e) => e.toString()).toList(),
    date: DateTime.parse(j['date'] as String),
  );
}

String niveauFromScore(int s) {
  if (s < 7) return 'FAIBLE';
  if (s <= 11) return 'LEGER';
  if (s <= 14) return 'MODERE';
  if (s <= 20) return 'ELEVE';
  return 'TRES_ELEVE';
}

RisqueResult computeRisk(RisqueInput i) {
  int score = 0;
  score += i.age < 45 ? 0 : (i.age <= 54 ? 2 : (i.age <= 64 ? 3 : 4));
  final m = i.tailleCm / 100.0;
  final imc = i.poidsKg / (m * m);
  score += imc < 25 ? 0 : (imc <= 30 ? 1 : 3);
  final t = i.tourTailleCm;
  if (i.sexe == 'M') {
    score += t < 94 ? 0 : (t <= 102 ? 3 : 4);
  } else {
    score += t < 80 ? 0 : (t <= 88 ? 3 : 4);
  }
  score += i.activite == 'QUOTIDIEN' ? 0 : (i.activite == 'PARFOIS' ? 1 : 2);
  score += i.fruitsLegumes ? 0 : 1;
  score += i.hypertension ? 2 : 0;
  score += i.glycemieElevee ? 5 : 0;
  score += i.antecedents == 'AUCUN'
      ? 0
      : (i.antecedents == 'SECOND_DEGRE' ? 3 : 5);

  final niveau = niveauFromScore(score);
  final codes = <String>[];
  if (score >= 7) {
    codes.add('CEREALES_LOCALES');
    codes.add('REDUIRE_SUCRES');
  }
  if (imc >= 25) codes.add('PERDRE_POIDS');
  if (i.activite != 'QUOTIDIEN') codes.add('ACTIVITE_PHYSIQUE');
  if (!i.fruitsLegumes) codes.add('LEGUMES_LOCAUX');
  if (i.hypertension) codes.add('SURVEILLER_TENSION');
  if (niveau == 'MODERE' ||
      niveau == 'ELEVE' ||
      niveau == 'TRES_ELEVE' ||
      i.glycemieElevee) {
    codes.add('CONSULTER_GLYCEMIE_JEUN');
  }
  return RisqueResult(
    score: score,
    niveau: niveau,
    codes: codes,
    date: DateTime.now().toUtc(),
  );
}
