import 'package:hive/hive.dart';

part 'sync_queue.g.dart';

@HiveType(typeId: 12)
class SyncQueueItem extends HiveObject {
  @HiveField(0)
  final String id; // Local unique ID

  @HiveField(1)
  final String action; // 'CREATE', 'UPDATE', 'DELETE'

  @HiveField(2)
  final String entity; // 'PRODUCT', 'CATEGORY', 'TRANSACTION'

  @HiveField(3)
  final Map<String, dynamic> data;

  @HiveField(4)
  final DateTime createdAt;

  SyncQueueItem({
    required this.id,
    required this.action,
    required this.entity,
    required this.data,
    required this.createdAt,
  });
}
