import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/simple_sync_service.dart';

/// 同步服务提供者
final syncServiceProvider = Provider<SimpleSyncService>((ref) {
  return SimpleSyncService();
});

/// 同步状态提供者
final syncStatusProvider = Provider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.syncStatus;
});

/// 是否已配置同步提供者
final isSyncConfiguredProvider = Provider<bool>((ref) {
  final syncStatus = ref.watch(syncStatusProvider);
  return syncStatus.isConfigured;
});

/// 自动同步状态提供者
final autoSyncEnabledProvider = Provider<bool>((ref) {
  final syncStatus = ref.watch(syncStatusProvider);
  return syncStatus.autoSyncEnabled;
});

/// 同步进度提供者（用于显示同步状态）
final syncProgressProvider = StateNotifierProvider<SyncProgressNotifier, SyncProgress>((ref) {
  return SyncProgressNotifier(ref);
});

/// 同步进度通知器
class SyncProgressNotifier extends StateNotifier<SyncProgress> {
  final Ref ref;

  SyncProgressNotifier(this.ref) : super(const SyncProgress());

  /// 开始同步
  void startSync() {
    state = state.copyWith(
      isSyncing: true,
      error: null,
    );
  }

  /// 完成同步
  void completeSync({int? downloadedCount, int? uploadedCount}) {
    state = state.copyWith(
      isSyncing: false,
      downloadedCount: downloadedCount,
      uploadedCount: uploadedCount,
      lastSyncTime: DateTime.now(),
      error: null,
    );

    // 3秒后重置计数器
    Future.delayed(const Duration(seconds: 3), () {
      if (state.isSyncing == false) {
        state = state.copyWith(
          downloadedCount: null,
          uploadedCount: null,
        );
      }
    });
  }

  /// 同步失败
  void syncFailed(String error) {
    state = state.copyWith(
      isSyncing: false,
      error: error,
    );
  }

  /// 重置进度
  void reset() {
    state = const SyncProgress();
  }
}

/// 同步进度数据类
class SyncProgress {
  final bool isSyncing;
  final int? downloadedCount;
  final int? uploadedCount;
  final DateTime? lastSyncTime;
  final String? error;

  const SyncProgress({
    this.isSyncing = false,
    this.downloadedCount,
    this.uploadedCount,
    this.lastSyncTime,
    this.error,
  });

  SyncProgress copyWith({
    bool? isSyncing,
    int? downloadedCount,
    int? uploadedCount,
    DateTime? lastSyncTime,
    String? error,
  }) {
    return SyncProgress(
      isSyncing: isSyncing ?? this.isSyncing,
      downloadedCount: downloadedCount ?? this.downloadedCount,
      uploadedCount: uploadedCount ?? this.uploadedCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncProgress &&
        other.isSyncing == isSyncing &&
        other.downloadedCount == downloadedCount &&
        other.uploadedCount == uploadedCount &&
        other.lastSyncTime == lastSyncTime &&
        other.error == error;
  }

  @override
  int get hashCode {
    return isSyncing.hashCode ^
        downloadedCount.hashCode ^
        uploadedCount.hashCode ^
        lastSyncTime.hashCode ^
        error.hashCode;
  }
}