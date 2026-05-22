import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import '../utils/logger.dart';

const _metaBox = 'meta';
const _usersBox = 'users';

final _seededTrainer = User(
  id: 'tr_aarav',
  role: UserRole.trainer,
  name: 'Aarav',
  email: 'aarav@wtf.local',
);

final _seededMember = User(
  id: 'mb_dk',
  role: UserRole.member,
  name: 'DK',
  email: 'dk@wtf.local',
  assignedTrainerId: 'tr_aarav',
);

class AuthService {
  static Future<void> init() async {
    await Hive.openBox<dynamic>(_metaBox);
    await Hive.openBox<Map>(_usersBox);
    await _seedIfNeeded();
  }

  static Future<void> _seedIfNeeded() async {
    final meta = Hive.box<dynamic>(_metaBox);
    if (meta.get('hasSeeded', defaultValue: false) as bool) return;

    final users = Hive.box<Map>(_usersBox);
    await users.put('tr_aarav', _seededTrainer.toJson());
    await users.put('mb_dk', _seededMember.toJson());
    await meta.put('hasSeeded', true);
    Log.auth('seeded tr_aarav + mb_dk');
  }

  static Future<User?> login(String email, String password) async {
    final users = Hive.box<Map>(_usersBox);
    for (final key in users.keys) {
      final raw = users.get(key);
      if (raw == null) continue;
      final user = User.fromJson(Map<String, dynamic>.from(raw));
      if (user.email.toLowerCase() == email.trim().toLowerCase()) {
        final meta = Hive.box<dynamic>(_metaBox);
        await meta.put('currentUserId', user.id);
        Log.auth('login success: ${user.id}');
        return user;
      }
    }
    Log.auth('login failed for $email');
    return null;
  }

  static User? currentUser() {
    final meta = Hive.box<dynamic>(_metaBox);
    final id = meta.get('currentUserId') as String?;
    if (id == null) return null;
    final users = Hive.box<Map>(_usersBox);
    final raw = users.get(id);
    if (raw == null) return null;
    return User.fromJson(Map<String, dynamic>.from(raw));
  }

  static Future<void> logout() async {
    final meta = Hive.box<dynamic>(_metaBox);
    await meta.delete('currentUserId');
    Log.auth('logout');
  }

  static Future<void> setOnboarded(bool value) async {
    final meta = Hive.box<dynamic>(_metaBox);
    await meta.put('hasOnboarded', value);
  }

  static bool hasOnboarded() {
    final meta = Hive.box<dynamic>(_metaBox);
    return meta.get('hasOnboarded', defaultValue: false) as bool;
  }

  static User get seededTrainer => _seededTrainer;
  static User get seededMember => _seededMember;
}
