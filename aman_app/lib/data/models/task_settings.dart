class TaskSettings {
  const TaskSettings({
    required this.id,
    required this.telecomCompanyId,
    required this.taskAmount,
    required this.recurrenceDays,
    required this.dueDateRule,
    required this.upcomingDays,
  });

  final String id;
  final String telecomCompanyId;
  final num taskAmount;
  final int recurrenceDays;
  final String dueDateRule;
  final int upcomingDays;

  factory TaskSettings.fromJson(Map<String, dynamic> json) {
    return TaskSettings(
      id: json['id'] as String,
      telecomCompanyId: json['telecom_company_id'] as String,
      taskAmount: json['task_amount'] as num,
      recurrenceDays: json['recurrence_days'] as int,
      dueDateRule: json['due_date_rule'] as String? ?? 'acceptance_date',
      upcomingDays: json['upcoming_days'] as int? ?? 7,
    );
  }
}
