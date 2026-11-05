import 'package:shared_preferences/shared_preferences.dart';

/// URL du backend. Émulateur Android : 10.0.2.2 = ton PC.
/// Téléphone réel : flutter run --dart-define=API_URL=http://192.168.1.20:8080
const String kBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://192.168.1.14:8080',
);

/// Adresse du serveur modifiable depuis l'app (appui long sur le logo de l'écran d'accueil).
class ServerConfig {
  static String baseUrl = kBaseUrl;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString('api_url');
    if (saved != null && saved.isNotEmpty) baseUrl = saved;
  }

  static String normalize(String raw) {
    var u = raw.trim();
    if (u.isEmpty) return kBaseUrl;
    if (!u.startsWith('http://') && !u.startsWith('https://')) u = 'http://$u';
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  static Future<void> save(String raw) async {
    baseUrl = normalize(raw);
    final p = await SharedPreferences.getInstance();
    await p.setString('api_url', baseUrl);
  }

  static Future<void> reset() async {
    baseUrl = kBaseUrl;
    final p = await SharedPreferences.getInstance();
    await p.remove('api_url');
  }
}

const String kSamuNumber = '1515';

const List<String> kRegions = [
  'Dakar',
  'Thiès',
  'Diourbel',
  'Saint-Louis',
  'Kaolack',
  'Fatick',
  'Kaffrine',
  'Kolda',
  'Louga',
  'Matam',
  'Sédhiou',
  'Tambacounda',
  'Kédougou',
  'Ziguinchor',
];
