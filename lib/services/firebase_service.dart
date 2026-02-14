import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/journal_entry.dart';
import '../models/stats_model.dart';
import '../models/supporter_model.dart';

/// Central Firestore service for all database operations.
class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Collection references ─────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _db.collection('users');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _usersCol.doc(uid);

  CollectionReference<Map<String, dynamic>> _journalCol(String uid) =>
      _userDoc(uid).collection('journal');

  CollectionReference<Map<String, dynamic>> _nudgesCol(String uid) =>
      _userDoc(uid).collection('nudges');

  // ─── User CRUD ─────────────────────────────────────────────────

  /// Create a new user document with a unique support code.
  Future<void> createUser(UserModel user) async {
    await _userDoc(user.uid).set(user.toMap());
  }

  /// Get user by UID.
  Future<UserModel?> getUser(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  /// Stream user document for real-time updates.
  Stream<UserModel?> streamUser(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Update user fields.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _userDoc(uid).update(data);
  }

  /// Generate a unique 6-digit support code (BF-XXXX format).
  Future<String> generateSupportCode() async {
    final random = Random();
    String code;
    bool exists;

    do {
      final number = random.nextInt(9000) + 1000; // 1000-9999
      code = 'BF-$number';
      final query =
          await _usersCol.where('support_code', isEqualTo: code).limit(1).get();
      exists = query.docs.isNotEmpty;
    } while (exists);

    return code;
  }

  /// Find user by support code for invitation.
  Future<UserModel?> findUserBySupportCode(String code) async {
    final query = await _usersCol
        .where('support_code', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return UserModel.fromMap(doc.data(), doc.id);
  }

  // ─── Circle / Supporter Operations ────────────────────────────

  /// Add a supporter to a user's circle.
  Future<void> addSupporter(String userUid, String supporterUid) async {
    final batch = _db.batch();

    // Add supporter to user's list
    batch.update(_userDoc(userUid), {
      'supporters': FieldValue.arrayUnion([supporterUid]),
    });

    // Add user to supporter's "supporting" list
    batch.update(_userDoc(supporterUid), {
      'supporting': FieldValue.arrayUnion([userUid]),
    });

    await batch.commit();
  }

  /// Remove a supporter from the circle.
  Future<void> removeSupporter(String userUid, String supporterUid) async {
    final batch = _db.batch();

    batch.update(_userDoc(userUid), {
      'supporters': FieldValue.arrayRemove([supporterUid]),
    });

    batch.update(_userDoc(supporterUid), {
      'supporting': FieldValue.arrayRemove([userUid]),
    });

    await batch.commit();
  }

  /// Get list of supporter models for a user.
  Future<List<SupporterModel>> getSupporters(String userUid) async {
    final user = await getUser(userUid);
    if (user == null) return [];

    final supporters = <SupporterModel>[];
    for (final uid in user.supporterUids) {
      final doc = await _userDoc(uid).get();
      if (doc.exists && doc.data() != null) {
        supporters.add(SupporterModel.fromMap(doc.data()!, doc.id));
      }
    }
    return supporters;
  }

  /// Get list of users this person is supporting.
  Future<List<UserModel>> getSupportedUsers(String supporterUid) async {
    final user = await getUser(supporterUid);
    if (user == null) return [];

    final supported = <UserModel>[];
    for (final uid in user.supportingUids) {
      final doc = await _userDoc(uid).get();
      if (doc.exists && doc.data() != null) {
        supported.add(UserModel.fromMap(doc.data()!, doc.id));
      }
    }
    return supported;
  }

  // ─── Journal Operations ────────────────────────────────────────

  /// Add a journal entry.
  Future<String> addJournalEntry(String uid, JournalEntry entry) async {
    final docRef = await _journalCol(uid).add(entry.toMap());

    // Update stats based on event type
    if (entry.eventType == JournalEventType.relapse) {
      await _handleRelapse(uid, entry);
    } else if (entry.wasResisted) {
      await _handleCravingResisted(uid);
    }

    return docRef.id;
  }

  /// Stream journal entries in reverse chronological order.
  Stream<List<JournalEntry>> streamJournal(String uid) {
    return _journalCol(uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => JournalEntry.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get recent journal entries (limited).
  Future<List<JournalEntry>> getRecentJournal(String uid,
      {int limit = 20}) async {
    final snap = await _journalCol(uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snap.docs
        .map((doc) => JournalEntry.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Handle relapse: reset streak, log last smoke timestamp.
  Future<void> _handleRelapse(String uid, JournalEntry entry) async {
    await updateUser(uid, {
      'stats.last_smoke_timestamp': Timestamp.fromDate(entry.timestamp),
      'stats.streak_days': 0,
    });
  }

  /// Handle craving resisted: increment counters.
  Future<void> _handleCravingResisted(String uid) async {
    await updateUser(uid, {
      'stats.cravings_blocked': FieldValue.increment(1),
      'stats.total_cravings_resisted': FieldValue.increment(1),
    });
  }

  // ─── Stats Operations ─────────────────────────────────────────

  /// Update user stats.
  Future<void> updateStats(String uid, UserStats stats) async {
    await updateUser(uid, {'stats': stats.toMap()});
  }

  /// Increment intervention usage.
  Future<void> recordInterventionUsed(
      String uid, String interventionName) async {
    await updateUser(uid, {
      'stats.total_interventions_used': FieldValue.increment(1),
      'stats.intervention_breakdown.$interventionName': FieldValue.increment(1),
    });
  }

  /// Update health recovery percentage.
  Future<void> updateHealthRecovery(String uid, double percentage) async {
    await updateUser(uid, {
      'stats.health_recovery_percentage': percentage,
    });
  }

  // ─── Nudges ───────────────────────────────────────────────────

  /// Send a nudge (strength message) to a user.
  Future<void> sendNudge(String toUid, NudgeMessage nudge) async {
    await _nudgesCol(toUid).add(nudge.toMap());
  }

  /// Stream nudges for a user.
  Stream<List<NudgeMessage>> streamNudges(String uid) {
    return _nudgesCol(uid)
        .orderBy('sent_at', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => NudgeMessage.fromMap(doc.data())).toList());
  }

  // ─── Privacy ──────────────────────────────────────────────────

  /// Update privacy settings.
  Future<void> updatePrivacySettings(
      String uid, PrivacySettings settings) async {
    await updateUser(uid, {'privacy_settings': settings.toMap()});
  }

  // ─── FCM Token ────────────────────────────────────────────────

  /// Update FCM token for push notifications.
  Future<void> updateFcmToken(String uid, String token) async {
    await updateUser(uid, {'fcm_token': token});
  }
}
