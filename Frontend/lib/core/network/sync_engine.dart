import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncState {
  final bool isOnline;
  final int pendingCount;
  final DateTime? lastSyncTime;

  SyncState({
    required this.isOnline,
    required this.pendingCount,
    this.lastSyncTime,
  });

  SyncState copyWith({
    bool? isOnline,
    int? pendingCount,
    DateTime? lastSyncTime,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier()
      : super(SyncState(isOnline: true, pendingCount: 0, lastSyncTime: DateTime.now()));

  void addPendingTx(Map<String, dynamic> tx) {
    state = state.copyWith(pendingCount: state.pendingCount + 1);
  }

  void triggerSync() {
    state = state.copyWith(
      pendingCount: 0,
      lastSyncTime: DateTime.now(),
      isOnline: true,
    );
  }

  void toggleOnlineStatus(bool online) {
    state = state.copyWith(isOnline: online);
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier();
});
