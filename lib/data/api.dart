import 'dart:math';

import '../models/inspection.dart';

/// What sending an inspection actually did.
enum SendResult { accepted, unreachable, rejected }

/// Stands in for the real backend.
///
/// The app is about what happens when the network is unreliable, so the fake
/// is unreliable on purpose — the interesting paths are the ones a happy-path
/// stub would never exercise.
class InspectionApi {
  InspectionApi({Random? random, this.failureRate = 0.35})
      : _random = random ?? Random();

  final Random _random;

  /// Share of attempts that fail to reach the server.
  final double failureRate;

  Future<SendResult> send(Inspection inspection) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    // An inspection with no site can never be accepted, however many times it
    // is retried — the queue needs to be told that so it stops trying.
    if (inspection.site.trim().isEmpty) return SendResult.rejected;

    return _random.nextDouble() < failureRate
        ? SendResult.unreachable
        : SendResult.accepted;
  }
}
