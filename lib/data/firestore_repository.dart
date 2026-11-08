import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/models/track_point.dart';
import 'tracking_repository.dart';

/// Real Firebase Firestore backend repository (Decision 11).
/// Uses collection `live/{deviceId}` = latest point only.
/// Saves `ttl` field = ts + 24 hours.
class FirestoreRepository implements TrackingRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  bool get isMock => false;

  /// Ensures anonymous authentication is active.
  Future<void> ensureAuthenticated() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  @override
  Stream<List<TrackPoint>> watchActivePoints(String routeId) {
    return _firestore
        .collection('live')
        .where('routeId', isEqualTo: routeId)
        .snapshots()
        .map((snapshot) {
      final points = <TrackPoint>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          points.add(TrackPoint.fromJson(data));
        } catch (e) {
          debugPrint('Error parsing Firestore live doc ${doc.id}: $e');
        }
      }
      return points;
    });
  }

  @override
  Future<void> sendTrackPoint(TrackPoint point) async {
    await ensureAuthenticated();
    final docRef = _firestore.collection('live').doc(point.deviceId);

    final payload = point.toJson();
    // Decision 11: ttl field = ts + 24h
    payload['ttl'] = point.ts.toUtc().add(const Duration(hours: 24)).toIso8601String();

    await docRef.set(payload, SetOptions(merge: true));
  }

  @override
  Future<void> sendBufferedPoints(List<TrackPoint> points) async {
    if (points.isEmpty) return;
    await ensureAuthenticated();

    // Group by deviceId so we only send the newest point per device
    // in the live collection, avoiding unnecessary writes (Decision 11)
    final Map<String, TrackPoint> latestPerDevice = {};
    for (final p in points) {
      final existing = latestPerDevice[p.deviceId];
      if (existing == null || p.ts.isAfter(existing.ts)) {
        latestPerDevice[p.deviceId] = p;
      }
    }

    final batch = _firestore.batch();
    for (final point in latestPerDevice.values) {
      final docRef = _firestore.collection('live').doc(point.deviceId);
      final payload = point.toJson();
      payload['ttl'] = point.ts.toUtc().add(const Duration(hours: 24)).toIso8601String();
      batch.set(docRef, payload, SetOptions(merge: true));
    }
    await batch.commit();
  }

  @override
  void dispose() {
    // Firestore streams manage their own lifecycle
  }
}
