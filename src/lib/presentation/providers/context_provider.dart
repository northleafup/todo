import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// Context提供者（用于获取当前BuildContext）
// 注意：这需要在MaterialApp或CupertinoApp的builder中设置
final contextProvider = Provider<BuildContext>((ref) {
  throw UnimplementedError('Context provider must be overridden in MaterialApp');
});