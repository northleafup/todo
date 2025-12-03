import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/file_picker_sync_service.dart';

/// 文件同步服务提供者
final fileSyncServiceProvider = Provider<FilePickerSyncService>((ref) {
  final service = FilePickerSyncService();
  // 初始化服务
  service.initialize();
  return service;
});

/// 文件同步状态提供者
final fileSyncStatusProvider = Provider<SyncFolderStatus>((ref) {
  final syncService = ref.watch(fileSyncServiceProvider);
  return syncService.folderStatus;
});

/// 是否已配置文件同步提供者
final isFileSyncConfiguredProvider = Provider<bool>((ref) {
  final syncStatus = ref.watch(fileSyncStatusProvider);
  return syncStatus.isConfigured;
});

/// 文件同步是否可用提供者
final isFileSyncAvailableProvider = Provider<bool>((ref) {
  final syncStatus = ref.watch(fileSyncStatusProvider);
  return syncStatus.isConfigured && syncStatus.isAccessible;
});

/// 自动同步状态提供者
final autoFileSyncEnabledProvider = Provider<bool>((ref) {
  final syncStatus = ref.watch(fileSyncStatusProvider);
  return syncStatus.autoSyncEnabled;
});

/// 文件同步进度提供者（用于显示同步状态）
final fileSyncProgressProvider = StateNotifierProvider<FileSyncProgressNotifier, FileSyncProgress>((ref) {
  return FileSyncProgressNotifier(ref);
});

/// 文件同步进度通知器
class FileSyncProgressNotifier extends StateNotifier<FileSyncProgress> {
  final Ref ref;

  FileSyncProgressNotifier(this.ref) : super(const FileSyncProgress());

  /// 开始同步
  void startSync({SyncOperation? operation}) {
    state = state.copyWith(
      isSyncing: true,
      operation: operation,
      error: null,
    );
  }

  /// 完成同步
  void completeSync({SyncOperation? operation, int? fileSize, String? message}) {
    state = state.copyWith(
      isSyncing: false,
      operation: operation,
      fileSize: fileSize,
      message: message,
      lastSyncTime: DateTime.now(),
      error: null,
    );

    // 3秒后重置状态
    Future.delayed(const Duration(seconds: 3), () {
      if (state.isSyncing == false) {
        state = state.copyWith(
          operation: null,
          fileSize: null,
          message: null,
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
    state = const FileSyncProgress();
  }
}

/// 文件同步进度数据类
class FileSyncProgress {
  final bool isSyncing;
  final SyncOperation? operation;
  final int? fileSize;
  final DateTime? lastSyncTime;
  final String? message;
  final String? error;

  const FileSyncProgress({
    this.isSyncing = false,
    this.operation,
    this.fileSize,
    this.lastSyncTime,
    this.message,
    this.error,
  });

  FileSyncProgress copyWith({
    bool? isSyncing,
    SyncOperation? operation,
    int? fileSize,
    DateTime? lastSyncTime,
    String? message,
    String? error,
  }) {
    return FileSyncProgress(
      isSyncing: isSyncing ?? this.isSyncing,
      operation: operation ?? this.operation,
      fileSize: fileSize ?? this.fileSize,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      message: message ?? this.message,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileSyncProgress &&
        other.isSyncing == isSyncing &&
        other.operation == operation &&
        other.fileSize == fileSize &&
        other.lastSyncTime == lastSyncTime &&
        other.message == message &&
        other.error == error;
  }

  @override
  int get hashCode {
    return isSyncing.hashCode ^
        operation.hashCode ^
        fileSize.hashCode ^
        lastSyncTime.hashCode ^
        message.hashCode ^
        error.hashCode;
  }
}