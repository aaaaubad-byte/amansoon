class OperationalTask {
  const OperationalTask({
    required this.id,
    required this.protectionId,
    required this.taskAmount,
    required this.dueAt,
    required this.cycleNumber,
    required this.status,
    this.completedAt,
  });

  final String id;
  final String protectionId;
  final num taskAmount;
  final DateTime dueAt;
  final int cycleNumber;
  final String status;
  final DateTime? completedAt;

  factory OperationalTask.fromJson(Map<String, dynamic> json) {
    return OperationalTask(
      id: json['id'] as String,
      protectionId: json['protection_id'] as String,
      taskAmount: json['task_amount'] as num,
      dueAt: DateTime.parse(json['due_at'] as String),
      cycleNumber: json['cycle_number'] as int,
      status: json['status'] as String,
      completedAt: json['completed_at'] == null ? null : DateTime.parse(json['completed_at'] as String),
    );
  }
}
