import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import '../models/dictionary_entry.dart';
import '../models/geo_recording.dart';
import '../models/lesson.dart';
import '../models/lesson_task.dart';
import '../models/admin_models.dart';
import 'package:lumad_lingua/models/gallery_models.dart';
import 'package:lumad_lingua/models/artifact.dart';
import '../models/srs_models.dart';
import '../models/voice_submission.dart';
import '../models/contributor_request.dart';
import '../models/quest.dart';
import '../models/community_activity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../models/gamification_models.dart';
import '../models/app_config.dart';
import '../models/scenario_models.dart';
import '../models/broadcast.dart';
import '../models/feedback.dart';
import '../models/assessment.dart';
import 'offline_service.dart';

import '../models/daily_challenge.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  FirebaseFirestore get db => _db;

  // --- Village Code & Educator Linking ---

  Future<String> generateUniqueVillageCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Avoid ambiguous chars O, 0, I, 1
    final rnd = math.Random();
    
    while (true) {
      final code = String.fromCharCodes(
        Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
      );

      // Check if code exists
      final snap = await _db
          .collection('users')
          .where('villageCode', isEqualTo: code)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return code;
    }
  }

  Future<void> joinVillage(String userId, String code) async {
    final educatorSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'educator')
        .where('villageCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();

    if (educatorSnap.docs.isEmpty) {
      throw Exception("Village code not found. Please check with your educator.");
    }

    final educatorId = educatorSnap.docs.first.id;

    await _db.collection('users').doc(userId).update({
      'educatorId': educatorId,
    });

    // Notify educator
    final userDoc = await _db.collection('users').doc(userId).get();
    final userName = userDoc.data()?['username'] ?? 'A new learner';

    await addNotification(educatorId, {
      'title': 'New Learner Joined! 🌿',
      'message': '$userName has joined your village.',
      'type': 'broadcast',
    });
  }

  // User Profile Operations
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('users').doc(userId).update(data);
  }

  // Dictionary Streams
  Stream<List<DictionaryEntry>> getValidatedDictionaryWords() {
    return _db
        .collection('words')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => DictionaryEntry.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<String>> getDialects() {
    return _db.collection('config').doc('languages').snapshots().map((doc) {
      final defaultDialects = [
        'Mansaka',
      ];

      if (!doc.exists || doc.data() == null) {
        return ["All", ...defaultDialects];
      }
      final list = List<String>.from(doc.data()!['list'] ?? []);
      if (list.isEmpty) return ["All", ...defaultDialects];

      if (!list.contains("All")) list.insert(0, "All");
      return list;
    });
  }

  Stream<AppConfig> getAppConfig() {
    return _db.collection('config').doc('app').snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return AppConfig.fromFirestore({});
      }
      return AppConfig.fromFirestore(doc.data()!);
    });
  }

  Stream<List<DictionaryEntry>> getPendingDictionaryWords({
    int limit = 50,
    String? search,
    String? dialect,
  }) {
    // Only filter by status on server to avoid composite index requirement
    return _db
        .collection('words')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      var docs = snapshot.docs
          .map((doc) => DictionaryEntry.fromFirestore(
              doc.data(), doc.id))
          .toList();

      // Filter by dialect client-side
      if (dialect != null && dialect != 'All' && dialect.isNotEmpty) {
        docs = docs.where((d) => d.language == dialect).toList();
      }

      // Filter by search client-side
      if (search != null && search.isNotEmpty) {
        final query = search.toLowerCase();
        docs = docs.where((d) {
          return d.indigenousWord.toLowerCase().contains(query) ||
              d.translation.toLowerCase().contains(query);
        }).toList();
      }

      // Sort client-side
      docs.sort((a, b) => b.id.compareTo(a.id));

      return docs.take(limit).toList();
    });
  }

  Stream<List<DictionaryEntry>> getGlobalDictionaryWords({
    int limit = 50,
    String? search,
    String? dialect,
  }) {
    Query query = _db.collection('words');

    if (dialect != null && dialect != 'All' && dialect.isNotEmpty) {
      query = query.where('dialect', isEqualTo: dialect);
    }

    if (search != null && search.isNotEmpty) {
      final queryTerm = search.toLowerCase();
      query = query
          .where('term_lowercase', isGreaterThanOrEqualTo: queryTerm)
          .where('term_lowercase', isLessThanOrEqualTo: '$queryTerm\uf8ff');
    }

    return query.limit(limit).snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => DictionaryEntry.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    });
  }


  Stream<List<DictionaryEntry>> getValidatorHistory(
    String validatorId, {
    int limit = 50,
    String? search,
    String? dialect,
  }) {
    // Single server filter
    return _db
        .collection('words')
        .where('validatorId', isEqualTo: validatorId)
        .snapshots()
        .map((snapshot) {
      var docs = snapshot.docs
          .map((doc) => DictionaryEntry.fromFirestore(
              doc.data(), doc.id))
          .toList();

      // Client filter
      if (dialect != null && dialect != 'All' && dialect.isNotEmpty) {
        docs = docs.where((d) => d.language == dialect).toList();
      }

      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        docs = docs.where((d) => d.indigenousWord.toLowerCase().contains(q)).toList();
      }

      // Sort client-side
      docs.sort((a, b) {
        if (a.validatedAt == null) return 1;
        if (b.validatedAt == null) return -1;
        return b.validatedAt!.compareTo(a.validatedAt!);
      });

      return docs.take(limit).toList();
    });
  }

  Stream<List<DictionaryEntry>> getUserContributions(String userId) {
    return _db
        .collection('words')
        .where('contributorId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => DictionaryEntry.fromFirestore(doc.data(), doc.id))
              .toList();

          // Sort client-side to avoid the need for a composite index
          docs.sort((a, b) {
            final t1 = a.validatedAt;
            // Note: Since DictionaryEntry might not have createdAt, we use validatedAt or a fallback
            if (t1 == null) return 1;
            final t2 = b.validatedAt;
            if (t2 == null) return -1;
            return t2.compareTo(t1);
          });

          return docs;
        });
  }

  Stream<List<VoiceSubmission>> getUserVoiceSubmissions(String userId) {
    return _db
        .collection('voice_submissions')
        .where('contributorId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => VoiceSubmission.fromFirestore(doc.data(), doc.id))
              .toList();

          // Sort client-side to avoid the need for a composite index
          docs.sort((a, b) {
            final t1 = a.submittedAt;
            final t2 = b.submittedAt;
            if (t1 == null) return 1;
            if (t2 == null) return -1;
            return t2.compareTo(t1);
          });

          return docs;
    });
  }

  Stream<List<Artifact>> getUserArtifacts(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('artifacts')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Artifact.fromFirestore(doc.data(), doc.id))
              .toList();

          // Sort by tier index (descending) then by earned date
          list.sort((a, b) {
            final tierCompare = b.tier.index.compareTo(a.tier.index);
            if (tierCompare != 0) return tierCompare;

            final dateA = a.earnedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final dateB = b.earnedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return dateB.compareTo(dateA);
          });

          return list;
        });
  }

  Future<void> updateArtifactProgress(
    String userId,
    String artifactId,
    int progress, {
    bool isEarned = false,
  }) async {
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('artifacts')
        .doc(artifactId);

    final updates = {
      'currentProgress': progress,
      if (isEarned) 'isEarned': true,
      if (isEarned) 'earnedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(updates, SetOptions(merge: true));
  }

  Stream<List<DictionaryEntry>> getAllDictionaryWords() {
    return _db.collection('words').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => DictionaryEntry.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<DictionaryEntry>> getDictionaryWordsByStatus(String status) {
    return _db
        .collection('words')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => DictionaryEntry.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<VoiceSubmission>> getAllVoiceSubmissions() {
    return _db.collection('voice_submissions').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => VoiceSubmission.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> approveWord(
    String id,
    String validatorId,
    String validatorRole,
  ) async {
    return _db.runTransaction((transaction) async {
      final docRef = _db.collection('words').doc(id);
      final doc = await transaction.get(docRef);
      final data = doc.data();
      if (data == null || data['status'] == 'approved') {
        return;
      }

      // READS MUST COME BEFORE WRITES IN TRANSACTIONS
      final configDoc = await transaction.get(_db.collection('config').doc('app'));
      final config = AppConfig.fromFirestore(configDoc.data() ?? {});

      final validatorRef = _db.collection('users').doc(validatorId);
      final validatorDoc = await transaction.get(validatorRef);
      final validatorName = validatorDoc.data()?['username'] ?? 'Validator';

      _saveVersionTransaction(transaction, docRef, data, validatorId);

      _logAuditTransaction(
        transaction,
        action: 'APPROVED',
        actorId: validatorId,
        actorName: validatorName,
        targetId: id,
        targetName: data['term'] ?? 'Unknown Word',
        targetType: 'word',
        icon: '🌿',
      );

      transaction.update(docRef, {
        'status': 'approved',
        'isValidated': true,
        'validatorId': validatorId,
        'validatorRole': validatorRole,
        'validatedAt': FieldValue.serverTimestamp(),
      });

      final contributorId = data['contributorId'];
      final term = data['term'] ?? 'your entry';

      if (contributorId != null) {
        final contributorRef = _db.collection('users').doc(contributorId);
        final contributorDoc = await transaction.get(contributorRef);
        final cData = contributorDoc.data();

        // Add Notification using Template
        final notifRef = _db
            .collection('users')
            .doc(contributorId)
            .collection('notifications')
            .doc();
            
        final title = config.notifications['word_approved_title'] ?? 'Entry Approved! 🌟';
        final message = config.formatNotification('word_approved_body', {
          'term': term,
          'role': validatorRole,
        });

        transaction.set(notifRef, {
          'title': title,
          'message': message,
          'type': 'approval',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        // Award XP from Config
        transaction.update(contributorRef, {
          'xp': FieldValue.increment(config.wordApprovalXp),
          'wordCount': FieldValue.increment(1),
        });

        // Community Feed: New Term
        final feedRef = _db.collection('community_feed').doc();
        transaction.set(feedRef, {
          'userId': contributorId,
          'userName': cData?['username'] ?? data['contributorName'] ?? 'A tribe member',
          'userPhotoUrl': cData?['photoURL'],
          'type': 'contribution',
          'message': 'added a new ${data['dialect'] ?? ''} term: "$term"!',
          'emoji': '🌿',
          'likeCount': 0,
          'commentCount': 0,
          'likedBy': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> flagWord(
    String id,
    String validatorId,
    String validatorRole,
    String feedback, {
    String? audioTipUrl,
  }) async {
    return _db.runTransaction((transaction) async {
      final docRef = _db.collection('words').doc(id);
      final doc = await transaction.get(docRef);
      final data = doc.data();
      if (data == null) return;

      final validatorRef = _db.collection('users').doc(validatorId);
      final validatorDoc = await transaction.get(validatorRef);
      final validatorName = validatorDoc.data()?['username'] ?? 'Validator';

      _saveVersionTransaction(transaction, docRef, data, validatorId);

      _logAuditTransaction(
        transaction,
        action: 'FLAGGED',
        actorId: validatorId,
        actorName: validatorName,
        targetId: id,
        targetName: data['term'] ?? data['indigenousWord'] ?? 'Unknown Word',
        targetType: 'word',
        icon: '🚩',
      );

      transaction.update(docRef, {
        'status': 'flagged',
        'isValidated': false,
        'validatorId': validatorId,
        'validatorRole': validatorRole,
        'validatorFeedback': feedback,
        'validatorAudioTipUrl': audioTipUrl,
        'flaggedAt': FieldValue.serverTimestamp(),
        'validatedAt': FieldValue.serverTimestamp(),
      });

      final contributorId = data['contributorId'];
      final term = data['term'] ?? 'your entry';

      if (contributorId != null) {
        final notifRef = _db
            .collection('users')
            .doc(contributorId)
            .collection('notifications')
            .doc();
        transaction.set(notifRef, {
          'title': 'Clarification Needed 📝',
          'message':
              'A $validatorRole has requested more info for "$term": $feedback',
          'type': 'flagged',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    });
  }

  Future<void> rejectWord(
    String id,
    String validatorId,
    String validatorRole,
    String feedback, {
    String? audioTipUrl,
  }) async {
    return _db.runTransaction((transaction) async {
      final docRef = _db.collection('words').doc(id);
      final doc = await transaction.get(docRef);
      final data = doc.data();
      if (data == null) return;

      final validatorRef = _db.collection('users').doc(validatorId);
      final validatorDoc = await transaction.get(validatorRef);
      final validatorName = validatorDoc.data()?['username'] ?? 'Validator';

      _saveVersionTransaction(transaction, docRef, data, validatorId);

      _logAuditTransaction(
        transaction,
        action: 'REJECTED',
        actorId: validatorId,
        actorName: validatorName,
        targetId: id,
        targetName: data['term'] ?? data['indigenousWord'] ?? 'Unknown Word',
        targetType: 'word',
        icon: '🚫',
      );

      transaction.update(docRef, {
        'status': 'rejected',
        'isValidated': false,
        'validatorId': validatorId,
        'validatorRole': validatorRole,
        'validatorFeedback': feedback,
        'validatorAudioTipUrl': audioTipUrl,
        'rejectedAt': FieldValue.serverTimestamp(),
        'validatedAt': FieldValue.serverTimestamp(),
      });

      final contributorId = data['contributorId'];
      final term = data['term'] ?? 'your entry';

      if (contributorId != null) {
        final notifRef = _db
            .collection('users')
            .doc(contributorId)
            .collection('notifications')
            .doc();
        transaction.set(notifRef, {
          'title': 'Entry Rejected ⚠️',
          'message': 'Your entry "$term" was not approved: $feedback',
          'type': 'rejection',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    });
  }

  // Geo Record Stream (Municipalities mapping to Local Voices)
  Stream<List<GeoRecording>> getMunicipalities() {
    return _db.collection('municipalities').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => GeoRecording.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // CRUD Operations for Municipalities
  Future<void> addMunicipality(Map<String, dynamic> data) async {
    await _db.collection('municipalities').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMunicipality(String id, Map<String, dynamic> data) async {
    await _db.collection('municipalities').doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Re-scans all approved recordings and updates municipality metadata
  Future<void> syncMunicipalityDialects() async {
    final muniSnaps = await _db.collection('municipalities').get();

    for (var muniDoc in muniSnaps.docs) {
      final recordingsSnap = await muniDoc.reference
          .collection('recordings')
          .where('status', isEqualTo: 'approved')
          .get();

      final Set<String> dialects = {};

      // Also include the primary dialect
      final primary = muniDoc.data()['dialect'];
      if (primary != null && primary != 'Lumad' && primary != 'lumad') {
        dialects.add(primary);
      }

      for (var recDoc in recordingsSnap.docs) {
        final d = recDoc.data()['dialect'];
        if (d != null) dialects.add(d);
      }

      if (dialects.isNotEmpty) {
        await muniDoc.reference.update({
          'supportedDialects': dialects.toList(),
        });
      }
    }
  }

  Future<void> deleteMunicipality(String id) async {
    await _db.collection('municipalities').doc(id).delete();
  }

  // CRUD Operations for Dictionary
  Future<void> addWord(DictionaryEntry entry) async {
    await _db.collection('words').add({
      ...entry.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateWord(String id, Map<String, dynamic> data) async {
    await _db.collection('words').doc(id).update(data);
  }

  Future<void> deleteWord(String id) async {
    await _db.collection('words').doc(id).delete();
  }

  Future<void> bulkAddWords(List<DictionaryEntry> entries) async {
    final batch = _db.batch();
    for (var entry in entries) {
      final docRef = _db.collection('words').doc();
      batch.set(docRef, {
        ...entry.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> bulkApproveWords(List<String> ids, String validatorId, String validatorRole) async {
    return _db.runTransaction((transaction) async {
      final configDoc = await transaction.get(_db.collection('config').doc('app'));
      final config = AppConfig.fromFirestore(configDoc.data() ?? {});

      final validatorRef = _db.collection('users').doc(validatorId);
      final validatorDoc = await transaction.get(validatorRef);
      final validatorName = validatorDoc.data()?['username'] ?? 'Validator';

      for (var id in ids) {
        final docRef = _db.collection('words').doc(id);
        final doc = await transaction.get(docRef);
        final data = doc.data();
        if (data == null || data['status'] == 'approved') continue;

        _saveVersionTransaction(transaction, docRef, data, validatorId);

        _logAuditTransaction(
          transaction,
          action: 'APPROVED (BULK)',
          actorId: validatorId,
          actorName: validatorName,
          targetId: id,
          targetName: data['term'] ?? 'Unknown Word',
          targetType: 'word',
          icon: '✨',
        );

        transaction.update(docRef, {
          'status': 'approved',
          'isValidated': true,
          'validatorId': validatorId,
          'validatorRole': validatorRole,
          'validatedAt': FieldValue.serverTimestamp(),
        });

        final contributorId = data['contributorId'];
        final term = data['term'] ?? 'your entry';

        if (contributorId != null) {
          final notifRef = _db.collection('users').doc(contributorId).collection('notifications').doc();
          transaction.set(notifRef, {
            'title': config.notifications['word_approved_title'] ?? 'Entry Approved! 🌟',
            'message': config.formatNotification('word_approved_body', {'term': term, 'role': validatorRole}),
            'type': 'approval',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });

          transaction.update(_db.collection('users').doc(contributorId), {
            'xp': FieldValue.increment(config.wordApprovalXp),
            'wordCount': FieldValue.increment(1),
          });
        }
      }
    });
  }

  Future<void> bulkRejectWords(List<String> ids, String validatorId, String validatorRole, String feedback) async {
    return _db.runTransaction((transaction) async {
      final validatorRef = _db.collection('users').doc(validatorId);
      final validatorDoc = await transaction.get(validatorRef);
      final validatorName = validatorDoc.data()?['username'] ?? 'Validator';

      for (var id in ids) {
        final docRef = _db.collection('words').doc(id);
        final doc = await transaction.get(docRef);
        final data = doc.data();
        if (data == null) continue;

        _saveVersionTransaction(transaction, docRef, data, validatorId);

        _logAuditTransaction(
          transaction,
          action: 'REJECTED (BULK)',
          actorId: validatorId,
          actorName: validatorName,
          targetId: id,
          targetName: data['term'] ?? data['indigenousWord'] ?? 'Unknown Word',
          targetType: 'word',
          icon: '🚫',
        );

        transaction.update(docRef, {
          'status': 'rejected',
          'isValidated': false,
          'validatorId': validatorId,
          'validatorRole': validatorRole,
          'validatorFeedback': feedback,
          'validatorAudioTipUrl': null,
          'rejectedAt': FieldValue.serverTimestamp(),
          'validatedAt': FieldValue.serverTimestamp(),
        });

        final contributorId = data['contributorId'];
        final term = data['term'] ?? 'your entry';

        if (contributorId != null) {
          final notifRef = _db.collection('users').doc(contributorId).collection('notifications').doc();
          transaction.set(notifRef, {
            'title': 'Entry Rejected (Bulk) ⚠️',
            'message': 'Your entry "$term" was not approved: $feedback',
            'type': 'rejection',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }
    });
  }

  Future<void> bulkFlagWords(List<String> ids, String validatorId, String validatorRole, String feedback) async {
    return _db.runTransaction((transaction) async {
      final validatorRef = _db.collection('users').doc(validatorId);
      final validatorDoc = await transaction.get(validatorRef);
      final validatorName = validatorDoc.data()?['username'] ?? 'Validator';

      for (var id in ids) {
        final docRef = _db.collection('words').doc(id);
        final doc = await transaction.get(docRef);
        final data = doc.data();
        if (data == null) continue;

        _saveVersionTransaction(transaction, docRef, data, validatorId);

        _logAuditTransaction(
          transaction,
          action: 'FLAGGED (BULK)',
          actorId: validatorId,
          actorName: validatorName,
          targetId: id,
          targetName: data['term'] ?? data['indigenousWord'] ?? 'Unknown Word',
          targetType: 'word',
          icon: '🚩',
        );

        transaction.update(docRef, {
          'status': 'flagged',
          'isValidated': false,
          'validatorId': validatorId,
          'validatorRole': validatorRole,
          'validatorFeedback': feedback,
          'validatorAudioTipUrl': null,
          'flaggedAt': FieldValue.serverTimestamp(),
          'validatedAt': FieldValue.serverTimestamp(),
        });

        final contributorId = data['contributorId'];
        final term = data['term'] ?? 'your entry';

        if (contributorId != null) {
          final notifRef = _db.collection('users').doc(contributorId).collection('notifications').doc();
          transaction.set(notifRef, {
            'title': 'Clarification Needed (Bulk) 📝',
            'message': 'A $validatorRole has requested more info for "$term": $feedback',
            'type': 'flagged',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }
    });
  }

  Future<void> bulkDeleteWords(List<String> ids) async {
    final batch = _db.batch();
    for (var id in ids) {
      batch.delete(_db.collection('words').doc(id));
    }
    await batch.commit();
  }

  // Bookmark Operations
  Future<void> toggleBookmark(String userId, String wordId) async {
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(wordId);
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.delete();
    } else {
      await docRef.set({'timestamp': FieldValue.serverTimestamp()});
    }
  }

  Stream<List<String>> getBookmarks(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.id).toList();
        });
  }

  // Notification Operations
  Stream<List<Map<String, dynamic>>> getNotifications(String userId, {int? limit}) {
    var query = _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }

    return query
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        });
  }

  Future<void> addNotification(
    String userId,
    Map<String, dynamic> notification,
  ) async {
    await _db.collection('users').doc(userId).collection('notifications').add({
      ...notification,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  /// Sends a notification to multiple users using WriteBatch for scalability.
  Future<void> broadcastNotification(
    List<String> userIds,
    Map<String, dynamic> notification,
  ) async {
    // Firestore batches are limited to 500 operations.
    const int batchSize = 450;
    for (var i = 0; i < userIds.length; i += batchSize) {
      final batch = _db.batch();
      final end = (i + batchSize < userIds.length)
          ? i + batchSize
          : userIds.length;
      final chunk = userIds.sublist(i, end);

      for (var userId in chunk) {
        final notifRef = _db
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc();
        batch.set(notifRef, {
          ...notification,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
      await batch.commit();
    }
  }

  Future<void> markNotificationAsRead(
    String userId,
    String notificationId,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    if (snap.docs.isEmpty) return;

    final batch = _db.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Village Broadcast Operations ──────────────────────────────────────────

  Future<void> sendVillageBroadcast({
    required String educatorId,
    required String educatorName,
    required String title,
    required String message,
    required List<String> studentIds,
  }) async {
    // 1. Save the broadcast globally for history
    final broadcastRef = _db.collection('broadcasts').doc();
    final broadcast = VillageBroadcast(
      id: broadcastRef.id,
      educatorId: educatorId,
      educatorName: educatorName,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      recipients: studentIds,
    );
    await broadcastRef.set(broadcast.toFirestore());

    // 2. Send notifications to all students
    await broadcastNotification(studentIds, {
      'title': title,
      'message': message,
      'type': 'broadcast',
      'senderId': educatorId,
      'senderName': educatorName,
      'broadcastId': broadcastRef.id,
    });
  }

  Stream<List<VillageBroadcast>> getVillageBroadcasts() {
    return _db
        .collection('broadcasts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => VillageBroadcast.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateVillageBroadcast(String id, String message) async {
    await _db.collection('broadcasts').doc(id).update({
      'message': message,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteVillageBroadcast(String id) async {
    await _db.collection('broadcasts').doc(id).delete();
  }

  // ── Student Feedback Operations ───────────────────────────────────────────

  Future<void> submitStudentFeedback({
    required String studentId,
    required String studentName,
    String? studentPhotoUrl,
    required String message,
  }) async {
    await _db.collection('feedback').add({
      'studentId': studentId,
      'studentName': studentName,
      'studentPhotoUrl': studentPhotoUrl,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Stream<List<StudentFeedback>> getStudentFeedback() {
    return _db
        .collection('feedback')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => StudentFeedback.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> markFeedbackAsRead(String feedbackId) async {
    await _db.collection('feedback').doc(feedbackId).update({'isRead': true});
  }

  Future<void> replyToFeedback(String feedbackId, String reply) async {
    await _db.collection('feedback').doc(feedbackId).update({
      'educatorReply': reply,
      'repliedAt': FieldValue.serverTimestamp(),
      'isRead': true,
    });
  }

  Stream<int> getUnreadFeedbackCount() {
    return _db
        .collection('feedback')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size);
  }

  // Gamification Operations
  Future<void> addXp(String userId, int xpToAdd) async {
    final docRef = _db.collection('users').doc(userId);
    await docRef.update({'xp': FieldValue.increment(xpToAdd)});
  }

  // SRS Operations
  Stream<List<SRSProgress>> getSRSProgress(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('srs_progress')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SRSProgress.fromFirestore(doc.data()))
              .toList();
        });
  }

  Future<void> updateSRSProgress(String userId, SRSProgress progress) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('srs_progress')
        .doc(progress.wordId)
        .set(progress.toFirestore());
  }

  // --- Daily Challenge Operations ---

  Future<DailyChallenge?> getDailyChallenge(String dateId) async {
    final doc = await _db.collection('daily_challenges').doc(dateId).get();
    if (doc.exists) {
      return DailyChallenge.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> saveDailyChallenge(DailyChallenge challenge) async {
    await _db
        .collection('daily_challenges')
        .doc(challenge.id)
        .set(challenge.toFirestore());
  }

  Future<void> completeDailyChallenge(
    String userId,
    String dateId,
    int xp,
    int crystals,
  ) async {
    final userRef = _db.collection('users').doc(userId);

    await _db.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) return;

      final data = userSnap.data()!;
      final completedChallenges = List<String>.from(data['completedChallenges'] ?? []);

      if (!completedChallenges.contains(dateId)) {
        completedChallenges.add(dateId);

        // Update XP, Crystals, and Streak
        int currentStreak = data['streak'] ?? 0;
        String? lastStreakDate = data['lastStreakDate'];

        DateTime now = DateTime.now();
        String today = dateId; // YYYY-MM-DD

        if (lastStreakDate == null) {
          currentStreak = 1;
        } else {
          DateTime lastDate = DateTime.parse(lastStreakDate);
          DateTime yesterday = now.subtract(const Duration(days: 1));

          if (lastDate.year == yesterday.year &&
              lastDate.month == yesterday.month &&
              lastDate.day == yesterday.day) {
            currentStreak += 1;
          } else if (lastDate.year == now.year &&
              lastDate.month == now.month &&
              lastDate.day == now.day) {
            // Already updated today, don't increment streak again but we record completion
          } else {
            currentStreak = 1;
          }
        }

        transaction.update(userRef, {
          'xp': FieldValue.increment(xp),
          'mistCrystals': FieldValue.increment(crystals),
          'streak': currentStreak,
          'lastStreakDate': today,
          'completedChallenges': completedChallenges,
        });
      }
    });
  }

  Future<List<LessonTask>> getRandomTasks(int count, {String? language}) async {
    Query query = _db.collection('lessons').where('status', isEqualTo: 'PUBLISHED');
    if (language != null) {
      query = query.where('language', isEqualTo: language);
    }

    final lessonsSnap = await query.get();
    if (lessonsSnap.docs.isEmpty) return [];

    final allTasks = <LessonTask>[];
    for (var doc in lessonsSnap.docs) {
      final lesson = Lesson.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      allTasks.addAll(lesson.tasks);
    }

    if (allTasks.isEmpty) return [];

    allTasks.shuffle();
    return allTasks.take(math.min(count, allTasks.length)).toList();
  }

  // Community Recording Operations
  Future<DocumentReference> addRecording(
    String municipalityId,
    Map<String, dynamic> recordingData,
  ) async {
    return await _db
        .collection('municipalities')
        .doc(municipalityId)
        .collection('recordings')
        .add({...recordingData, 'timestamp': FieldValue.serverTimestamp()});
  }

  Future<void> addVoiceSubmission(VoiceSubmission submission) async {
    await _db.collection('voice_submissions').add({
      ...submission.toFirestore(),
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getRecordingsForMunicipality(
    String municipalityId,
  ) {
    return _db
        .collection('municipalities')
        .doc(municipalityId)
        .collection('recordings')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();

          // Sort client-side to avoid the need for a composite index
          docs.sort((a, b) {
            DateTime? parseTime(dynamic t) {
              if (t is Timestamp) return t.toDate();
              if (t is String) return DateTime.tryParse(t);
              return null;
            }

            final t1 = parseTime(a['timestamp']);
            final t2 = parseTime(b['timestamp']);

            if (t1 == null && t2 == null) return 0;
            if (t1 == null) return 1;
            if (t2 == null) return -1;
            return t2.compareTo(t1);
          });

          return docs;
        });
  }

  // Gamification & Economics Operations
  Stream<List<LearningSeason>> getSeasons() {
    return _db.collection('seasons').orderBy('startDate', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => LearningSeason.fromFirestore(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addSeason(LearningSeason season) async {
    await _db.collection('seasons').add(season.toFirestore());
  }

  Future<void> updateSeason(String id, Map<String, dynamic> data) async {
    await _db.collection('seasons').doc(id).update(data);
  }

  Future<void> deleteSeason(String id) async {
    await _db.collection('seasons').doc(id).delete();
  }

  Stream<List<ShopItem>> getShopItems() {
    return _db.collection('shop_items').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ShopItem.fromFirestore(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addShopItem(ShopItem item) async {
    await _db.collection('shop_items').add(item.toFirestore());
  }

  Future<void> updateShopItem(String id, Map<String, dynamic> data) async {
    await _db.collection('shop_items').doc(id).update(data);
  }

  Stream<List<Map<String, dynamic>>> getLinguaDuels() {
    return _db.collection('lingua_duels').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  Future<void> resolveDuelDispute(String duelId, String resolution) async {
    await _db.collection('lingua_duels').doc(duelId).update({
      'status': 'resolved',
      'moderatorResolution': resolution,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> getAdvancedPedagogicalAnalytics() async {
    try {
      final progressSnap = await _db.collectionGroup('progress').get();
      final srsSnap = await _db.collectionGroup('srs_progress').get();
      final lessonsSnap = await _db.collection('lessons').get();

      // 1. Lesson Heatmaps
      final Map<String, Map<String, int>> lessonStruggles = {};
      final Map<String, String> lessonNames = {};
      for (var doc in lessonsSnap.docs) {
        lessonNames[doc.id] = doc.data()['title'] ?? 'Unknown';
      }

      for (var doc in progressSnap.docs) {
        final lessonId = doc.id;
        final performance = doc.data()['performance'] as Map<String, dynamic>? ?? {};
        if (!lessonStruggles.containsKey(lessonId)) {
          lessonStruggles[lessonId] = {};
        }
        performance.forEach((taskId, mistakes) {
          lessonStruggles[lessonId]![taskId] = (lessonStruggles[lessonId]![taskId] ?? 0) + (mistakes as num).toInt();
        });
      }

      // 2. Dialect Distribution (by active learners)
      final Map<String, Set<String>> dialectUsers = {};
      for (var doc in lessonsSnap.docs) {
        final lang = doc.data()['language'] ?? 'Lumad';
        if (!dialectUsers.containsKey(lang)) dialectUsers[lang] = {};
      }

      for (var doc in progressSnap.docs) {
        final lessonId = doc.id;
        final userId = doc.reference.parent.parent?.id;
        if (userId != null && lessonsSnap.docs.isNotEmpty) {
          final lessonDoc = lessonsSnap.docs.firstWhere(
            (d) => d.id == lessonId,
            orElse: () => lessonsSnap.docs.first,
          );
          final lang = lessonDoc.data()['language'] ?? 'Lumad';
          if (!dialectUsers.containsKey(lang)) dialectUsers[lang] = {};
          dialectUsers[lang]!.add(userId);
        }
      }

      // 3. SRS Health
      int totalReviews = 0;
      int totalSuccess = 0;
      final Map<int, int> masteryDist = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (var doc in srsSnap.docs) {
        final data = doc.data();
        final reviews = data['timesReviewed'] as int? ?? 0;
        final level = data['level'] as int? ?? 0;
        totalReviews += reviews;
        // Approximation: success = total - failures (if we had failure count)
        // Or using consecutiveCorrect as a health indicator
        totalSuccess += data['consecutiveCorrect'] as int? ?? 0;
        masteryDist[level] = (masteryDist[level] ?? 0) + 1;
      }

      return {
        'lessonStruggles': lessonStruggles,
        'lessonNames': lessonNames,
        'dialectPopularity': dialectUsers.map((k, v) => MapEntry(k, v.length)),
        'srsHealth': {
          'retentionRate': totalReviews > 0 ? (totalSuccess / (totalReviews + totalSuccess)) : 0.0,
          'masteryDistribution': masteryDist,
          'totalCards': srsSnap.size,
        }
      };
    } catch (e, stack) {
      debugPrint('Advanced Analytics Error: $e');
      debugPrint(stack.toString());
      return {
        'lessonStruggles': <String, Map<String, int>>{},
        'lessonNames': <String, String>{},
        'dialectPopularity': <String, int>{},
        'srsHealth': {
          'retentionRate': 0.0,
          'masteryDistribution': {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
          'totalCards': 0,
        }
      };
    }
  }

  // User Management
  Stream<List<AdminUser>> getAllUsers() {
    return _db.collection('users').snapshots().map((snap) {
      return snap.docs
          .map((doc) => AdminUser.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getUsersPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query =
        _db.collection('users').orderBy('createdAt', descending: true).limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.get();
  }

  Future<void> updateUserRole(
    String userId,
    String newRole, {
    String? indigenousGroup,
  }) async {
    final Map<String, dynamic> updates = {'role': newRole};
    if (indigenousGroup != null) {
      updates['indigenousGroup'] = indigenousGroup;
    }
    await _db.collection('users').doc(userId).update(updates);
  }

  Future<void> updateUserDetails(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update(data);
  }

  Future<void> updatePrivacySettings(String userId, {bool? isPublic, bool? shareAnalytics}) async {
    final Map<String, dynamic> updates = {};
    if (isPublic != null) updates['isPublicProfile'] = isPublic;
    if (shareAnalytics != null) updates['shareAnalytics'] = shareAnalytics;
    
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(userId).update(updates);
    }
  }

  Future<Map<String, dynamic>> exportUserData(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    final wordsSnap = await _db.collection('words').where('contributorId', isEqualTo: userId).get();
    final voiceSnap = await _db.collection('voice_submissions').where('contributorId', isEqualTo: userId).get();
    
    return {
      'profile': userDoc.data(),
      'contributed_words': wordsSnap.docs.map((d) => d.data()).toList(),
      'voice_submissions': voiceSnap.docs.map((d) => d.data()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> createInvitation(String email, String role, {String? indigenousGroup}) async {
    await _db.collection('invitations').add({
      'email': email,
      'role': role,
      'indigenousGroup': indigenousGroup,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Contributor Request Operations
  Future<void> submitContributorRequest(
    String userId,
    String username,
    String email, {
    String? message,
  }) async {
    await _db.collection('contributor_requests').add({
      'userId': userId,
      'username': username,
      'userEmail': email,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'message': message,
    });
  }

  Future<void> cancelContributorRequest(String requestId) async {
    await _db.collection('contributor_requests').doc(requestId).delete();
  }

  Stream<List<ContributorRequest>> getContributorRequests() {
    return _db
        .collection('contributor_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => ContributorRequest.fromFirestore(doc.data(), doc.id),
              )
              .toList();
        });
  }

  Stream<int> getPendingContributorRequestsCount() {
    return _db
        .collection('contributor_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<ContributorRequest?> getPendingContributorRequest(String userId) {
    return _db
        .collection('contributor_requests')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return ContributorRequest.fromFirestore(
            snapshot.docs.first.data(),
            snapshot.docs.first.id,
          );
        });
  }

  Future<void> updateContributorRequestStatus(
    String requestId,
    String userId,
    String status,
  ) async {
    return _db.runTransaction((transaction) async {
      final requestRef = _db.collection('contributor_requests').doc(requestId);
      transaction.update(requestRef, {
        'status': status,
        'processedAt': FieldValue.serverTimestamp(),
      });

      if (status == 'approved') {
        final userRef = _db.collection('users').doc(userId);
        transaction.update(userRef, {'role': 'contributor'});

        // Notify User
        final notifRef = _db
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc();
        transaction.set(notifRef, {
          'title': 'Welcome to the Tribe! 🌿',
          'message':
              'Your request to become a Contributor has been approved. You now have access to expansion tools!',
          'type': 'approval',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      } else if (status == 'rejected') {
        // Notify User
        final notifRef = _db
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc();
        transaction.set(notifRef, {
          'title': 'Contributor Request Update',
          'message':
              'Your request to become a Contributor was not approved at this time. Keep learning and try again later!',
          'type': 'rejection',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    });
  }

  // System Health & Analytics
  Stream<Map<String, dynamic>> getSystemHealth() {
    // In a real app, this might come from a Cloud Function that monitors infrastructure
    // or a dedicated 'health' document updated by a cron job.
    return _db.collection('system').doc('health').snapshots().map((doc) {
      if (!doc.exists) {
        return {
          'apiStatus': 'Online',
          'storage': '75%',
          'database': 'Healthy',
          'uptime': '99.9%',
        };
      }
      return doc.data()!;
    });
  }

  Stream<Map<String, List<int>>> getPlatformActivityStats() {
    return Rx.combineLatest2(
      _db.collection('users').orderBy('createdAt').snapshots(),
      _db.collection('words').orderBy('createdAt').snapshots(),
      (userSnap, wordSnap) {
        final now = DateTime.now();
        final last7Days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
        
        List<int> growth = List.filled(7, 0);
        List<int> contributions = List.filled(7, 0);

        for (var doc in userSnap.docs) {
          final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
          if (createdAt != null) {
            for (int i = 0; i < 7; i++) {
              if (createdAt.year == last7Days[i].year &&
                  createdAt.month == last7Days[i].month &&
                  createdAt.day == last7Days[i].day) {
                growth[i]++;
              }
            }
          }
        }

        for (var doc in wordSnap.docs) {
          final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
          if (createdAt != null) {
            for (int i = 0; i < 7; i++) {
              if (createdAt.year == last7Days[i].year &&
                  createdAt.month == last7Days[i].month &&
                  createdAt.day == last7Days[i].day) {
                contributions[i]++;
              }
            }
          }
        }

        return {
          'growth': growth,
          'contributions': contributions,
        };
      },
    );
  }

  Future<void> recordMasteryStat(String userId, int masteredCount) async {
    final dateKey = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    await _db
        .collection('users')
        .doc(userId)
        .collection('mastery_history')
        .doc(dateKey)
        .set({
      'count': masteredCount,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<double>> getMasteryHistoryStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('mastery_history')
        .orderBy('timestamp', descending: true)
        .limit(7)
        .snapshots()
        .map((snap) {
      // Create a map for quick lookup
      final Map<String, double> historyMap = {};
      for (var doc in snap.docs) {
        historyMap[doc.id] = (doc.data()['count'] as num?)?.toDouble() ?? 0.0;
      }

      // Generate last 7 days including today
      final now = DateTime.now();
      final List<double> result = [];
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = date.toIso8601String().split('T')[0];

        // If we don't have a log for a specific day, we take the previous day's value
        // to maintain the cumulative feel, or 0.0 if it's the very first log.
        if (historyMap.containsKey(dateKey)) {
          result.add(historyMap[dateKey]!);
        } else {
          // Find the most recent previous value
          double fallback = 0.0;
          for (var entry in snap.docs) {
             if (entry.id.compareTo(dateKey) < 0) {
               fallback = (entry.data()['count'] as num?)?.toDouble() ?? 0.0;
               break;
             }
          }
          result.add(fallback);
        }
      }
      return result;
    });
  }

  // System Settings / Dialect Toggles
  Stream<Map<String, bool>> getDialectSettings() {
    return _db.collection('system_configs').doc('dialects').snapshots().map((doc) {
      if (!doc.exists) {
        return {
          'Mansaka': true,
          'Mandaya': true,
          'Manobo': true,
          'Bagobo': true,
          'Kagan': false,
        };
      }
      return Map<String, bool>.from(doc.data()!);
    });
  }

  Future<void> updateDialectSettings(Map<String, bool> settings) async {
    await _db.collection('system_configs').doc('dialects').set(settings);
  }

  Future<void> updateUserStatus(
    String userId,
    String status,
    String? reason,
  ) async {
    await _db.collection('users').doc(userId).update({
      'status': status,
      'suspensionReason': reason,
    });
  }

  // Leaderboard Operations
  Stream<List<Map<String, dynamic>>> getLeaderboardLearners() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'learner')
        .orderBy('xp', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> getVillageLeaderboard(String educatorId) {
    return _db
        .collection('users')
        .where('educatorId', isEqualTo: educatorId)
        .where('role', isEqualTo: 'learner')
        .orderBy('xp', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> getLeaderboardContributors() {
    // Show anyone with contributions, regardless of role
    // Using wordCount > 0 ensures we only see active contributors
    return _db
        .collection('users')
        .where('wordCount', isGreaterThan: 0)
        .orderBy('wordCount', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList());
  }

  // Learning Hub Operations
  Future<void> approveLesson(
    String id,
    String validatorId,
    String validatorRole,
  ) async {
    return _db.runTransaction((transaction) async {
      final docRef = _db.collection('lessons').doc(id);
      final doc = await transaction.get(docRef);
      final data = doc.data();
      if (data == null || data['status'] == 'PUBLISHED') return;

      // READS MUST COME BEFORE WRITES IN TRANSACTIONS
      final configDoc = await transaction.get(_db.collection('config').doc('app'));
      final config = AppConfig.fromFirestore(configDoc.data() ?? {});

      final validatorRef = _db.collection('users').doc(validatorId);
      final validatorDoc = await transaction.get(validatorRef);
      final validatorName = validatorDoc.data()?['username'] ?? 'Validator';

      _saveVersionTransaction(transaction, docRef, data, validatorId);

      _logAuditTransaction(
        transaction,
        action: 'APPROVED',
        actorId: validatorId,
        actorName: validatorName,
        targetId: id,
        targetName: data['term'] ?? 'Unknown Word',
        targetType: 'word',
        icon: '🌿',
      );

      transaction.update(docRef, {
        'status': 'PUBLISHED',
        'isValidated': true,
        'validatorId': validatorId,
        'validatorRole': validatorRole,
        'validatedAt': FieldValue.serverTimestamp(),
      });

      final contributorId = data['contributorId'];
      final title = data['title'] ?? 'your lesson';

      if (contributorId != null) {
        // Notify Contributor using Template
        final notifRef = _db
            .collection('users')
            .doc(contributorId)
            .collection('notifications')
            .doc();
            
        final notifTitle = config.notifications['lesson_approved_title'] ?? 'Curriculum Approved! 📚';
        final notifMessage = config.formatNotification('lesson_approved_body', {
          'title': title,
        });

        transaction.set(notifRef, {
          'title': notifTitle,
          'message': notifMessage,
          'type': 'approval',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        // Award XP from Config
        final userRef = _db.collection('users').doc(contributorId);
        transaction.update(userRef, {
          'xp': FieldValue.increment(config.lessonApprovalXp),
          'lessonCount': FieldValue.increment(1),
        });
      }
    });
  }

  Future<void> flagLesson(
    String id,
    String validatorId,
    String validatorRole,
    String feedback,
  ) async {
    return _db.runTransaction((transaction) async {
      final docRef = _db.collection('lessons').doc(id);
      final doc = await transaction.get(docRef);
      final data = doc.data();
      if (data == null) return;

      final validatorRef = _db.collection('users').doc(validatorId);
      final validatorDoc = await transaction.get(validatorRef);
      final validatorName = validatorDoc.data()?['username'] ?? 'Validator';

      _saveVersionTransaction(transaction, docRef, data, validatorId);

      _logAuditTransaction(
        transaction,
        action: 'FLAGGED',
        actorId: validatorId,
        actorName: validatorName,
        targetId: id,
        targetName: data['title'] ?? 'Unknown Lesson',
        targetType: 'lesson',
        icon: '🚩',
      );

      transaction.update(docRef, {
        'status': 'FLAGGED',
        'isValidated': false,
        'validatorId': validatorId,
        'validatorRole': validatorRole,
        'validatorFeedback': feedback,
        'flaggedAt': FieldValue.serverTimestamp(),
        'validatedAt': FieldValue.serverTimestamp(),
      });

      final contributorId = data['contributorId'];
      if (contributorId != null) {
        final notifRef = _db.collection('users').doc(contributorId).collection('notifications').doc();
        transaction.set(notifRef, {
          'title': 'Lesson Feedback 📝',
          'message': 'A $validatorRole suggested changes for "${data['title']}": $feedback',
          'type': 'flagged',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    });
  }

  /// Rejects a pending lesson, recording the decision and notifying its contributor.
  Future<void> rejectLesson(
    String id,
    String validatorId,
    String validatorRole,
    String feedback,
  ) async {
    final rejectionFeedback = feedback.trim();
    if (rejectionFeedback.isEmpty) {
      throw ArgumentError.value(
        feedback,
        'feedback',
        'Rejection feedback cannot be empty.',
      );
    }

    return _db.runTransaction((transaction) async {
      final docRef = _db.collection('lessons').doc(id);
      final doc = await transaction.get(docRef);
      final data = doc.data();
      if (data == null || data['status'] != 'PENDING_REVIEW') return;

      final validatorRef = _db.collection('users').doc(validatorId);
      final validatorDoc = await transaction.get(validatorRef);
      final validatorName = validatorDoc.data()?['username'] ?? 'Validator';

      _saveVersionTransaction(transaction, docRef, data, validatorId);
      _logAuditTransaction(
        transaction,
        action: 'REJECTED',
        actorId: validatorId,
        actorName: validatorName,
        targetId: id,
        targetName: data['title'] ?? 'Unknown Lesson',
        targetType: 'lesson',
        icon: '🚫',
        metadata: {'feedback': rejectionFeedback},
      );

      transaction.update(docRef, {
        'status': 'REJECTED',
        'isValidated': false,
        'validatorId': validatorId,
        'validatorRole': validatorRole,
        'validatorFeedback': rejectionFeedback,
        'rejectionFeedback': rejectionFeedback,
        'rejectedAt': FieldValue.serverTimestamp(),
        'validatedAt': FieldValue.serverTimestamp(),
      });

      final contributorId = data['contributorId'];
      final title = data['title'] ?? 'your lesson';
      if (contributorId != null) {
        final notifRef = _db
            .collection('users')
            .doc(contributorId)
            .collection('notifications')
            .doc();
        transaction.set(notifRef, {
          'title': 'Lesson Rejected ⚠️',
          'message': 'Your lesson "$title" was not approved: $rejectionFeedback',
          'type': 'rejection',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    });
  }

  Stream<List<Lesson>> getPendingLessons({String? dialect}) {
    return _db
        .collection('lessons')
        .where('status', isEqualTo: 'PENDING_REVIEW')
        .snapshots()
        .map((snapshot) {
      var list = snapshot.docs
          .map((doc) =>
              Lesson.fromFirestore(doc.data(), doc.id))
          .toList();

      if (dialect != null && dialect != 'All' && dialect.isNotEmpty) {
        list = list.where((l) => l.language == dialect).toList();
      }
      return list;
    });
  }

  Stream<List<Lesson>> getValidatorLessonHistory(
    String validatorId, {
    int limit = 50,
  }) {
    return _db
        .collection('lessons')
        .where('validatorId', isEqualTo: validatorId)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Lesson.fromFirestore(doc.data(), doc.id))
              .toList();
          // Client-side sort to avoid index requirements
          list.sort((a, b) {
            final aTime = a.validatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.validatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          return list;
        });
  }

  Stream<List<Lesson>> getPublishedLessons() {
    return _db
        .collection('lessons')
        .where('status', isEqualTo: 'PUBLISHED')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Lesson.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<Lesson>> getAllLessons() {
    return _db.collection('lessons').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Lesson.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<Lesson?> getLessonById(String id) async {
    final doc = await _db.collection('lessons').doc(id).get();
    if (!doc.exists) return null;
    return Lesson.fromFirestore(doc.data()!, doc.id);
  }

  Future<String> saveLesson(
    Lesson lesson, {
    String status = 'PUBLISHED',
  }) async {
    final data = lesson.toFirestore();
    data['status'] = status;
    data['updatedAt'] = FieldValue.serverTimestamp();

    // Check for unit number collision
    final isOccupied = await isUnitUnique(
      lesson.language,
      lesson.unitNumber,
      excludeLessonId: (lesson.id.isNotEmpty && !lesson.id.startsWith('temp_')) ? lesson.id : null,
    ).then((unique) => !unique);

    if (isOccupied) {
      // Shift existing lessons to make room
      await shiftUnitNumbers(
        language: lesson.language,
        startUnit: lesson.unitNumber,
        offset: 1,
      );
    }

    if (lesson.id.isEmpty || lesson.id.startsWith('temp_')) {
      data['createdAt'] = FieldValue.serverTimestamp();
      final docRef = await _db.collection('lessons').add(data);
      return docRef.id;
    } else {
      await _db
          .collection('lessons')
          .doc(lesson.id)
          .set(data, SetOptions(merge: true));
      return lesson.id;
    }
  }

  Future<bool> isUnitUnique(
    String language,
    int unitNumber, {
    String? excludeLessonId,
  }) async {
    final query = _db
        .collection('lessons')
        .where('language', isEqualTo: language)
        .where('unitNumber', isEqualTo: unitNumber);

    final snapshot = await query.get();

    if (excludeLessonId != null) {
      return snapshot.docs.where((doc) => doc.id != excludeLessonId).isEmpty;
    }

    return snapshot.docs.isEmpty;
  }

  Future<void> deleteLesson(String id) async {
    // 1. Get the lesson to find assets
    final lesson = await getLessonById(id);
    if (lesson != null) {
      // 2. Delete assets from Storage
      for (var task in lesson.tasks) {
        if (task.audioUrl != null && task.audioUrl!.isNotEmpty) {
          await deleteFileByUrl(task.audioUrl!);
        }
        if (task.imageUrl != null && task.imageUrl!.isNotEmpty) {
          await deleteFileByUrl(task.imageUrl!);
        }
      }
    }
    // 3. Delete from Firestore
    await _db.collection('lessons').doc(id).delete();
  }

  Future<void> bulkApproveLessons(List<String> ids, String validatorId, String validatorRole) async {
    return _db.runTransaction((transaction) async {
      final configDoc = await transaction.get(_db.collection('config').doc('app'));
      final config = AppConfig.fromFirestore(configDoc.data() ?? {});

      final validatorRef = _db.collection('users').doc(validatorId);
      final validatorDoc = await transaction.get(validatorRef);
      final validatorName = validatorDoc.data()?['username'] ?? 'Validator';

      for (var id in ids) {
        final docRef = _db.collection('lessons').doc(id);
        final doc = await transaction.get(docRef);
        final data = doc.data();
        if (data == null || data['status'] == 'PUBLISHED') continue;

        _saveVersionTransaction(transaction, docRef, data, validatorId);

        _logAuditTransaction(
          transaction,
          action: 'APPROVED (BULK)',
          actorId: validatorId,
          actorName: validatorName,
          targetId: id,
          targetName: data['title'] ?? 'Unknown Lesson',
          targetType: 'lesson',
          icon: '📚',
        );

        transaction.update(docRef, {
          'status': 'PUBLISHED',
          'isValidated': true,
          'validatorId': validatorId,
          'validatorRole': validatorRole,
          'validatedAt': FieldValue.serverTimestamp(),
        });
        
        final contributorId = data['contributorId'];
        if (contributorId != null) {
          final notifRef = _db.collection('users').doc(contributorId).collection('notifications').doc();
          transaction.set(notifRef, {
            'title': 'Lesson Published! 📚',
            'message': 'Your lesson "${data['title']}" is now live.',
            'type': 'approval',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });

          transaction.update(_db.collection('users').doc(contributorId), {
            'xp': FieldValue.increment(config.lessonApprovalXp),
          });
        }
      }
    });
  }

  Future<void> bulkDeleteLessons(List<String> ids) async {
    // Note: This doesn't delete assets from storage for simplicity in bulk
    final batch = _db.batch();
    for (var id in ids) {
      batch.delete(_db.collection('lessons').doc(id));
    }
    await batch.commit();
  }

  Future<void> deleteFileByUrl(String url) async {
    try {
      if (url.contains('supabase.co')) {
        // Supabase URL
        // Format: https://[PROJECT].supabase.co/storage/v1/object/public/[BUCKET]/[PATH]
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 5) {
          final bucket = pathSegments[4];
          final path = pathSegments.sublist(5).join('/');
          // Using direct Supabase client since we are in a singleton/service context
          await Supabase.instance.client.storage.from(bucket).remove([path]);
          debugPrint('Successfully deleted Supabase file: $path from $bucket');
        }
      } else {
        // Firebase URL
        final ref = _storage.refFromURL(url);
        await ref.delete();
        debugPrint('Successfully deleted Firebase file: $url');
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  /// Reorders units by shifting all units from [startUnit] onwards by [offset]
  Future<void> shiftUnitNumbers({
    required String language,
    required int startUnit,
    int offset = 1,
  }) async {
    final query = _db
        .collection('lessons')
        .where('language', isEqualTo: language)
        .where('unitNumber', isGreaterThanOrEqualTo: startUnit);

    final snapshot = await query.get();

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'unitNumber': FieldValue.increment(offset)});
    }
    await batch.commit();
  }

  Stream<Map<String, dynamic>> getUserProgress(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('progress')
        .snapshots()
        .map((snapshot) {
          final progress = <String, dynamic>{};
          for (var doc in snapshot.docs) {
            progress[doc.id] = doc.data();
          }
          return progress;
        });
  }

  Future<Map<String, dynamic>> getEducatorAnalytics(String educatorId) async {
    try {
      // 1. Get learners linked to this educator
      final usersSnap = await _db
          .collection('users')
          .where('educatorId', isEqualTo: educatorId)
          .where('role', isEqualTo: 'learner')
          .get();

      final List<String> studentIds = usersSnap.docs.map((doc) => doc.id).toList();

      if (studentIds.isEmpty) {
        return {
          'totalXP': 0,
          'avgLessonsCompleted': 0.0,
          'pronunciationAccuracy': 0.0,
          'quizPerformance': <Map<String, dynamic>>[],
          'commonHurdles': <Map<String, dynamic>>[],
        };
      }

      final lessonsSnap = await _db.collection('lessons').get();
      final Map<String, String> lessonNames = {};
      final Map<String, List<Map<String, dynamic>>> lessonTasks = {};

      for (var doc in lessonsSnap.docs) {
        lessonNames[doc.id] = doc.data()['title'] as String? ?? 'Unknown Lesson';
        lessonTasks[doc.id] = List<Map<String, dynamic>>.from(
          doc.data()['tasks'] ?? [],
        );
      }

      int totalXP = 0;
      int totalLessonsCompleted = 0;
      double totalAccuracySum = 0;
      int accuracyCount = 0;

      final Map<String, int> lessonAttempts = {};
      final Map<String, int> lessonPasses = {};
      final Map<String, int> taskMistakesCount = {};
      final Map<String, String> taskToLesson = {};

      for (var userDoc in usersSnap.docs) {
        final userData = userDoc.data();
        totalXP += (userData['xp'] as num?)?.toInt() ?? 0;

        final progressSnap = await userDoc.reference.collection('progress').get();
        for (var progDoc in progressSnap.docs) {
          final data = progDoc.data();
          final lessonId = progDoc.id;
          final completed = data['completed'] == true;

          if (completed) totalLessonsCompleted++;

          lessonAttempts[lessonId] = (lessonAttempts[lessonId] ?? 0) + 1;
          if (completed) {
            lessonPasses[lessonId] = (lessonPasses[lessonId] ?? 0) + 1;
          }

          final performance = data['performance'] as Map<String, dynamic>? ?? {};
          performance.forEach((taskId, mistakes) {
            final mistakesInt = (mistakes as num?)?.toInt() ?? 0;
            taskMistakesCount[taskId] = (taskMistakesCount[taskId] ?? 0) + mistakesInt;
            taskToLesson[taskId] = lessonId;

            totalAccuracySum += (1.0 - (mistakesInt / 5.0)).clamp(0.0, 1.0);
            accuracyCount++;
          });
        }
      }

      final List<Map<String, dynamic>> quizPerformance = [];
      lessonAttempts.forEach((lessonId, attempts) {
        if (attempts > 0) {
          final passes = lessonPasses[lessonId] ?? 0;
          final passRate = ((passes / attempts) * 100).round();
          quizPerformance.add({
            'name': lessonNames[lessonId] ?? 'Lesson',
            'pass': passRate,
            'fail': 100 - passRate,
          });
        }
      });

      final List<Map<String, dynamic>> hurdles = [];
      final sortedTasks = taskMistakesCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (var entry in sortedTasks.take(3)) {
        final taskId = entry.key;
        final mistakes = entry.value;
        final lessonId = taskToLesson[taskId] ?? '';

        String topic = 'Activity Task';
        if (lessonTasks.containsKey(lessonId)) {
          final task = lessonTasks[lessonId]!.firstWhere(
            (t) => t['id'] == taskId,
            orElse: () => <String, dynamic>{},
          );
          if (task.isNotEmpty) {
            final type = task['type'] ?? '';
            topic = '${type.toString().split('.').last.toUpperCase()} TASK';
          }
        }

        hurdles.add({
          'topic': topic,
          'stat': '$mistakes slips identified',
          'lessonName': lessonNames[lessonId] ?? 'Ancestral Path',
        });
      }

      return {
        'totalXP': totalXP,
        'avgLessonsCompleted': totalLessonsCompleted / studentIds.length,
        'pronunciationAccuracy': accuracyCount > 0 ? totalAccuracySum / accuracyCount : 0.85,
        'quizPerformance': quizPerformance,
        'commonHurdles': hurdles,
      };
    } catch (e) {
      debugPrint('Analytics Scoping Error: $e');
      return {
        'quizPerformance': <Map<String, dynamic>>[],
        'commonHurdles': <Map<String, dynamic>>[],
        'totalXP': 0,
        'avgLessonsCompleted': 0.0,
        'pronunciationAccuracy': 0.0,
      };
    }
  }

  Future<void> updateAppConfig(Map<String, dynamic> data) async {
    await _db.collection('config').doc('app').update(data);
  }

  Future<void> completeScenario(String userId, String scenarioId, int xpReward) async {
    final userRef = _db.collection('users').doc(userId);
    final progressRef = _db
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(scenarioId);

    await _db.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      final progressDoc = await transaction.get(progressRef);
      final isNew = !(progressDoc.data()?['completed'] == true);

      transaction.set(progressRef, {
        'completed': true,
        'lastCompleted': FieldValue.serverTimestamp(),
        'bestScore': 100, // Scenarios are pass/fail for now
      }, SetOptions(merge: true));

      transaction.update(userRef, {
        'xp': FieldValue.increment(xpReward),
      });

      if (isNew) {
        final feedRef = _db.collection('community_feed').doc();
        transaction.set(feedRef, {
          'userId': userId,
          'userName': userDoc.data()?['username'] ?? 'A tribe member',
          'userPhotoUrl': userDoc.data()?['photoURL'],
          'type': 'contribution',
          'message': 'survived the "$scenarioId" cultural scenario!',
          'emoji': '🔥',
          'likeCount': 0,
          'commentCount': 0,
          'likedBy': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<Map<String, dynamic>> completeLesson(
    String userId,
    String lessonId,
    int score,
    int stars, {
    Map<String, int>? taskPerformance,
    int bonusXp = 0,
  }) async {
    // Fetch lesson details outside the transaction for efficiency
    final lesson = await getLessonById(lessonId);
    
    // Fetch config for dynamic XP
    final configDoc = await _db.collection('config').doc('app').get();
    final config = AppConfig.fromFirestore(configDoc.data() ?? {});

    // Artifact Gacha Logic (pre-fetch to keep transaction fast)
    Artifact? droppedArtifact;
    if (stars >= 2) {
      final random = math.Random();
      final dropChance = stars == 3
          ? 0.3
          : 0.1; // 30% for 3-stars, 10% for 2-stars
      if (random.nextDouble() <= dropChance) {
        try {
          final artifactsSnap = await _db.collection('artifacts').get();
          if (artifactsSnap.docs.isNotEmpty) {
            final allArtifacts = artifactsSnap.docs
                .map((d) => Artifact.fromFirestore(d.data(), d.id))
                .toList();

            // Weighted random selection based on rarity (lower rarity = rarer drop)
            // rarity is 1-100. We invert it for weighting: rarer items have smaller ranges.
            int totalWeight = allArtifacts.fold(0, (acc, a) => acc + a.rarity);
            int randomWeight = random.nextInt(totalWeight);
            int currentWeight = 0;

            for (var artifact in allArtifacts) {
              currentWeight += artifact.rarity;
              if (randomWeight < currentWeight) {
                droppedArtifact = artifact;
                break;
              }
            }
          }
        } catch (e) {
          debugPrint('Gacha fetch error: $e');
        }
      }
    }

    return _db.runTransaction((transaction) async {
      final userRef = _db.collection('users').doc(userId);
      final progressRef = _db
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(lessonId);

      // PRE-FETCH REFERENCES FOR LATER (To keep READS at the start)
      final badgeRef = _db
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc('perfect_lesson');

      DocumentReference? userArtifactRef;
      final artifact = droppedArtifact;
      if (artifact != null) {
        userArtifactRef = _db
            .collection('users')
            .doc(userId)
            .collection('artifacts')
            .doc(artifact.id);
      }

      // Fetch all necessary data at the START of the transaction (READS)
      final userDoc = await transaction.get(userRef);
      final progressDoc = await transaction.get(progressRef);
      final badgeDoc = await transaction.get(badgeRef);

      DocumentSnapshot? userArtifactDoc;
      if (userArtifactRef != null) {
        userArtifactDoc = await transaction.get(userArtifactRef);
      }

      if (!userDoc.exists) {
        throw Exception("User profile not found. Please log in again.");
      }

      final existingData = progressDoc.data();
      final int currentBestScore = existingData?['bestScore'] as int? ?? 0;
      final int currentStars = existingData?['stars'] as int? ?? 0;

      // Update lesson progress if it's the first completion or a better score
      final Map<String, dynamic> updateData = {
        'completed': true,
        'bestScore': score > currentBestScore ? score : currentBestScore,
        'stars': stars > currentStars ? stars : currentStars,
        'lastAttempt': FieldValue.serverTimestamp(),
      };

      if (taskPerformance != null) {
        // Track analytics: merges existing mistakes with new ones
        final existingPerformance =
            existingData?['performance'] as Map<String, dynamic>? ?? {};
        taskPerformance.forEach((key, value) {
          existingPerformance[key] = (existingPerformance[key] ?? 0) + value;
        });
        updateData['performance'] = existingPerformance;
      }

      // 1. Save Progress
      transaction.set(progressRef, updateData, SetOptions(merge: true));

      // 2. Struggle Point Telemetry
      if (taskPerformance != null) {
        for (var entry in taskPerformance.entries) {
          if (entry.value > 0) {
            final telemetryRef = _db
                .collection('telemetry')
                .doc('struggle_points')
                .collection('points')
                .doc(entry.key);
            transaction.set(telemetryRef, {
              'taskId': entry.key,
              'totalMistakes': FieldValue.increment(entry.value),
              'userImpactCount': FieldValue.increment(1),
              'lastReported': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }
      }

      // 3. Calculate rewards
      int xpReward = 0;

      if (lesson != null) {
        for (var task in lesson.tasks) {
          final mistakes = taskPerformance?[task.id] ?? 0;
          if (mistakes == 0) {
            xpReward += config.lessonTaskPerfectXp;
          } else {
            xpReward += config.lessonTaskRetryXp;
          }
        }
      } else {
        xpReward = score * 2;
      }

      xpReward += config.lessonCompletionBaseXp + bonusXp;

      int crystalReward;
      if (lesson?.isMistUnit ?? false) {
        crystalReward = 30;
      } else {
        crystalReward = stars == 3 ? 50 : (stars == 2 ? 25 : 15);
      }

      // 4. Atomic reward update
      transaction.update(userRef, {
        'mistCrystals': FieldValue.increment(crystalReward),
        'xp': FieldValue.increment(xpReward),
      });

      // Vocabulary Mastery Logic
      if (lesson != null && stars >= 2) {
        for (var task in lesson.tasks) {
          if (task.type == TaskType.vocabulary) {
            final mistakes = taskPerformance?[task.id] ?? 0;
            final wordId = task.nativeWord;
            if (wordId.isNotEmpty) {
              final masterRef = _db
                  .collection('users')
                  .doc(userId)
                  .collection('mastery')
                  .doc(wordId);

              if (mistakes == 0) {
                transaction.set(masterRef, {
                  'word': wordId,
                  'masteryLevel': FieldValue.increment(1),
                  'lastSeen': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
              } else {
                transaction.set(masterRef, {
                  'lastSeen': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
              }
            }
          }
        }
      }

      bool unlockedBadge = false;
      if (stars == 3) {
        if (!badgeDoc.exists) {
          unlockedBadge = true;
          transaction.set(badgeRef, {
            'id': 'perfect_lesson',
            'title': 'Perfect Scholar',
            'description': 'Completed a lesson with 3 stars.',
            'iconName': 'star',
            'colorHex': '#FFD700',
            'earnedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Grant Dropped Artifact (if any)
      if (droppedArtifact != null && userArtifactRef != null && userArtifactDoc != null) {
        if (!userArtifactDoc.exists) {
          final artifactData = droppedArtifact!.toFirestore();
          artifactData['isEarned'] = true;
          artifactData['earnedAt'] = FieldValue.serverTimestamp();
          transaction.set(userArtifactRef, artifactData);

          // Community Feed: Artifact Unlocked
          final feedRef = _db.collection('community_feed').doc();
          transaction.set(feedRef, {
            'userId': userId,
            'userName': userDoc.data()?['username'] ?? 'A tribe member',
            'userPhotoUrl': userDoc.data()?['photoURL'],
            'type': 'achievement',
            'message': 'discovered the "${droppedArtifact?.title}" artifact!',
            'emoji': '🏺',
            'likeCount': 0,
            'commentCount': 0,
            'likedBy': [],
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // User already has this artifact, grant 25 crystals instead
          droppedArtifact = null;
          transaction.update(userRef, {
            'mistCrystals': FieldValue.increment(25),
          });
        }
      }

      // Community Feed: Lesson Completion (only if new best stars)
      if (stars >= 2 && (existingData?['stars'] ?? 0) < stars) {
        final feedRef = _db.collection('community_feed').doc();
        transaction.set(feedRef, {
          'userId': userId,
          'userName': userDoc.data()?['username'] ?? 'A tribe member',
          'userPhotoUrl': userDoc.data()?['photoURL'],
          'type': 'lesson_completed',
          'message': stars == 3
              ? 'perfected "${lesson?.title ?? 'a lesson'}"!'
              : 'completed "${lesson?.title ?? 'a lesson'}"!',
          'emoji': stars == 3 ? '🌟' : '📚',
          'likeCount': 0,
          'commentCount': 0,
          'likedBy': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return {
        'unlockedBadge': unlockedBadge,
        'droppedArtifact': droppedArtifact,
        'xpEarned': xpReward,
        'crystalsEarned': crystalReward,
      };
    });
  }

  Future<void> addMistCrystals(String userId, int amount) async {
    await _db.collection('users').doc(userId).update({
      'mistCrystals': FieldValue.increment(amount),
    });
  }

  Future<void> spendMistCrystals(String userId, int amount) async {
    await _db.collection('users').doc(userId).update({
      'mistCrystals': FieldValue.increment(-amount),
    });
  }

  Future<void> buyStreakShield(String userId) async {
    return _db.runTransaction((transaction) async {
      final userRef = _db.collection('users').doc(userId);
      final userDoc = await transaction.get(userRef);
      final crystals = userDoc.data()?['mistCrystals'] ?? 0;

      if (crystals >= 100) {
        transaction.update(userRef, {
          'mistCrystals': FieldValue.increment(-100),
          'streakShields': FieldValue.increment(1),
        });
      } else {
        throw Exception("Not enough crystals");
      }
    });
  }

  Future<void> updateQuestProgress(
    String userId,
    String questId,
    int progress,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('dailyQuests')
        .doc(questId)
        .update({'current': FieldValue.increment(progress)});
  }

  Future<void> claimQuestReward(
    String userId,
    String questId,
    int reward,
  ) async {
    final userRef = _db.collection('users').doc(userId);
    final questRef = _db
        .collection('users')
        .doc(userId)
        .collection('dailyQuests')
        .doc(questId);

    return _db.runTransaction((transaction) async {
      transaction.update(userRef, {
        'mistCrystals': FieldValue.increment(reward),
      });
      transaction.update(questRef, {'isClaimed': true});
    });
  }

  Stream<List<Quest>> getUserQuests(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('dailyQuests')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Quest.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> purgeLegacyQuests(String userId, Set<String> allowedIds) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('dailyQuests')
        .get();

    final batch = _db.batch();
    bool hasChanges = false;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final isDynamic = data['isDynamic'] == true;
      if (isDynamic && doc.id.startsWith('dyn_')) {
        if (!allowedIds.contains(doc.id)) {
          batch.delete(doc.reference);
          hasChanges = true;
        }
      }
    }

    if (hasChanges) {
      await batch.commit();
    }
  }

  Future<void> addQuest(String userId, Quest quest) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('dailyQuests')
        .doc(quest.id)
        .set(quest.toMap());
  }

  Future<void> deleteQuest(String userId, String questId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('dailyQuests')
        .doc(questId)
        .delete();
  }

  // Assessment Operations
  Future<void> saveAssessmentResult(AssessmentResult result) async {
    await _db.collection('assessments').add(result.toFirestore());
    
    // If it's a pre-test or post-test, we might want to reward the user
    if (result.type == AssessmentType.preTest) {
      await addXp(result.userId, 50); // Small reward for onboarding survey
    } else if (result.type == AssessmentType.postTest) {
      await addXp(result.userId, 100); // Larger reward for milestone post-test
      await addMistCrystals(result.userId, 25);
    }
  }

  Future<void> incrementStreak(String userId) async {
    try {
      final userRef = _db.collection('users').doc(userId);

      return await _db.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          debugPrint("Streak Error: User $userId does not exist.");
          return;
        }

        final data = userDoc.data()!;
        final lastActive = data['lastActive'] as Timestamp?;
        final now = DateTime.now();
        final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        final int currentShields = data['streakShields'] ?? 0;
        final int currentStreak = data['streak'] ?? 0;

        Map<String, dynamic> updates = {
          'lastActive': FieldValue.serverTimestamp(),
          'activityMap.$dateKey': true,
        };

        if (lastActive == null) {
          debugPrint("Streak: First activity for user $userId. Setting streak to 1.");
          updates['streak'] = 1;
        } else {
          final lastDate = lastActive.toDate();
          final difference = DateTime(now.year, now.month, now.day)
              .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
              .inDays;

          if (difference == 0) {
            debugPrint("Streak: Activity already recorded today for $userId.");
          } else if (difference == 1) {
            debugPrint("Streak: Continued streak for $userId. New streak: ${currentStreak + 1}.");
            updates['streak'] = FieldValue.increment(1);

            // Community Feed: Streak Milestone
            final newStreak = currentStreak + 1;
            if (newStreak > 0 && newStreak % 5 == 0) {
              final feedRef = _db.collection('community_feed').doc();
              transaction.set(feedRef, {
                'userId': userId,
                'userName': data['username'] ?? 'A tribe member',
                'userPhotoUrl': data['photoURL'],
                'type': 'streak',
                'message': 'reached a $newStreak-day streak!',
                'emoji': '🔥',
                'likeCount': 0,
                'commentCount': 0,
                'likedBy': [],
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
          } else {
            // Streak broken? Check shields
            if (currentShields > 0) {
              debugPrint("Streak: Saved by shield for $userId. Gaps: $difference days.");
              updates['streakShields'] = FieldValue.increment(-1);
              updates['streak'] = FieldValue.increment(1);
              // Streak preserved and incremented
            } else {
              debugPrint("Streak: Broken for $userId. Resetting to 1. Gaps: $difference days.");
              updates['streak'] = 1;
            }
          }
        }

        transaction.update(userRef, updates);
      });
    } catch (e) {
      debugPrint("Streak Error for $userId: $e");
    }
  }

  // Admin Stats
  Stream<int> getTotalUsersCount() {
    return _db.collection('users').snapshots().map((snap) => snap.size);
  }

  Stream<int> getTotalWordsCount() {
    return _db.collection('words').snapshots().map((snap) => snap.size);
  }

  Stream<int> getPendingWordsCount({String? dialect}) {
    return _db
        .collection('words')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
      if (dialect == null || dialect == 'All' || dialect.isEmpty) {
        return snap.size;
      }
      return snap.docs.where((doc) => doc.data()['dialect'] == dialect).length;
    });
  }

  Stream<int> getTotalAudioClipsCount() {
    return _db
        .collection('words')
        .where('audioUrl', isNotEqualTo: null)
        .snapshots()
        .map((snap) => snap.size);
  }

  Stream<int> getValidatorActivityCount(String userId) {
    return _db
        .collection('words')
        .where('validatorId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.size);
  }

  Stream<Map<String, int>> getValidatorMetrics(String userId) {
    return _db
        .collection('words')
        .where('validatorId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      int approved = 0;
      int flagged = 0;
      int rejected = 0;
      for (var doc in snap.docs) {
        final status = doc.data()['status'];
        if (status == 'approved') {
          approved++;
        } else if (status == 'flagged') {
          flagged++;
        } else if (status == 'rejected') {
          rejected++;
        }
      }
      return {
        'approved': approved,
        'flagged': flagged,
        'rejected': rejected,
      };
    });
  }

  Stream<Map<String, int>> getVoiceValidatorMetrics(String userId) {
    return _db
        .collection('voice_submissions')
        .where('validatorId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      int approved = 0;
      int flagged = 0;
      int rejected = 0;
      for (var doc in snap.docs) {
        final status = doc.data()['status'];
        if (status == 'approved') {
          approved++;
        } else if (status == 'flagged') {
          flagged++;
        } else if (status == 'rejected') {
          rejected++;
        }
      }
      return {
        'approved': approved,
        'flagged': flagged,
        'rejected': rejected,
      };
    });
  }

  Stream<int> getContributorWordCount(String userId) {
    return _db
        .collection('words')
        .where('contributorId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.size);
  }

  Stream<Map<String, dynamic>> getUserImpactMetrics(String userId) {
    // Combine word contributions and user ranking
    final wordsStream = _db
        .collection('words')
        .where('contributorId', isEqualTo: userId)
        .snapshots();
        
    final userDocStream = _db.collection('users').doc(userId).snapshots();
    final allUsersCountStream = _db.collection('users').snapshots();

    return Rx.combineLatest3(
      wordsStream,
      userDocStream,
      allUsersCountStream,
      (QuerySnapshot<Map<String, dynamic>> wordsSnap, DocumentSnapshot<Map<String, dynamic>> userSnap, QuerySnapshot<Map<String, dynamic>> allUsersSnap) {
        final docs = wordsSnap.docs;
        int approved = 0;
        int rejected = 0;
        for (var doc in docs) {
          final data = doc.data();
          final status = data['status'];
          if (status == 'approved') {
            approved++;
          } else if (status == 'rejected') {
            rejected++;
          }
        }

        final totalDecisions = approved + rejected;
        final accuracy = totalDecisions > 0 ? (approved / totalDecisions) : 0.0;
        
        final userXp = userSnap.data()?['xp'] ?? 0;
        final totalUsers = allUsersSnap.size;
        
        // Calculate Rank (Percentile)
        int higherXpCount = 0;
        for (var doc in allUsersSnap.docs) {
          final otherXp = (doc.data() as Map<String, dynamic>?)?['xp'] ?? 0;
          if (otherXp > userXp) higherXpCount++;
        }
        
        final percentile = totalUsers > 0 ? (1.0 - (higherXpCount / totalUsers)) : 0.0;
        
        return {
          'accuracy': accuracy,
          'approvedCount': approved,
          'percentile': percentile,
          'totalSubmissions': docs.length,
          'xp': userXp,
        };
      },
    );
  }

  Future<void> recordActivity(CommunityActivity activity) async {
    await _db.collection('community_feed').add(activity.toFirestore());
  }

  // Gallery Operations
  Stream<List<Artifact>> getArtifacts() {
    return _db.collection('artifacts').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Artifact.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<GalleryBadge>> getEarnedBadges(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .snapshots()
        .asyncMap((snapshot) async {
          final Map<String, Map<String, dynamic>> userAchievementData = {
            for (var doc in snapshot.docs) doc.id: doc.data(),
          };

          // Get all possible badges from the global collection
          final allBadgesSnap = await _db.collection('badges').get();
          return allBadgesSnap.docs.map((doc) {
            final data = userAchievementData[doc.id];
            return GalleryBadge.fromFirestore(
              doc.data(),
              doc.id,
              isEarned: data != null,
            ).copyWith(
              currentCount: data?['currentCount'] ?? 0,
              tier: data?['tier'] ?? 1,
            );
          }).toList();
        });
  }

  Future<void> purchaseArtifact(
    String userId,
    String artifactId,
    int cost,
  ) async {
    return _db.runTransaction((transaction) async {
      final userRef = _db.collection('users').doc(userId);
      final userDoc = await transaction.get(userRef);
      final crystals = userDoc.data()?['mistCrystals'] ?? 0;

      if (crystals < cost) {
        throw Exception("Not enough Mist Crystals!");
      }

      final artifactRef = _db
          .collection('users')
          .doc(userId)
          .collection('artifacts')
          .doc(artifactId);

      // Fetch global artifact for details
      final artifactGlobalDoc = await transaction.get(_db.collection('artifacts').doc(artifactId));
      final artifactName = artifactGlobalDoc.data()?['name'] ?? artifactId;

      transaction.update(userRef, {
        'mistCrystals': FieldValue.increment(-cost),
      });
      transaction.set(artifactRef, {
        'earnedAt': FieldValue.serverTimestamp(),
        'isEarned': true,
        'currentProgress': 1, // Set to 1 if it was a discrete item, or target value
      }, SetOptions(merge: true));

      // Community Feed: Artifact Purchased
      final feedRef = _db.collection('community_feed').doc();
      transaction.set(feedRef, {
        'userId': userId,
        'userName': userDoc.data()?['username'] ?? 'A tribe member',
        'userPhotoUrl': userDoc.data()?['photoURL'],
        'type': 'achievement',
        'message': 'acquired the "$artifactName" from the Mist Store!',
        'emoji': '✨',
        'likeCount': 0,
        'commentCount': 0,
        'likedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> recordAchievementProgress(
    String userId,
    String badgeId, {
    int increment = 1,
  }) async {
    final achievementRef = _db
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .doc(badgeId);

    return _db.runTransaction((transaction) async {
      final userRef = _db.collection('users').doc(userId);
      final userDoc = await transaction.get(userRef);
      final doc = await transaction.get(achievementRef);
      final data = doc.data();
      final currentCount = (data?['currentCount'] ?? 0) + increment;
      final oldTier = data?['tier'] ?? 0;

      // Tier Logic: 10 = Tier I, 50 = Tier II, 100 = Tier III
      int tier = 0;
      if (currentCount >= 100) {
        tier = 3;
      } else if (currentCount >= 50) {
        tier = 2;
      } else if (currentCount >= 10) {
        tier = 1;
      }

      transaction.set(achievementRef, {
        'currentCount': currentCount,
        'tier': tier,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (tier > oldTier) {
        final feedRef = _db.collection('community_feed').doc();
        transaction.set(feedRef, {
          'userId': userId,
          'userName': userDoc.data()?['username'] ?? 'A tribe member',
          'userPhotoUrl': userDoc.data()?['photoURL'],
          'type': 'achievement',
          'message': 'earned the Tier $tier "${badgeId.replaceAll('_', ' ')}" badge!',
          'emoji': '🎖️',
          'likeCount': 0,
          'commentCount': 0,
          'likedBy': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
  // ── Voice Submission Operations ──────────────────────────────────────────

  /// Fetches items that require urgent attention (older than 48 hours  /// Streams pending voice submissions for validators to review.
  Stream<List<VoiceSubmission>> getPendingVoiceSubmissions({
    int limit = 50,
    String? dialect,
  }) {
    // Status only filter
    return _db
        .collection('voice_submissions')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      var list = snapshot.docs
          .map((doc) => VoiceSubmission.fromFirestore(
              doc.data(), doc.id))
          .toList();

      if (dialect != null && dialect != 'All' && dialect.isNotEmpty) {
        list = list.where((v) => v.dialect == dialect).toList();
      }

      list.sort((a, b) {
        final aTime = a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list.take(limit).toList();
    });
  }

  /// Streams voice submissions reviewed by a specific validator.
  Stream<List<VoiceSubmission>> getVoiceValidatorHistory(
    String validatorId, {
    int limit = 50,
  }) {
    return _db
        .collection('voice_submissions')
        .where('validatorId', isEqualTo: validatorId)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => VoiceSubmission.fromFirestore(doc.data(), doc.id))
              .toList();
          // Client-side sort to avoid index requirements
          list.sort((a, b) {
             final aTime = a.validatedAt ?? a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
             final bTime = b.validatedAt ?? b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
             return bTime.compareTo(aTime);
          });
          return list;
        });
  }

  /// Approves a voice submission — awards XP and notifies the contributor.
  Future<void> approveVoiceSubmission(
    String id,
    String validatorId,
    String validatorRole,
  ) async {
    return _db.runTransaction((transaction) async {
      // 1. ALL READS
      final docRef = _db.collection('voice_submissions').doc(id);
      final doc = await transaction.get(docRef);
      final data = doc.data();
      if (data == null) return;

      final configDoc = await transaction.get(_db.collection('config').doc('app'));
      final config = AppConfig.fromFirestore(configDoc.data() ?? {});

      String? municipalityId = data['municipalityId'];
      // Fallback: If IDs are missing or in old format (no province prefix), reconstruct them
      if (data['municipality'] != null && data['province'] != null) {
        final pSlug = data['province'].toString().toLowerCase().replaceAll(' ', '_');
        final mSlug = data['municipality'].toString().toLowerCase().replaceAll(' ', '_');
        final reconstructedId = '${pSlug}_$mSlug';

        // Use reconstructed ID if missing or potentially in old format (no underscore prefix)
        if (municipalityId == null || !municipalityId.startsWith(pSlug)) {
           municipalityId = reconstructedId;
        }
      }

      DocumentSnapshot? muniDoc;
      if (municipalityId != null) {
        muniDoc = await transaction.get(_db.collection('municipalities').doc(municipalityId));
      }

      final contributorId = data['contributorId'];
      DocumentSnapshot? userDoc;
      if (contributorId != null) {
        userDoc = await transaction.get(_db.collection('users').doc(contributorId));
      }

      final validatorRef = _db.collection('users').doc(validatorId);
      final validatorDoc = await transaction.get(validatorRef);
      final validatorName = validatorDoc.data()?['username'] ?? 'Validator';

      _saveVersionTransaction(transaction, docRef, data, validatorId);

      _logAuditTransaction(
        transaction,
        action: 'APPROVED',
        actorId: validatorId,
        actorName: validatorName,
        targetId: id,
        targetName: data['title'] ?? 'Voice Recording',
        targetType: 'voice',
        icon: '🎙️',
      );

      // 2. ALL WRITES
      transaction.update(docRef, {
        'status': 'approved',
        'validatorId': validatorId,
        'validatorRole': validatorRole,
        'validatedAt': FieldValue.serverTimestamp(),
      });

      // Update the actual recording in the municipality sub-collection
      String? recordingId = data['recordingId'];

      if (municipalityId != null) {
        final muniRef = _db.collection('municipalities').doc(municipalityId);
        final recordingsRef = muniRef.collection('recordings');

        if (recordingId != null) {
          transaction.update(recordingsRef.doc(recordingId), {'status': 'approved'});

          // Update supportedDialects in the parent municipality document
          if (muniDoc != null && muniDoc.exists) {
            final muniData = muniDoc.data() as Map<String, dynamic>?;
            final List<String> dialects = List<String>.from(muniData?['supportedDialects'] ?? []);
            final String dialect = data['dialect'] ?? 'Lumad';
            if (!dialects.contains(dialect)) {
              dialects.add(dialect);
              transaction.update(muniRef, {'supportedDialects': dialects});
            }
          }
        }
      }

      if (contributorId != null && userDoc != null && userDoc.exists) {
        final notifRef = _db
            .collection('users')
            .doc(contributorId)
            .collection('notifications')
            .doc();

        final notifTitle = config.notifications['voice_approved_title'] ?? 'Voice Recording Approved! 🎙️';
        final message = config.formatNotification('voice_approved_body', {
          'title': data['title'] ?? 'your recording',
        });

        transaction.set(notifRef, {
          'title': notifTitle,
          'message': message,
          'type': 'approval',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        final userRef = _db.collection('users').doc(contributorId);
        transaction.update(userRef, {
          'xp': FieldValue.increment(config.voiceApprovalXp),
          'voiceCount': FieldValue.increment(1),
        });

        // Community Feed: New Voice
        final feedRef = _db.collection('community_feed').doc();
        transaction.set(feedRef, {
          'userId': contributorId,
          'userName': userDoc.get('username') ?? data['speakerName'] ?? data['contributorName'] ?? 'A tribe member',
          'userPhotoUrl': userDoc.get('photoURL'),
          'type': 'contribution',
          'message': 'shared a new voice recording: "${data['title'] ?? 'untitled'}"!',
          'emoji': '🎤',
          'likeCount': 0,
          'commentCount': 0,
          'likedBy': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> bulkApproveVoiceSubmissions(
    List<String> ids,
    String validatorId,
    String validatorRole,
  ) async {
    return _db.runTransaction((transaction) async {
      // 1. ALL READS
      final configDoc = await transaction.get(_db.collection('config').doc('app'));
      final config = AppConfig.fromFirestore(configDoc.data() ?? {});

      final validatorRef = _db.collection('users').doc(validatorId);
      final validatorDoc = await transaction.get(validatorRef);
      final validatorName = validatorDoc.data()?['username'] ?? 'Validator';

      final List<DocumentSnapshot<Map<String, dynamic>>> submissionSnaps = [];
      for (var id in ids) {
        final snap = await transaction.get(_db.collection('voice_submissions').doc(id));
        if (snap.exists) submissionSnaps.add(snap);
      }

      final Set<String> municipalityIds = {};
      for (var snap in submissionSnaps) {
        final data = snap.data();
        String? mId = data?['municipalityId'];

        // Ensure we handle legacy IDs by checking province + municipality
        if (data?['province'] != null && data?['municipality'] != null) {
          final pSlug = data!['province'].toString().toLowerCase().replaceAll(' ', '_');
          final mSlug = data['municipality'].toString().toLowerCase().replaceAll(' ', '_');
          final reconstructedId = '${pSlug}_$mSlug';

          if (mId == null || !mId.startsWith(pSlug)) {
            mId = reconstructedId;
          }
        }

        if (mId != null) municipalityIds.add(mId);
      }

      final Map<String, List<String>> muniDialects = {};
      for (var mId in municipalityIds) {
        final mSnap = await transaction.get(_db.collection('municipalities').doc(mId));
        if (mSnap.exists) {
          muniDialects[mId] = List<String>.from(mSnap.data()?['supportedDialects'] ?? []);
        } else {
          muniDialects[mId] = [];
        }
      }

      // 2. ALL WRITES
      final Set<String> modifiedMuniIds = {};

      for (var snap in submissionSnaps) {
        final data = snap.data()!;
        final id = snap.id;

        _saveVersionTransaction(transaction, snap.reference, data, validatorId);

        _logAuditTransaction(
          transaction,
          action: 'APPROVED (BULK)',
          actorId: validatorId,
          actorName: validatorName,
          targetId: id,
          targetName: data['title'] ?? 'Voice Recording',
          targetType: 'voice',
          icon: '🎙️',
        );

        transaction.update(snap.reference, {
          'status': 'approved',
          'validatorId': validatorId,
          'validatorRole': validatorRole,
          'validatedAt': FieldValue.serverTimestamp(),
        });

        final String? mIdInDoc = data['municipalityId'];
        String? mId = mIdInDoc;
        final String? rId = data['recordingId'];
        final String? dialect = data['dialect'];
        final String? province = data['province'];
        final String? municipality = data['municipality'];

        if (province != null && municipality != null) {
          final pSlug = province.toLowerCase().replaceAll(' ', '_');
          final mSlug = municipality.toLowerCase().replaceAll(' ', '_');
          final reconstructedId = '${pSlug}_$mSlug';
          if (mId == null || !mId.startsWith(pSlug)) {
            mId = reconstructedId;
          }
        }

        if (mId != null) {
          if (rId != null) {
            transaction.update(
              _db.collection('municipalities').doc(mId).collection('recordings').doc(rId),
              {'status': 'approved'},
            );
          }

          if (dialect != null) {
            final dialects = muniDialects[mId]!;
            if (!dialects.contains(dialect)) {
              dialects.add(dialect);
              modifiedMuniIds.add(mId);
            }
          }
        }

        // Notify contributor
        final contributorId = data['contributorId'];
        if (contributorId != null) {
          final notifRef = _db.collection('users').doc(contributorId).collection('notifications').doc();
          transaction.set(notifRef, {
            'title': config.notifications['voice_approved_title'] ?? 'Voice Recording Approved! 🎙️',
            'message': config.formatNotification('voice_approved_body', {'title': data['title'] ?? 'your recording'}),
            'type': 'approval',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });

          transaction.update(_db.collection('users').doc(contributorId), {
            'xp': FieldValue.increment(config.voiceApprovalXp),
          });
        }
      }

      // Update supportedDialects for all affected municipalities
      for (var mId in modifiedMuniIds) {
        transaction.update(_db.collection('municipalities').doc(mId), {
          'supportedDialects': muniDialects[mId],
        });
      }
    });
  }

  Future<void> bulkRejectVoiceSubmissions(List<String> ids, String validatorId, String validatorRole, String feedback) async {
    return _db.runTransaction((transaction) async {
      final validatorRef = _db.collection('users').doc(validatorId);
      final validatorDoc = await transaction.get(validatorRef);
      final validatorName = validatorDoc.data()?['username'] ?? 'Validator';

      for (var id in ids) {
        final docRef = _db.collection('voice_submissions').doc(id);
        final doc = await transaction.get(docRef);
        final data = doc.data();
        if (data == null) continue;

        _saveVersionTransaction(transaction, docRef, data, validatorId);

        _logAuditTransaction(
          transaction,
          action: 'REJECTED (BULK)',
          actorId: validatorId,
          actorName: validatorName,
          targetId: id,
          targetName: data['title'] ?? 'Voice Recording',
          targetType: 'voice',
          icon: '🚫',
        );

        transaction.update(docRef, {
          'status': 'rejected',
          'validatorId': validatorId,
          'validatorRole': validatorRole,
          'validatorFeedback': feedback,
          'validatedAt': FieldValue.serverTimestamp(),
        });

        final contributorId = data['contributorId'];
        final title = data['title'] ?? 'your voice recording';
        if (contributorId != null) {
          final notifRef = _db.collection('users').doc(contributorId).collection('notifications').doc();
          transaction.set(notifRef, {
            'title': 'Voice Recording Rejected (Bulk) ⚠️',
            'message': 'Your recording "$title" was not approved: $feedback',
            'type': 'rejection',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }
    });
  }

  Future<void> bulkFlagVoiceSubmissions(List<String> ids, String validatorId, String validatorRole, String feedback) async {
    return _db.runTransaction((transaction) async {
      final validatorRef = _db.collection('users').doc(validatorId);
      final validatorDoc = await transaction.get(validatorRef);
      final validatorName = validatorDoc.data()?['username'] ?? 'Validator';

      for (var id in ids) {
        final docRef = _db.collection('voice_submissions').doc(id);
        final doc = await transaction.get(docRef);
        final data = doc.data();
        if (data == null) continue;

        _saveVersionTransaction(transaction, docRef, data, validatorId);

        _logAuditTransaction(
          transaction,
          action: 'FLAGGED (BULK)',
          actorId: validatorId,
          actorName: validatorName,
          targetId: id,
          targetName: data['title'] ?? 'Voice Recording',
          targetType: 'voice',
          icon: '🚩',
        );

        transaction.update(docRef, {
          'status': 'flagged',
          'validatorId': validatorId,
          'validatorRole': validatorRole,
          'validatorFeedback': feedback,
          'validatedAt': FieldValue.serverTimestamp(),
        });

        final contributorId = data['contributorId'];
        final title = data['title'] ?? 'your voice recording';
        if (contributorId != null) {
          final notifRef = _db.collection('users').doc(contributorId).collection('notifications').doc();
          transaction.set(notifRef, {
            'title': 'Voice Recording Feedback (Bulk) 🎤',
            'message': 'A $validatorRole requested changes for "$title": $feedback',
            'type': 'flagged',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }
    });
  }

  Future<void> bulkDeleteVoiceSubmissions(List<String> ids) async {
    final batch = _db.batch();
    for (var id in ids) {
      batch.delete(_db.collection('voice_submissions').doc(id));
    }
    await batch.commit();
  }

  /// Flags a voice submission for clarification and notifies the contributor.
  Future<void> flagVoiceSubmission(
    String id,
    String validatorId,
    String validatorRole,
    String feedback,
  ) async {
    return _db.runTransaction((transaction) async {
      final docRef = _db.collection('voice_submissions').doc(id);
      final doc = await transaction.get(docRef);
      final data = doc.data();
      if (data == null) return;

      final validatorRef = _db.collection('users').doc(validatorId);
      final validatorDoc = await transaction.get(validatorRef);
      final validatorName = validatorDoc.data()?['username'] ?? 'Validator';

      _saveVersionTransaction(transaction, docRef, data, validatorId);

      _logAuditTransaction(
        transaction,
        action: 'FLAGGED',
        actorId: validatorId,
        actorName: validatorName,
        targetId: id,
        targetName: data['title'] ?? 'Voice Recording',
        targetType: 'voice',
        icon: '🚩',
      );

      transaction.update(docRef, {
        'status': 'flagged',
        'validatorId': validatorId,
        'validatorRole': validatorRole,
        'validatorFeedback': feedback,
        'validatedAt': FieldValue.serverTimestamp(),
      });

      final contributorId = data['contributorId'];
      final title = data['title'] ?? 'your voice recording';

      if (contributorId != null) {
        final notifRef = _db.collection('users').doc(contributorId).collection('notifications').doc();
        transaction.set(notifRef, {
          'title': 'Voice Recording Feedback 🎤',
          'message': 'A $validatorRole requested changes for "$title": $feedback',
          'type': 'flagged',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    });
  }

  /// Rejects a voice submission and notifies the contributor.
  Future<void> rejectVoiceSubmission(
    String id,
    String validatorId,
    String validatorRole,
    String feedback,
  ) async {
    return _db.runTransaction((transaction) async {
      final docRef = _db.collection('voice_submissions').doc(id);
      final doc = await transaction.get(docRef);
      final data = doc.data();
      if (data == null) return;

      final validatorRef = _db.collection('users').doc(validatorId);
      final validatorDoc = await transaction.get(validatorRef);
      final validatorName = validatorDoc.data()?['username'] ?? 'Validator';

      _saveVersionTransaction(transaction, docRef, data, validatorId);

      _logAuditTransaction(
        transaction,
        action: 'REJECTED',
        actorId: validatorId,
        actorName: validatorName,
        targetId: id,
        targetName: data['title'] ?? 'Voice Recording',
        targetType: 'voice',
        icon: '🚫',
      );

      transaction.update(docRef, {
        'status': 'rejected',
        'validatorId': validatorId,
        'validatorRole': validatorRole,
        'validatorFeedback': feedback,
        'validatedAt': FieldValue.serverTimestamp(),
      });

      final contributorId = data['contributorId'];
      final title = data['title'] ?? 'your voice recording';

      if (contributorId != null) {
        final notifRef = _db.collection('users').doc(contributorId).collection('notifications').doc();
        transaction.set(notifRef, {
          'title': 'Voice Recording Rejected ⚠️',
          'message': 'Your recording "$title" was not approved: $feedback',
          'type': 'rejection',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    });
  }

  /// Count of pending voice submissions.
  Stream<int> getPendingVoiceSubmissionsCount({String? dialect}) {
    return _db
        .collection('voice_submissions')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
      if (dialect == null || dialect == 'All' || dialect.isEmpty) {
        return snap.size;
      }
      return snap.docs.where((doc) => doc.data()['dialect'] == dialect).length;
    });
  }

  /// Count of pending lessons.
  Stream<int> getPendingLessonsCount({String? dialect}) {
    return _db
        .collection('lessons')
        .where('status', isEqualTo: 'PENDING_REVIEW')
        .snapshots()
        .map((snap) {
      if (dialect == null || dialect == 'All' || dialect.isEmpty) {
        return snap.size;
      }
      return snap.docs.where((doc) => doc.data()['language'] == dialect).length;
    });
  }

  // ── Community Feed Operations ──────────────────────────────────────────

  Stream<List<CommunityActivity>> getCommunityFeed({int limit = 20}) {
    return _db
        .collection('community_feed')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CommunityActivity.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> toggleLike(
    String activityId,
    String userId, {
    String? userName,
    String? userPhotoUrl,
  }) async {
    final docRef = _db.collection('community_feed').doc(activityId);

    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final targetUserId = data['userId'] as String?;

      if (likedBy.contains(userId)) {
        transaction.update(docRef, {
          'likedBy': FieldValue.arrayRemove([userId]),
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        transaction.update(docRef, {
          'likedBy': FieldValue.arrayUnion([userId]),
          'likeCount': FieldValue.increment(1),
        });

        // Add notification for the activity owner
        if (targetUserId != null && targetUserId != userId) {
          final notifRef = _db
              .collection('users')
              .doc(targetUserId)
              .collection('notifications')
              .doc();

          transaction.set(notifRef, {
            'type': 'like',
            'title': 'Sacred Spark! ✨',
            'message': '${userName ?? 'Someone'} liked your activity.',
            'senderId': userId,
            'senderName': userName ?? 'Tribe Member',
            'senderPhotoUrl': userPhotoUrl,
            'activityId': activityId,
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  Future<void> addComment(
    String activityId,
    String userId,
    String userName,
    String text, {
    String? userPhotoUrl,
  }) async {
    final activityRef = _db.collection('community_feed').doc(activityId);
    final commentRef = activityRef.collection('comments').doc();

    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(activityRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final targetUserId = data['userId'] as String?;

      transaction.set(commentRef, {
        'userId': userId,
        'userName': userName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(activityRef, {
        'commentCount': FieldValue.increment(1),
      });

      // Add notification for the activity owner
      if (targetUserId != null && targetUserId != userId) {
        final notifRef = _db
            .collection('users')
            .doc(targetUserId)
            .collection('notifications')
            .doc();

        transaction.set(notifRef, {
          'type': 'comment',
          'title': 'New Echo! 💬',
          'message': '$userName commented: "$text"',
          'senderId': userId,
          'senderName': userName,
          'senderPhotoUrl': userPhotoUrl,
          'activityId': activityId,
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // ── Scenario Operations ────────────────────────────────────────────────

  Stream<List<Scenario>> getScenarios() {
    return _db.collection('scenarios').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Scenario.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<Scenario?> getScenarioById(String id) async {
    final doc = await _db.collection('scenarios').doc(id).get();
    if (!doc.exists) return null;
    return Scenario.fromFirestore(doc.data()!, doc.id);
  }

  Future<void> addScenario(Scenario scenario) async {
    await _db.collection('scenarios').doc(scenario.id).set(scenario.toFirestore());
  }

  Future<void> updateScenario(String id, Map<String, dynamic> data) async {
    await _db.collection('scenarios').doc(id).update(data);
  }

  Future<void> deleteScenario(String id) async {
    await _db.collection('scenarios').doc(id).delete();
  }

  Future<void> seedScenarios() async {
    final scenarios = [
      Scenario(
        id: 'forest_wisdom',
        title: 'The Forest\'s Whispers',
        description: 'Learn the secrets of the ancient woods from an elder.',
        difficulty: 'Beginner',
        baseReward: 100,
        iconName: 'auto_stories',
        initialNodeId: 'start',
        nodes: {
          'start': ScenarioNode(
            id: 'start',
            text: 'You meet an elder at the edge of the Kagulangan. He gestures for you to follow. Do you go?',
            choices: [
              ScenarioChoice(label: 'Follow the Elder', targetNodeId: 'follow', xpReward: 10),
              ScenarioChoice(label: 'Stay back', targetNodeId: 'stay', xpReward: 0),
            ],
          ),
          'follow': ScenarioNode(
            id: 'follow',
            text: 'He points to a rare orchid. "This is the Waling-waling," he says. How do you respond?',
            choices: [
              ScenarioChoice(label: 'Ask for its history', targetNodeId: 'history', xpReward: 20),
              ScenarioChoice(label: 'Just nod respectfully', targetNodeId: 'end', xpReward: 10),
            ],
          ),
          'stay': ScenarioNode(
            id: 'stay',
            text: 'The forest remains a mystery to you. Perhaps another time.',
            choices: [
              ScenarioChoice(label: 'Finish', targetNodeId: 'end', xpReward: 5),
            ],
          ),
          'history': ScenarioNode(
            id: 'history',
            text: 'He smiles and tells you a legend of the first Lumad. You feel enlightened.',
            choices: [
              ScenarioChoice(label: 'Gratitude', targetNodeId: 'end', xpReward: 30),
            ],
          ),
        },
      ),
      Scenario(
        id: 'market_day',
        title: 'Tribal Trade',
        description: 'Navigate the busy tribal market and trade fairly.',
        difficulty: 'Intermediate',
        baseReward: 150,
        iconName: 'storefront',
        initialNodeId: 'start',
        nodes: {
          'start': ScenarioNode(
            id: 'start',
            text: 'The market is loud. A weaver offers you a hand-woven Malong for 50 crystals. It looks high quality.',
            choices: [
              ScenarioChoice(label: 'Buy it immediately', targetNodeId: 'buy', xpReward: 5),
              ScenarioChoice(label: 'Haggle respectfully', targetNodeId: 'haggle', xpReward: 15),
            ],
          ),
          'buy': ScenarioNode(
            id: 'buy',
            text: 'She is pleased. "You support our craft well," she says.',
            choices: [
              ScenarioChoice(label: 'Complete Trade', targetNodeId: 'end', xpReward: 10),
            ],
          ),
          'haggle': ScenarioNode(
            id: 'haggle',
            text: 'She smiles. "A wise trader! How about 45?"',
            choices: [
              ScenarioChoice(label: 'Accept 45', targetNodeId: 'end', xpReward: 20),
              ScenarioChoice(label: 'Insist on 40', targetNodeId: 'greedy', xpReward: 0),
            ],
          ),
          'greedy': ScenarioNode(
            id: 'greedy',
            text: 'She looks disappointed. "This takes weeks to weave. 45 is my lowest."',
            choices: [
              ScenarioChoice(label: 'Apologize and pay 45', targetNodeId: 'end', xpReward: 5),
              ScenarioChoice(label: 'Walk away', targetNodeId: 'end', xpReward: 0),
            ],
          ),
        },
      ),
    ];

    for (var s in scenarios) {
      await addScenario(s);
    }
  }

  // ── Audit Trail & Versioning ──────────────────────────────────────────

  /// Internal helper to log an action to the global audit trail within a transaction.
  void _logAuditTransaction(
    Transaction transaction, {
    required String action,
    required String actorId,
    required String actorName,
    required String targetId,
    required String targetName,
    required String targetType,
    String icon = '🔧',
    Map<String, dynamic>? metadata,
  }) {
    final docRef = _db.collection('audit_trail').doc();
    transaction.set(docRef, {
      'action': action,
      'actorId': actorId,
      'actorName': actorName,
      'targetId': targetId,
      'targetName': targetName,
      'targetType': targetType,
      'timestamp': FieldValue.serverTimestamp(),
      'icon': icon,
      if (metadata != null) 'metadata': metadata,
    });
  }

  /// Internal helper to save a version snapshot of a document within a transaction.
  void _saveVersionTransaction(
    Transaction transaction,
    DocumentReference targetRef,
    Map<String, dynamic> previousData,
    String actorId,
  ) {
    final historyRef = targetRef.collection('version_history').doc();
    transaction.set(historyRef, {
      'snapshot': previousData,
      'timestamp': FieldValue.serverTimestamp(),
      'actorId': actorId,
    });
  }

  Stream<List<AuditLogEntry>> getAuditTrail({int limit = 50}) {
    return _db
        .collection('audit_trail')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AuditLogEntry.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Stream<List<Map<String, dynamic>>> getVersionHistory(
    String collectionPath,
    String documentId,
  ) {
    return _db
        .collection(collectionPath)
        .doc(documentId)
        .collection('version_history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }
}


// Global Providers
final firebaseServiceProvider = Provider((ref) {
  return FirebaseService();
});

final dictionaryStreamProvider = StreamProvider<List<DictionaryEntry>>((ref) {
  return ref.watch(firebaseServiceProvider).getValidatedDictionaryWords();
});

final pendingDictionaryStreamProvider =
    StreamProvider.family<List<DictionaryEntry>, ValidatorQuery>((ref, query) {
      return ref.watch(firebaseServiceProvider).getPendingDictionaryWords(
            limit: query.limit,
            search: query.search,
            dialect: query.dialect,
          );
    });

final globalDictionaryStreamProvider =
    StreamProvider.family<List<DictionaryEntry>, ValidatorQuery>((ref, query) {
      return ref.watch(firebaseServiceProvider).getGlobalDictionaryWords(
            limit: query.limit,
            search: query.search,
            dialect: query.dialect,
          );
    });

final mapMarkersStreamProvider = StreamProvider<List<GeoRecording>>((ref) {
  return ref.watch(firebaseServiceProvider).getMunicipalities();
});

final userBookmarksStreamProvider = StreamProvider.family<List<String>, String>(
  (ref, userId) {
    return ref.watch(firebaseServiceProvider).getBookmarks(userId);
  },
);

final userNotificationsStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
      return ref.watch(firebaseServiceProvider).getNotifications(userId);
    });

class NotificationQuery {
  final String userId;
  final int limit;
  const NotificationQuery(this.userId, this.limit);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationQuery &&
          other.userId == userId &&
          other.limit == limit;

  @override
  int get hashCode => userId.hashCode ^ limit.hashCode;
}

final paginatedNotificationsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, NotificationQuery>((
  ref,
  query,
) {
  return ref
      .watch(firebaseServiceProvider)
      .getNotifications(query.userId, limit: query.limit);
});

final userContributionsStreamProvider =
    StreamProvider.family<List<DictionaryEntry>, String>((ref, userId) {
      return ref.watch(firebaseServiceProvider).getUserContributions(userId);
    });

final userVoiceSubmissionsStreamProvider =
    StreamProvider.family<List<VoiceSubmission>, String>((ref, userId) {
      return ref.watch(firebaseServiceProvider).getUserVoiceSubmissions(userId);
    });

final dialectsInNeedProvider = StreamProvider<Map<String, int>>((ref) {
  return ref.watch(firebaseServiceProvider).getAllDictionaryWords().map((
    words,
  ) {
    final counts = <String, int>{};
    for (final word in words) {
      final String rawLang = word.language.trim();
      if (rawLang.isEmpty) continue;

      // Robust normalization:
      // 1. Title Case for each word (handles "MANSAKA", "mansaka", "Mansaka")
      // 2. Merges them into a single key in the counts map
      final String normalized = rawLang
          .split(RegExp(r'\s+'))
          .map((s) => s.isNotEmpty
              ? s[0].toUpperCase() + s.substring(1).toLowerCase()
              : "")
          .join(' ')
          .trim();

      if (normalized.isEmpty) continue;
      counts[normalized] = (counts[normalized] ?? 0) + 1;
    }
    return counts;
  });
});

final totalUsersCountProvider = StreamProvider<int>((ref) {
  return ref.watch(firebaseServiceProvider).getTotalUsersCount();
});

final srsProgressStreamProvider =
    StreamProvider.family<List<SRSProgress>, String>((ref, userId) {
      return ref.watch(firebaseServiceProvider).getSRSProgress(userId);
    });

final totalWordsCountProvider = StreamProvider<int>((ref) {
  return ref.watch(firebaseServiceProvider).getTotalWordsCount();
});

final pendingWordsCountProvider = StreamProvider.family<int, String?>((ref, dialect) {
  return ref.watch(firebaseServiceProvider).getPendingWordsCount(dialect: dialect);
});

final totalAudioClipsCountProvider = StreamProvider<int>((ref) {
  return ref.watch(firebaseServiceProvider).getTotalAudioClipsCount();
});

final validatorActivityCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  return ref.watch(firebaseServiceProvider).getValidatorActivityCount(userId);
});

final validatorMetricsProvider =
    StreamProvider.family<Map<String, int>, String>((ref, userId) {
      return ref.watch(firebaseServiceProvider).getValidatorMetrics(userId);
    });

final voiceValidatorMetricsProvider =
    StreamProvider.family<Map<String, int>, String>((ref, userId) {
      return ref
          .watch(firebaseServiceProvider)
          .getVoiceValidatorMetrics(userId);
    });

final contributorWordCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  return ref.watch(firebaseServiceProvider).getContributorWordCount(userId);
});

final dialectDistributionProvider = StreamProvider<Map<String, double>>((ref) {
  return ref.watch(firebaseServiceProvider).getAllDictionaryWords().map((
    words,
  ) {
    if (words.isEmpty) {
      return {};
    }
    final counts = <String, int>{};
    for (final word in words) {
      final String rawLang = word.language.trim();
      if (rawLang.isEmpty) continue;

      // Consistent normalization with dialectsInNeedProvider
      final String normalized = rawLang
          .split(RegExp(r'\s+'))
          .map((s) => s.isNotEmpty
              ? s[0].toUpperCase() + s.substring(1).toLowerCase()
              : "")
          .join(' ')
          .trim();

      if (normalized.isEmpty) continue;
      counts[normalized] = (counts[normalized] ?? 0) + 1;
    }

    final total = words.length;
    return counts.map((key, value) => MapEntry(key, value / total));
  });
});

final municipalityRecordingsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      municipalityId,
    ) {
      return ref
          .watch(firebaseServiceProvider)
          .getRecordingsForMunicipality(municipalityId);
    });

final lessonsStreamProvider = StreamProvider<List<Lesson>>((ref) {
  final stream = ref.watch(firebaseServiceProvider).getPublishedLessons();
  return stream.map((lessons) {
    // Automatically cache lessons for offline use
    ref.read(offlineServiceProvider).saveLessons(lessons);
    return lessons;
  });
});

final allLessonsStreamProvider = StreamProvider<List<Lesson>>((ref) {
  return ref.watch(firebaseServiceProvider).getAllLessons();
});

final userProgressStreamProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, userId) {
      return ref.watch(firebaseServiceProvider).getUserProgress(userId);
    });

final allUsersProvider = StreamProvider<List<AdminUser>>((ref) {
  return ref.watch(firebaseServiceProvider).getAllUsers();
});

final topLearnersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(firebaseServiceProvider).getLeaderboardLearners();
});

final topContributorsProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  return ref.watch(firebaseServiceProvider).getLeaderboardContributors();
});

class ValidatorQuery {
  final String id;
  final int limit;
  final String? search;
  final String? dialect;
  const ValidatorQuery(this.id, this.limit, {this.search, this.dialect});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidatorQuery &&
          other.id == id &&
          other.limit == limit &&
          other.search == search &&
          other.dialect == dialect;

  @override
  int get hashCode =>
      id.hashCode ^
      limit.hashCode ^
      (search?.hashCode ?? 0) ^
      (dialect?.hashCode ?? 0);
}

final validatorHistoryStreamProvider =
    StreamProvider.family<List<DictionaryEntry>, ValidatorQuery>((ref, query) {
      return ref
          .watch(firebaseServiceProvider)
          .getValidatorHistory(
            query.id,
            limit: query.limit,
            search: query.search,
            dialect: query.dialect,
          );
    });

final dialectsProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(firebaseServiceProvider).getDialects();
});

final artifactsStreamProvider = StreamProvider<List<Artifact>>((ref) {
  return ref.watch(firebaseServiceProvider).getArtifacts();
});

final userBadgesStreamProvider =
    StreamProvider.family<List<GalleryBadge>, String>((ref, userId) {
      return ref.watch(firebaseServiceProvider).getEarnedBadges(userId);
    });

final educatorAnalyticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, educatorId) async {
  return ref.watch(firebaseServiceProvider).getEducatorAnalytics(educatorId);
});

final villageTopLearnersProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, educatorId) {
  return ref.watch(firebaseServiceProvider).getVillageLeaderboard(educatorId);
});

final educatorLearnersProvider =
    StreamProvider.family<List<AdminUser>, String>((ref, educatorId) {
  return ref.watch(firebaseServiceProvider).db
      .collection('users')
      .where('educatorId', isEqualTo: educatorId)
      .where('role', isEqualTo: 'learner')
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => AdminUser.fromFirestore(doc.data(), doc.id))
          .toList());
});

final advancedAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(firebaseServiceProvider).getAdvancedPedagogicalAnalytics();
});

// ── Voice Submission Providers ──────────────────────────────────────────

final pendingVoiceSubmissionsProvider =
    StreamProvider.family<List<VoiceSubmission>, ValidatorQuery>((ref, query) {
      return ref.watch(firebaseServiceProvider).getPendingVoiceSubmissions(
            limit: query.limit,
            dialect: query.dialect,
          );
    });

final voiceValidatorHistoryProvider =
    StreamProvider.family<List<VoiceSubmission>, ValidatorQuery>((ref, query) {
      return ref
          .watch(firebaseServiceProvider)
          .getVoiceValidatorHistory(query.id, limit: query.limit);
    });

final pendingVoiceSubmissionsCountProvider =
    StreamProvider.family<int, String?>((ref, dialect) {
  return ref
      .watch(firebaseServiceProvider)
      .getPendingVoiceSubmissionsCount(dialect: dialect);
});

final pendingLessonsCountProvider =
    StreamProvider.family<int, String?>((ref, dialect) {
  return ref
      .watch(firebaseServiceProvider)
      .getPendingLessonsCount(dialect: dialect);
});

// ── Community Feed Providers ────────────────────────────────────────────

final communityFeedProvider = StreamProvider<List<CommunityActivity>>((ref) {
  return ref.watch(firebaseServiceProvider).getCommunityFeed();
});

final appConfigProvider = StreamProvider<AppConfig>((ref) {
  return ref.watch(firebaseServiceProvider).getAppConfig();
});

final seasonsStreamProvider = StreamProvider<List<LearningSeason>>((ref) {
  return ref.watch(firebaseServiceProvider).getSeasons();
});

final shopItemsStreamProvider = StreamProvider<List<ShopItem>>((ref) {
  return ref.watch(firebaseServiceProvider).getShopItems();
});

final linguaDuelsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(firebaseServiceProvider).getLinguaDuels();
});

final systemHealthProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return ref.watch(firebaseServiceProvider).getSystemHealth();
});

final platformActivityProvider = StreamProvider<Map<String, List<int>>>((ref) {
  return ref.watch(firebaseServiceProvider).getPlatformActivityStats();
});

final dialectSettingsProvider = StreamProvider<Map<String, bool>>((ref) {
  return ref.watch(firebaseServiceProvider).getDialectSettings();
});

final allWordsProvider = StreamProvider<List<DictionaryEntry>>((ref) {
  return ref.watch(firebaseServiceProvider).getAllDictionaryWords();
});

final allVoiceSubmissionsProvider = StreamProvider<List<VoiceSubmission>>((ref) {
  return ref.watch(firebaseServiceProvider).getAllVoiceSubmissions();
});

final scenariosProvider = StreamProvider<List<Scenario>>((ref) {
  return ref.watch(firebaseServiceProvider).getScenarios();
});

final broadcastsProvider = StreamProvider<List<VillageBroadcast>>((ref) {
  return ref.watch(firebaseServiceProvider).getVillageBroadcasts();
});

final studentFeedbackProvider = StreamProvider<List<StudentFeedback>>((ref) {
  return ref.watch(firebaseServiceProvider).getStudentFeedback();
});

final unreadFeedbackCountProvider = StreamProvider<int>((ref) {
  return ref.watch(firebaseServiceProvider).getUnreadFeedbackCount();
});

final masteredWordsCountProvider = StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(firebaseServiceProvider).db
      .collection('users')
      .doc(userId)
      .collection('srs_progress')
      .where('level', isGreaterThanOrEqualTo: 4)
      .snapshots()
      .map((snap) => snap.size);
});

final dueSRSCountProvider = StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(firebaseServiceProvider).db
      .collection('users')
      .doc(userId)
      .collection('srs_progress')
      .where('nextReview', isLessThanOrEqualTo: DateTime.now())
      .snapshots()
      .map((snap) => snap.size);
});

final versionHistoryProvider =
    StreamProvider.family<List<Map<String, dynamic>>, ({String path, String id})>((
  ref,
  arg,
) {
  return ref.watch(firebaseServiceProvider).getVersionHistory(arg.path, arg.id);
});

final userImpactMetricsProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, userId) {
  return ref.watch(firebaseServiceProvider).getUserImpactMetrics(userId);
});



