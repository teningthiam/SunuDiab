import 'package:uuid/uuid.dart';

import '../core/glycemia.dart';

double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
int? _i(dynamic v) => v == null ? null : (v as num).toInt();

class UserInfo {
  final int id;
  final String nom;
  final String prenom;
  final String? email;
  final String? telephone;
  final String role;
  final String langue;
  final int? patientId;

  const UserInfo({
    required this.id,
    required this.nom,
    required this.prenom,
    this.email,
    this.telephone,
    required this.role,
    required this.langue,
    this.patientId,
  });

  String get nomComplet => '$prenom $nom';

  factory UserInfo.fromJson(Map<String, dynamic> j) => UserInfo(
    id: _i(j['id'])!,
    nom: (j['nom'] ?? '') as String,
    prenom: (j['prenom'] ?? '') as String,
    email: j['email'] as String?,
    telephone: j['telephone'] as String?,
    role: (j['role'] ?? 'PATIENT') as String,
    langue: (j['langue'] ?? 'FR') as String,
    patientId: _i(j['patientId']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'telephone': telephone,
    'role': role,
    'langue': langue,
    'patientId': patientId,
  };
}

class Contact {
  final int id;
  final String nom;
  final String telephone;
  final String? lien;
  const Contact({
    required this.id,
    required this.nom,
    required this.telephone,
    this.lien,
  });

  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
    id: _i(j['id'])!,
    nom: (j['nom'] ?? '') as String,
    telephone: (j['telephone'] ?? '') as String,
    lien: j['lien'] as String?,
  );
}

/// Profil du patient (réponse du serveur conservée telle quelle pour le cache hors ligne).
class Profil {
  final Map<String, dynamic> raw;
  const Profil(this.raw);

  int get id => _i(raw['id']) ?? 0;
  String get numeroDossier => (raw['numeroDossier'] ?? '') as String;
  String get nom => (raw['nom'] ?? '') as String;
  String get prenom => (raw['prenom'] ?? '') as String;
  String get nomComplet => '$prenom $nom';
  String? get telephone => raw['telephone'] as String?;
  int? get age => _i(raw['age']);
  String? get sexe => raw['sexe'] as String?;
  String get typeDiabete => (raw['typeDiabete'] ?? 'AUCUN') as String;
  double? get tailleCm => _d(raw['tailleCm']);
  double? get poidsKg => _d(raw['poidsKg']);
  double? get tourTailleCm => _d(raw['tourTailleCm']);
  double? get imc => _d(raw['imc']);
  int? get tensionSystolique => _i(raw['tensionSystolique']);
  int? get tensionDiastolique => _i(raw['tensionDiastolique']);
  bool get antecedentsFamiliaux => raw['antecedentsFamiliaux'] == true;
  String? get couvertureIpm => raw['couvertureIpm'] as String?;
  String? get quartier => raw['quartier'] as String?;
  String? get ville => raw['ville'] as String?;
  String? get region => raw['region'] as String?;
  int? get medecinReferentId => _i(raw['medecinReferentId']);
  String? get medecinReferentNom => raw['medecinReferentNom'] as String?;
  String? get infirmierRelaisNom => raw['infirmierRelaisNom'] as String?;
  String? get infirmierRelaisTelephone =>
      raw['infirmierRelaisTelephone'] as String?;
  bool get rappelSms => raw['rappelSms'] != false;
  bool get partageDossier => raw['partageDossier'] != false;
  double get cibleMin => _d(raw['cibleMin']) ?? 0.70;
  double get cibleMax => _d(raw['cibleMax']) ?? 1.30;
  double? get derniereHba1c => _d(raw['derniereHba1c']);
  bool get aProfilSante => tailleCm != null && poidsKg != null;

  List<Contact> get contacts => ((raw['contacts'] ?? []) as List)
      .map((e) => Contact.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

class Mesure {
  final String clientUuid;
  final int? serverId;
  final double valeur;
  final String moment;
  final String methode;
  final String? contexte;
  final String? note;
  final DateTime mesureLe;
  final GStatus statut;
  final bool supprime;
  final bool synced;

  const Mesure({
    required this.clientUuid,
    this.serverId,
    required this.valeur,
    required this.moment,
    required this.methode,
    this.contexte,
    this.note,
    required this.mesureLe,
    required this.statut,
    required this.supprime,
    required this.synced,
  });

  factory Mesure.create({
    required double valeur,
    required String moment,
    String methode = 'CLAVIER',
    String? contexte,
    String? note,
    required GStatus statut,
  }) => Mesure(
    clientUuid: const Uuid().v4(),
    valeur: valeur,
    moment: moment,
    methode: methode,
    contexte: contexte,
    note: note,
    mesureLe: DateTime.now().toUtc(),
    statut: statut,
    supprime: false,
    synced: false,
  );

  factory Mesure.fromDb(Map<String, Object?> m) => Mesure(
    clientUuid: m['client_uuid'] as String,
    serverId: m['server_id'] as int?,
    valeur: (m['valeur'] as num).toDouble(),
    moment: m['moment'] as String,
    methode: (m['methode'] as String?) ?? 'CLAVIER',
    contexte: m['contexte'] as String?,
    note: m['note'] as String?,
    mesureLe: DateTime.parse(m['mesure_le'] as String),
    statut: statusFromServer(m['statut'] as String?),
    supprime: (m['supprime'] as int) == 1,
    synced: (m['synced'] as int) == 1,
  );

  factory Mesure.fromServer(Map<String, dynamic> j) => Mesure(
    clientUuid: j['clientUuid'] as String,
    serverId: _i(j['id']),
    valeur: _d(j['valeur'])!,
    moment: (j['moment'] ?? 'A_JEUN') as String,
    methode: (j['methode'] ?? 'CLAVIER') as String,
    contexte: j['contexte'] as String?,
    note: j['note'] as String?,
    mesureLe: DateTime.parse(j['mesureLe'] as String).toUtc(),
    statut: statusFromServer(j['statut'] as String?),
    supprime: j['supprime'] == true,
    synced: true,
  );

  Map<String, Object?> toDb() => {
    'client_uuid': clientUuid,
    'server_id': serverId,
    'valeur': valeur,
    'moment': moment,
    'methode': methode,
    'contexte': contexte,
    'note': note,
    'mesure_le': mesureLe.toUtc().toIso8601String(),
    'statut': statusToServer(statut),
    'supprime': supprime ? 1 : 0,
    'synced': synced ? 1 : 0,
  };

  Map<String, dynamic> toSyncJson() => {
    'clientUuid': clientUuid,
    'valeur': valeur,
    'moment': moment,
    'methode': methode,
    'contexte': contexte,
    'note': note,
    'mesureLe': mesureLe.toUtc().toIso8601String(),
    'supprime': supprime,
  };
}

class Traitement {
  final Map<String, dynamic> raw;
  const Traitement(this.raw);
  int get id => _i(raw['id'])!;
  String get medicament => (raw['medicament'] ?? '') as String;
  String? get dosage => raw['dosage'] as String?;
  String? get posologie => raw['posologie'] as String?;
  String? get horaires => raw['horaires'] as String?;
  bool get actif => raw['actif'] != false;
  int? get stockRestant => _i(raw['stockRestant']);
  String? get prescripteur => raw['prescripteur'] as String?;
}

class Ordonnance {
  final Map<String, dynamic> raw;
  const Ordonnance(this.raw);
  int get id => _i(raw['id'])!;
  String get numero => (raw['numero'] ?? '') as String;
  String get lignes => (raw['lignes'] ?? '') as String;
  String? get pharmacie => raw['pharmacie'] as String?;
  String? get medecin => raw['medecin'] as String?;
  DateTime? get dateExpiration => raw['dateExpiration'] == null
      ? null
      : DateTime.tryParse(raw['dateExpiration'] as String);
  DateTime? get dateEmission => raw['dateEmission'] == null
      ? null
      : DateTime.tryParse(raw['dateEmission'] as String);
}

class Rdv {
  final Map<String, dynamic> raw;
  const Rdv(this.raw);
  int get id => _i(raw['id'])!;
  String get medecinNom => (raw['medecinNom'] ?? '') as String;
  DateTime get dateHeure => DateTime.parse(raw['dateHeure'] as String);
  String get mode => (raw['mode'] ?? 'PRESENTIEL') as String;
  String get statut => (raw['statut'] ?? 'EN_ATTENTE') as String;
  String? get motif => raw['motif'] as String?;
  String? get lieu => raw['lieu'] as String?;
  bool get annulable =>
      (statut == 'EN_ATTENTE' || statut == 'CONFIRME') &&
      dateHeure.isAfter(DateTime.now());
}

class Medecin {
  final int id;
  final String nomComplet;
  final String? specialite;
  final String? structure;
  const Medecin({
    required this.id,
    required this.nomComplet,
    this.specialite,
    this.structure,
  });
  factory Medecin.fromJson(Map<String, dynamic> j) => Medecin(
    id: _i(j['id'])!,
    nomComplet: (j['nomComplet'] ?? '') as String,
    specialite: j['specialite'] as String?,
    structure: j['structure'] as String?,
  );
}

class Conseil {
  final Map<String, dynamic> raw;
  const Conseil(this.raw);
  int get id => _i(raw['id'])!;
  String? get categorie => raw['categorie'] as String?;
  String title(String lang) {
    final wo = raw['titreWo'] as String?;
    if (lang == 'wo' && wo != null && wo.trim().isNotEmpty) return wo;
    return (raw['titreFr'] ?? '') as String;
  }

  String body(String lang) {
    final wo = raw['contenuWo'] as String?;
    if (lang == 'wo' && wo != null && wo.trim().isNotEmpty) return wo;
    return (raw['contenuFr'] ?? '') as String;
  }
}

class ChatMsg {
  final String auteur; // PATIENT | ASSISTANT
  final String contenu;
  final bool urgence;
  final bool erreur;
  final DateTime createdAt;

  ChatMsg({
    required this.auteur,
    required this.contenu,
    this.urgence = false,
    this.erreur = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get fromPatient => auteur == 'PATIENT';

  factory ChatMsg.fromJson(Map<String, dynamic> j) => ChatMsg(
    auteur: (j['auteur'] ?? 'ASSISTANT') as String,
    contenu: (j['contenu'] ?? '') as String,
    urgence: j['urgence'] == true,
    createdAt: j['createdAt'] == null
        ? null
        : DateTime.tryParse(j['createdAt'] as String),
  );
}
