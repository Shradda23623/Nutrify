import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';

// ── Protocol definitions ──────────────────────────────────────────────────────

enum FastingProtocol {
  sixteenEight,  // 16:8
  eighteenSix,   // 18:6
  twentyFour,    // OMAD 24h
  fiveTwo,       // 5:2
}

class FastingProtocolInfo {
  final FastingProtocol protocol;
  final String name;
  final String description;
  final int fastHours;
  final int eatHours;
  final String emoji;

  const FastingProtocolInfo({
    required this.protocol,
    required this.name,
    required this.description,
    required this.fastHours,
    required this.eatHours,
    required this.emoji,
  });
}

const List<FastingProtocolInfo> fastingProtocols = [
  FastingProtocolInfo(
    protocol: FastingProtocol.sixteenEight,
    name: '16:8',
    description: 'Fast 16 h, eat within an 8-h window. Most popular method.',
    fastHours: 16, eatHours: 8, emoji: '⏰',
  ),
  FastingProtocolInfo(
    protocol: FastingProtocol.eighteenSix,
    name: '18:6',
    description: 'Fast 18 h, eat within a 6-h window. Stronger fat burn.',
    fastHours: 18, eatHours: 6, emoji: '🔥',
  ),
  FastingProtocolInfo(
    protocol: FastingProtocol.twentyFour,
    name: 'OMAD',
    description: 'One meal a day — 23-h fast. Advanced practitioners only.',
    fastHours: 23, eatHours: 1, emoji: '💪',
  ),
  FastingProtocolInfo(
    protocol: FastingProtocol.fiveTwo,
    name: '5:2',
    description: 'Eat normally 5 days, restrict to ~500 kcal on 2 days.',
    fastHours: 0, eatHours: 0, emoji: '📅',
  ),
];

// ── FastingSession model ──────────────────────────────────────────────────────

class FastingSession {
  final FastingProtocol protocol;
  final DateTime startTime;
  final DateTime? endTime;
  final bool completed;

  FastingSession({
    required this.protocol,
    required this.startTime,
    this.endTime,
    this.completed = false,
  });

  Duration get elapsed =>
      (endTime ?? DateTime.now()).difference(startTime);

  Map<String, dynamic> toMap() => {
        'protocol':  protocol.index,
        'startTime': startTime.toIso8601String(),
        'endTime':   endTime?.toIso8601String(),
        'completed': completed,
      };

  factory FastingSession.fromMap(Map<String, dynamic> m) => FastingSession(
        protocol:  FastingProtocol.values[m['protocol'] ?? 0],
        startTime: DateTime.parse(m['startTime'] as String),
        endTime:   m['endTime'] != null
            ? DateTime.parse(m['endTime'] as String)
            : null,
        completed: m['completed'] as bool? ?? false,
      );
}

// ── Service ───────────────────────────────────────────────────────────────────

/// Paths:
///   users/{uid}/fasting/_active  → current active session doc
///   users/{uid}/fasting/{auto}   → completed/archived sessions
class FastingService {
  DocumentReference<Map<String, dynamic>> get _activeDoc =>
      FirestoreService.userDoc.collection('fasting').doc('_active');

  CollectionReference<Map<String, dynamic>> get _col =>
      FirestoreService.collection('fasting');

  // ── Active session ─────────────────────────────────────────────────────────

  Future<FastingSession?> getActiveSession() async {
    try {
      final doc = await _activeDoc.get();
      if (!doc.exists || doc.data() == null) return null;
      return FastingSession.fromMap(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  Future<void> startSession(FastingProtocol protocol) async {
    final session =
        FastingSession(protocol: protocol, startTime: DateTime.now());
    await _activeDoc.set(session.toMap());
  }

  Future<FastingSession?> endSession() async {
    final active = await getActiveSession();
    if (active == null) return null;

    final info     = fastingProtocols
        .firstWhere((p) => p.protocol == active.protocol);
    final elapsedH = DateTime.now().difference(active.startTime).inHours;
    final done     = elapsedH >= info.fastHours;

    final ended = FastingSession(
      protocol:  active.protocol,
      startTime: active.startTime,
      endTime:   DateTime.now(),
      completed: done,
    );

    await _col.add({
      ...ended.toMap(),
      'archivedAt': FirestoreService.serverTimestamp,
    });
    await _activeDoc.delete();
    return ended;
  }

  // ── History ────────────────────────────────────────────────────────────────

  Future<List<FastingSession>> getHistory() async {
    try {
      final snap = await _col
          .orderBy('startTime', descending: true)
          .limit(30)
          .get();
      // Exclude the _active pseudo-doc
      return snap.docs
          .where((d) => d.id != '_active')
          .map((d) => FastingSession.fromMap(d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Streak ─────────────────────────────────────────────────────────────────

  Future<int> getStreak() async {
    final history =
        (await getHistory()).where((s) => s.completed).toList();
    if (history.isEmpty) return 0;
    int streak = 1;
    for (int i = 1; i < history.length; i++) {
      final diff =
          history[i - 1].startTime.difference(history[i].startTime).inHours.abs();
      if (diff <= 48) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ── Real-time active stream ────────────────────────────────────────────────

  Stream<FastingSession?> activeStream() {
    return _activeDoc.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return FastingSession.fromMap(snap.data()!);
    });
  }
}
