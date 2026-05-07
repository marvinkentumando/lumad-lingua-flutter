import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
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
import '../models/validator_models.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  FirebaseFirestore get db => _db;

  FirebaseService();

  // Generic File Upload
  Future<String> uploadFile(
    String path,
    dynamic fileData, {
    String? fileName,
  }) async {
    final String name =
        fileName ?? DateTime.now().millisecondsSinceEpoch.toString();
    final ref = _storage.ref().child('$path/$name');

    if (fileData is File) {
      await ref.putFile(fileData);
    } else if (fileData is List<int>) {
      await ref.putData(Uint8List.fromList(fileData));
    } else {
      throw Exception('Unsupported file data type');
    }

    return await ref.getDownloadURL();
  }

  // Audio Upload
  Future<String> uploadAudio(String filePath, String fileName) async {
    final file = File(filePath);
    final ref = _storage.ref().child('audio/$fileName');
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<String> uploadProfilePicture(String userId, File file) async {
    final ref = _storage.ref().child(
      'users/$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

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
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => DictionaryEntry.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<String>> getDialects() {
    return _db.collection('config').doc('languages').snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return ["All", "Mansaka", "Mandaya"];
      }
      final list = List<String>.from(doc.data()!['list'] ?? []);
      if (!list.contains("All")) list.insert(0, "All");
      return list;
    });
  }

  Stream<List<DictionaryEntry>> getPendingDictionaryWords({
    int limit = 50,
    String? search,
  }) {
    Query query = _db.collection('words').where('status', isEqualTo: 'pending');

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
  }) {
    Query query = _db
        .collection('words')
        .where('validatorId', isEqualTo: validatorId);

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

  Stream<List<DictionaryEntry>> getUserContributions(String userId) {
    return _db
        .collection('words')
        .where('contributorId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => DictionaryEntry.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<Artifact>> getUserArtifacts(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('artifacts')
        .orderBy('tier', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Artifact.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<DictionaryEntry>> getAllDictionaryWords() {
    return _db.collection('words').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => DictionaryEntry.fromFirestore(doc.data(), doc.id))
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
        // Add Notification
        final notifRef = _db
            .collection('users')
            .doc(contributorId)
            .collection('notifications')
            .doc();
        transaction.set(notifRef, {
          'title': 'Entry Approved! 🌟',
          'message':
              'Your contribution "$term" has been validated by a $validatorRole and is now live in the dictionary.',
          'type': 'approval',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        // Award XP
        final userRef = _db.collection('users').doc(contributorId);
        transaction.update(userRef, {
          'xp': FieldValue.increment(100),
          'wordCount': FieldValue.increment(1),
        });
      }
    });
  }

  Future<void> flagWord(
    String id,
    String validatorId,
    String validatorRole,
    String feedback,
  ) async {
    return _db.runTransaction((transaction) async {
      final docRef = _db.collection('words').doc(id);
      final doc = await transaction.get(docRef);
      final data = doc.data();
      if (data == null) return;

      transaction.update(docRef, {
        'status': 'flagged',
        'isValidated': false,
        'validatorId': validatorId,
        'validatorRole': validatorRole,
        'validatorFeedback': feedback,
        'flaggedAt': FieldValue.serverTimestamp(),
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
    String feedback,
  ) async {
    return _db.runTransaction((transaction) async {
      final docRef = _db.collection('words').doc(id);
      final doc = await transaction.get(docRef);
      final data = doc.data();
      if (data == null) return;

      transaction.update(docRef, {
        'status': 'rejected',
        'isValidated': false,
        'validatorId': validatorId,
        'validatorRole': validatorRole,
        'validatorFeedback': feedback,
        'rejectedAt': FieldValue.serverTimestamp(),
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

  // CRUD Operations for Dictionary
  Future<void> addWord(DictionaryEntry entry) async {
    await _db.collection('words').add(entry.toFirestore());
  }

  Future<void> updateWord(String id, Map<String, dynamic> data) async {
    await _db.collection('words').doc(id).update(data);
  }

  Future<void> deleteWord(String id) async {
    await _db.collection('words').doc(id).delete();
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
  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
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

  // Community Recording Operations
  Future<void> addRecording(
    String municipalityId,
    Map<String, dynamic> recordingData,
  ) async {
    await _db
        .collection('municipalities')
        .doc(municipalityId)
        .collection('recordings')
        .add({...recordingData, 'timestamp': FieldValue.serverTimestamp()});
  }

  Stream<List<Map<String, dynamic>>> getRecordingsForMunicipality(
    String municipalityId,
  ) {
    return _db
        .collection('municipalities')
        .doc(municipalityId)
        .collection('recordings')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        });
  }

  // Audio Upload Operations
  Future<String> uploadVoiceFragment(String userId, String filePath) async {
    final file = File(filePath);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
    final ref = FirebaseStorage.instance
        .ref()
        .child('voice_fragments')
        .child(userId)
        .child(fileName);

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // User Management
  Stream<List<AdminUser>> getAllUsers() {
    return _db.collection('users').snapshots().map((snap) {
      return snap.docs
          .map((doc) => AdminUser.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    await _db.collection('users').doc(userId).update({'role': newRole});
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
        .map(
          (snap) =>
              snap.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> getLeaderboardContributors() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'contributor')
        .orderBy('wordCount', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList(),
        );
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
        // Notify Contributor
        final notifRef = _db
            .collection('users')
            .doc(contributorId)
            .collection('notifications')
            .doc();
        transaction.set(notifRef, {
          'title': 'Curriculum Approved! 📚',
          'message': 'Your lesson "$title" is now live for all students.',
          'type': 'approval',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        // Award XP (More than single words)
        final userRef = _db.collection('users').doc(contributorId);
        transaction.update(userRef, {
          'xp': FieldValue.increment(500),
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
    final doc = await _db.collection('lessons').doc(id).get();
    final data = doc.data();
    if (data == null) return;

    await _db.collection('lessons').doc(id).update({
      'status': 'FLAGGED',
      'isValidated': false,
      'validatorId': validatorId,
      'validatorRole': validatorRole,
      'validatorFeedback': feedback,
      'flaggedAt': FieldValue.serverTimestamp(),
    });

    final contributorId = data['contributorId'];
    if (contributorId != null) {
      await addNotification(contributorId, {
        'title': 'Lesson Feedback 📝',
        'message':
            'A $validatorRole suggested changes for "${data['title']}": $feedback',
        'type': 'flagged',
      });
    }
  }

  Stream<List<Lesson>> getPendingLessons() {
    return _db
        .collection('lessons')
        .where('status', isEqualTo: 'PENDING_REVIEW')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Lesson.fromFirestore(doc.data(), doc.id))
              .toList();
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

    if (lesson.id.isEmpty || lesson.id.startsWith('temp_')) {
      data['createdAt'] = FieldValue.serverTimestamp();
      final docRef = await _db.collection('lessons').add(data);
      return docRef.id;
    } else {
      // 1. If updating an existing lesson, check if unitNumber changed to handle reordering
      final oldDoc = await _db.collection('lessons').doc(lesson.id).get();
      if (oldDoc.exists) {
        final oldUnit = oldDoc.data()?['unitNumber'] as int?;
        if (oldUnit != null && oldUnit != lesson.unitNumber) {
          // If the unit increased, we might need to shift others?
          // Usually, insertion at 'unit X' shifts X and above to X+1.
          // This is a manual choice, but we'll implement a helper.
        }
      }

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

  Future<void> deleteFileByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting file: $e');
      // If file doesn't exist, we can ignore
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

  Future<Map<String, dynamic>> getEducatorAnalytics() async {
    try {
      final progressSnap = await _db.collectionGroup('progress').get();
      final lessonsSnap = await _db.collection('lessons').get();

      final Map<String, String> lessonNames = {};
      final Map<String, List<Map<String, dynamic>>> lessonTasks = {};

      for (var doc in lessonsSnap.docs) {
        lessonNames[doc.id] =
            doc.data()['title'] as String? ?? 'Unknown Lesson';
        lessonTasks[doc.id] = List<Map<String, dynamic>>.from(
          doc.data()['tasks'] ?? [],
        );
      }

      final Map<String, int> lessonAttempts = {};
      final Map<String, int> lessonPasses = {};
      final Map<String, int> taskMistakesCount = {};
      final Map<String, String> taskToLesson = {};

      for (var doc in progressSnap.docs) {
        final data = doc.data();
        final lessonId = doc.id;
        final completed = data['completed'] == true;

        lessonAttempts[lessonId] = (lessonAttempts[lessonId] ?? 0) + 1;
        if (completed) {
          lessonPasses[lessonId] = (lessonPasses[lessonId] ?? 0) + 1;
        }

        final performance = data['performance'] as Map<String, dynamic>? ?? {};
        performance.forEach((taskId, mistakes) {
          taskMistakesCount[taskId] =
              (taskMistakesCount[taskId] ?? 0) +
              ((mistakes as num?)?.toInt() ?? 0);
          taskToLesson[taskId] = lessonId;
        });
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
          'stat': '$mistakes recorded mistakes',
          'lessonName': lessonNames[lessonId] ?? 'Unknown',
        });
      }

      return {'quizPerformance': quizPerformance, 'commonHurdles': hurdles};
    } catch (e) {
      debugPrint('Error getting analytics: $e');
      return {
        'quizPerformance': <Map<String, dynamic>>[],
        'commonHurdles': <Map<String, dynamic>>[],
      };
    }
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
            // Simple random selection (in future, weight by rarity)
            droppedArtifact = allArtifacts[random.nextInt(allArtifacts.length)];
          }
        } catch (e) {
          debugPrint('Gacha fetch error: $e');
        }
      }
    }

    return _db.runTransaction((transaction) async {
      final progressRef = _db
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(lessonId);
      final userRef = _db.collection('users').doc(userId);

      final progressDoc = await transaction.get(progressRef);
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
            progressDoc.data()?['performance'] as Map<String, dynamic>? ?? {};
        taskPerformance.forEach((key, value) {
          existingPerformance[key] = (existingPerformance[key] ?? 0) + value;
        });
        updateData['performance'] = existingPerformance;
      }

      transaction.set(progressRef, updateData, SetOptions(merge: true));

      // 3. Struggle Point Telemetry (Community-wide Heatmap)
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

      // Calculate rewards
      int xpReward = 0;
      int firstTryCount = 0;
      int retryCount = 0;

      if (lesson != null) {
        for (var task in lesson.tasks) {
          final mistakes = taskPerformance?[task.id] ?? 0;
          if (mistakes == 0) {
            firstTryCount++;
            xpReward += 20;
          } else {
            retryCount++;
            xpReward += 10;
          }
        }
      } else {
        // Fallback if lesson not found (unlikely)
        xpReward = score * 2;
      }

      // Completion Bonus + Combo/Speed Bonus
      xpReward += 50 + bonusXp;

      // Mist Crystal Reward
      int crystalReward;
      if (lesson?.isMistUnit ?? false) {
        crystalReward = 30; // Flat reward for Mist Units
      } else {
        crystalReward = stars == 3 ? 50 : (stars == 2 ? 25 : 15);
      }

      // Atomic reward update
      transaction.update(userRef, {
        'mistCrystals': FieldValue.increment(crystalReward),
        'xp': FieldValue.increment(xpReward),
      });

      // Pass calculated total XP back to UI (or store in meta for celebration)
      updateData['xpEarned'] = xpReward;
      updateData['crystalsEarned'] = crystalReward;
      updateData['firstTryCount'] = firstTryCount;
      updateData['retryCount'] = retryCount;

      // Vocabulary Mastery Logic
      if (lesson != null && stars >= 2) {
        // Only master words if student did reasonably well
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
                // Perfect hit: Increment mastery
                transaction.set(masterRef, {
                  'word': wordId,
                  'masteryLevel': FieldValue.increment(1),
                  'lastSeen': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
              } else {
                // Struggled: Decrement mastery (Penalty logic)
                // We use a separate get to check current level for the floor
                final masterDoc = await transaction.get(masterRef);
                final currentLevel = masterDoc.data()?['masteryLevel'] as int? ?? 0;
                if (currentLevel > 0) {
                  transaction.update(masterRef, {
                    'masteryLevel': FieldValue.increment(-1),
                    'lastSeen': FieldValue.serverTimestamp(),
                  });
                }
              }
            }
          }
        }
      }

      bool unlockedBadge = false;
      if (stars == 3) {
        final badgeRef = _db
            .collection('users')
            .doc(userId)
            .collection('achievements')
            .doc('perfect_lesson');
        final badgeDoc = await transaction.get(badgeRef);
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
      if (droppedArtifact != null) {
        final userArtifactRef = _db
            .collection('users')
            .doc(userId)
            .collection('artifacts')
            .doc(droppedArtifact!.id);
        final userArtifactDoc = await transaction.get(userArtifactRef);

        if (!userArtifactDoc.exists) {
          final artifactData = droppedArtifact!.toFirestore();
          artifactData['isEarned'] = true;
          artifactData['earnedAt'] = FieldValue.serverTimestamp();
          transaction.set(userArtifactRef, artifactData);
        } else {
          // User already has this artifact, grant 25 crystals instead
          droppedArtifact = null;
          transaction.update(userRef, {
            'mistCrystals': FieldValue.increment(25),
          });
        }
      }

      return {
        'unlockedBadge': unlockedBadge,
        'droppedArtifact': droppedArtifact,
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
    return _db.runTransaction((transaction) async {
      final userRef = _db.collection('users').doc(userId);
      final questRef = _db
          .collection('users')
          .doc(userId)
          .collection('dailyQuests')
          .doc(questId);

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

  Future<void> incrementStreak(String userId) async {
    return _db.runTransaction((transaction) async {
      final userRef = _db.collection('users').doc(userId);
      final userDoc = await transaction.get(userRef);

      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final lastActive = data['lastActive'] as Timestamp?;
      final now = DateTime.now();
      final int currentShields = data['streakShields'] ?? 0;

      if (lastActive == null) {
        transaction.update(userRef, {
          'streak': 1,
          'lastActive': FieldValue.serverTimestamp(),
        });
        return;
      }

      final lastDate = lastActive.toDate();
      final difference = DateTime(now.year, now.month, now.day)
          .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
          .inDays;

      if (difference == 0) {
        // Already active today
        return;
      } else if (difference == 1) {
        // Continued streak
        transaction.update(userRef, {
          'streak': FieldValue.increment(1),
          'lastActive': FieldValue.serverTimestamp(),
        });
      } else {
        // Streak broken? Check shields
        if (currentShields > 0) {
          transaction.update(userRef, {
            'streakShields': FieldValue.increment(-1),
            'lastActive': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(userRef, {
            'streak': 1,
            'lastActive': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  // Admin Stats
  Stream<int> getTotalUsersCount() {
    return _db.collection('users').snapshots().map((snap) => snap.size);
  }

  Stream<int> getTotalWordsCount() {
    return _db.collection('words').snapshots().map((snap) => snap.size);
  }

  Stream<int> getPendingWordsCount() {
    return _db
        .collection('words')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.size);
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

  Stream<int> getContributorWordCount(String userId) {
    return _db
        .collection('words')
        .where('contributorId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.size);
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

      transaction.update(userRef, {
        'mistCrystals': FieldValue.increment(-cost),
      });
      transaction.set(artifactRef, {
        'unlockedAt': FieldValue.serverTimestamp(),
        'isEarned': true,
      }, SetOptions(merge: true));
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
      final doc = await transaction.get(achievementRef);
      final currentCount = (doc.data()?['currentCount'] ?? 0) + increment;

      // Tier Logic: 10 = Tier I, 50 = Tier II, 100 = Tier III
      int tier = 1;
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
    });
  }
  // ── Voice Submission Operations ──────────────────────────────────────────

  /// Fetches items that require urgent attention (older than 48 hours or priority).
  Stream<List<ValidationItem>> getUrgentQueueItems() {
    final wordsStream = _db
        .collection('words')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();

    final voicesStream = _db
        .collection('voice_submissions')
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: true)
        .limit(10)
        .snapshots();

    return Rx.combineLatest2(wordsStream, voicesStream, (wordSnap, voiceSnap) {
      final List<ValidationItem> items = [];

      for (var doc in wordSnap.docs) {
        final data = doc.data();
        items.add(
          ValidationItem(
            id: doc.id,
            type: 'entry',
            title: data['term'] ?? 'New Entry',
            subtitle: data['definition'] ?? '',
            dialect: data['dialect'] ?? 'Unknown',
            contributor: data['contributorName'] ?? 'Anonymous',
            submittedAt:
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            priority: data['priority'] == true ? 'high' : 'normal',
          ),
        );
      }

      for (var doc in voiceSnap.docs) {
        final data = doc.data();
        items.add(
          ValidationItem(
            id: doc.id,
            type: 'voice',
            title: data['title'] ?? 'New Voice',
            subtitle: data['transcript'] ?? '',
            dialect: data['dialect'] ?? 'Unknown',
            contributor:
                data['speakerName'] ?? data['contributorName'] ?? 'Anonymous',
            submittedAt:
                (data['submittedAt'] as Timestamp?)?.toDate() ??
                (data['timestamp'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            priority: data['priority'] == true ? 'high' : 'normal',
          ),
        );
      }

      // Sort: high priority first, then by submission date (newest first)
      items.sort((a, b) {
        if (a.priority == 'high' && b.priority != 'high') return -1;
        if (a.priority != 'high' && b.priority == 'high') return 1;
        return b.submittedAt.compareTo(a.submittedAt);
      });

      return items;
    });
  }

  /// Streams pending voice submissions for validators to review.
  Stream<List<VoiceSubmission>> getPendingVoiceSubmissions({int limit = 50}) {
    return _db
        .collection('voice_submissions')
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => VoiceSubmission.fromFirestore(doc.data(), doc.id))
              .toList();
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
        .orderBy('validatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => VoiceSubmission.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// Approves a voice submission — awards XP and notifies the contributor.
  Future<void> approveVoiceSubmission(
    String id,
    String validatorId,
    String validatorRole,
  ) async {
    return _db.runTransaction((transaction) async {
      final docRef = _db.collection('voice_submissions').doc(id);
      final doc = await transaction.get(docRef);
      final data = doc.data();
      if (data == null) return;

      transaction.update(docRef, {
        'status': 'approved',
        'validatorId': validatorId,
        'validatorRole': validatorRole,
        'validatedAt': FieldValue.serverTimestamp(),
      });

      final contributorId = data['contributorId'];
      final title = data['title'] ?? 'your voice recording';

      if (contributorId != null) {
        final notifRef = _db
            .collection('users')
            .doc(contributorId)
            .collection('notifications')
            .doc();
        transaction.set(notifRef, {
          'title': 'Voice Recording Approved! 🎙️',
          'message':
              'Your recording "$title" has been validated by a $validatorRole.',
          'type': 'approval',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        final userRef = _db.collection('users').doc(contributorId);
        transaction.update(userRef, {'xp': FieldValue.increment(150)});
      }
    });
  }

  /// Flags a voice submission for clarification and notifies the contributor.
  Future<void> flagVoiceSubmission(
    String id,
    String validatorId,
    String validatorRole,
    String feedback,
  ) async {
    final doc = await _db.collection('voice_submissions').doc(id).get();
    final data = doc.data();
    if (data == null) return;

    await _db.collection('voice_submissions').doc(id).update({
      'status': 'flagged',
      'validatorId': validatorId,
      'validatorRole': validatorRole,
      'validatorFeedback': feedback,
      'validatedAt': FieldValue.serverTimestamp(),
    });

    final contributorId = data['contributorId'];
    final title = data['title'] ?? 'your voice recording';

    if (contributorId != null) {
      await addNotification(contributorId, {
        'title': 'Voice Recording Feedback 🎤',
        'message': 'A $validatorRole requested changes for "$title": $feedback',
        'type': 'flagged',
      });
    }
  }

  /// Rejects a voice submission and notifies the contributor.
  Future<void> rejectVoiceSubmission(
    String id,
    String validatorId,
    String validatorRole,
    String feedback,
  ) async {
    final doc = await _db.collection('voice_submissions').doc(id).get();
    final data = doc.data();
    if (data == null) return;

    await _db.collection('voice_submissions').doc(id).update({
      'status': 'rejected',
      'validatorId': validatorId,
      'validatorRole': validatorRole,
      'validatorFeedback': feedback,
      'validatedAt': FieldValue.serverTimestamp(),
    });

    final contributorId = data['contributorId'];
    final title = data['title'] ?? 'your voice recording';

    if (contributorId != null) {
      await addNotification(contributorId, {
        'title': 'Voice Recording Rejected ⚠️',
        'message': 'Your recording "$title" was not approved: $feedback',
        'type': 'rejection',
      });
    }
  }

  /// Count of pending voice submissions.
  Stream<int> getPendingVoiceSubmissionsCount() {
    return _db
        .collection('voice_submissions')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.size);
  }

  /// Count of pending lessons.
  Stream<int> getPendingLessonsCount() {
    return _db
        .collection('lessons')
        .where('status', isEqualTo: 'PENDING')
        .snapshots()
        .map((snap) => snap.size);
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

  Future<void> toggleLike(String activityId, String userId) async {
    final docRef = _db.collection('community_feed').doc(activityId);

    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);

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
      }
    });
  }

  Future<void> addComment(
    String activityId,
    String userId,
    String userName,
    String text,
  ) async {
    final activityRef = _db.collection('community_feed').doc(activityId);
    final commentRef = activityRef.collection('comments').doc();

    return _db.runTransaction((transaction) async {
      transaction.set(commentRef, {
        'userId': userId,
        'userName': userName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(activityRef, {
        'commentCount': FieldValue.increment(1),
      });
    });
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
      return ref
          .watch(firebaseServiceProvider)
          .getPendingDictionaryWords(limit: query.limit, search: query.search);
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

final userContributionsStreamProvider =
    StreamProvider.family<List<DictionaryEntry>, String>((ref, userId) {
      return ref.watch(firebaseServiceProvider).getUserContributions(userId);
    });

final dialectsInNeedProvider = StreamProvider<Map<String, int>>((ref) {
  return ref.watch(firebaseServiceProvider).getAllDictionaryWords().map((
    words,
  ) {
    final counts = <String, int>{};
    for (final word in words) {
      final lang = word.language;
      counts[lang] = (counts[lang] ?? 0) + 1;
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

final pendingWordsCountProvider = StreamProvider<int>((ref) {
  return ref.watch(firebaseServiceProvider).getPendingWordsCount();
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
      final lang = word.language;
      counts[lang] = (counts[lang] ?? 0) + 1;
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
  return ref.watch(firebaseServiceProvider).getPublishedLessons();
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
  const ValidatorQuery(this.id, this.limit, {this.search});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidatorQuery &&
          other.id == id &&
          other.limit == limit &&
          other.search == search;

  @override
  int get hashCode => id.hashCode ^ limit.hashCode ^ (search?.hashCode ?? 0);
}

final validatorHistoryStreamProvider =
    StreamProvider.family<List<DictionaryEntry>, ValidatorQuery>((ref, query) {
      return ref
          .watch(firebaseServiceProvider)
          .getValidatorHistory(
            query.id,
            limit: query.limit,
            search: query.search,
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

final educatorAnalyticsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  return ref.watch(firebaseServiceProvider).getEducatorAnalytics();
});

// ── Voice Submission Providers ──────────────────────────────────────────

final pendingVoiceSubmissionsProvider =
    StreamProvider.family<List<VoiceSubmission>, int>((ref, limit) {
      return ref
          .watch(firebaseServiceProvider)
          .getPendingVoiceSubmissions(limit: limit);
    });

final voiceValidatorHistoryProvider =
    StreamProvider.family<List<VoiceSubmission>, ValidatorQuery>((ref, query) {
      return ref
          .watch(firebaseServiceProvider)
          .getVoiceValidatorHistory(query.id, limit: query.limit);
    });

final pendingVoiceSubmissionsCountProvider = StreamProvider<int>((ref) {
  return ref.watch(firebaseServiceProvider).getPendingVoiceSubmissionsCount();
});

final urgentQueueProvider = StreamProvider<List<ValidationItem>>((ref) {
  return ref.watch(firebaseServiceProvider).getUrgentQueueItems();
});

final pendingLessonsCountProvider = StreamProvider<int>((ref) {
  return ref.watch(firebaseServiceProvider).getPendingLessonsCount();
});

// ── Community Feed Providers ────────────────────────────────────────────

final communityFeedProvider = StreamProvider<List<CommunityActivity>>((ref) {
  return ref.watch(firebaseServiceProvider).getCommunityFeed();
});



