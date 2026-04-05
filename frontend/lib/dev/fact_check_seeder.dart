import 'dart:developer';
import 'dart:math' hide log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:news_lab/core/constants/constants.dart';

/// Developer utility — seeds realistic fake fact-check data for every article
/// in Firestore that doesn't already have a fact_checks document.
class FactCheckSeeder {
  final FirebaseFirestore _firestore;
  final _rng = Random();

  FactCheckSeeder(this._firestore);

  Future<void> seedMissing() async {
    assert(kDebugMode, 'FactCheckSeeder must not run in production');
    final articles = await _firestore.collection(articlesCollection).get();
    if (articles.docs.isEmpty) return;

    final factCheckRefs = articles.docs
        .map((a) => _firestore.collection(factChecksCollection).doc(a.id))
        .toList();

    final existing = await Future.wait(factCheckRefs.map((r) => r.get()));

    final batch = _firestore.batch();
    var seeded = 0;

    for (var i = 0; i < articles.docs.length; i++) {
      if (existing[i].exists) continue;

      final data = <String, dynamic>{};

      if (_rng.nextBool()) {
        data['botCheck'] = {
          'flaggedSentencesPercent': _rand(0.05, 0.65),
          'confidenceScore': _rand(0.60, 0.98),
          'checkedAt': Timestamp.now(),
        };
      }

      final accurate = _rng.nextInt(80);
      final inaccurate = _rng.nextInt(30);
      final unsure = _rng.nextInt(20);
      data['communityCheck'] = {
        'accurateVotes': accurate,
        'inaccurateVotes': inaccurate,
        'unsureVotes': unsure,
      };

      batch.set(factCheckRefs[i], data);
      seeded++;
    }

    if (seeded > 0) {
      await batch.commit();
      log('[FactCheckSeeder] Seeded $seeded article(s).');
    } else {
      log('[FactCheckSeeder] All articles already have fact-check data.');
    }
  }

  double _rand(double min, double max) {
    final raw = min + _rng.nextDouble() * (max - min);
    return double.parse(raw.toStringAsFixed(2));
  }
}
