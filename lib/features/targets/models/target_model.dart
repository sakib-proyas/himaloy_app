class TargetModel {
  final int id;
  final String title;
  final String type; // monthly or yearly
  final String? period;
  final double targetAmount;
  final double achievedAmount;
  final double percentage;
  final String? status;

  TargetModel({
    required this.id,
    required this.title,
    required this.type,
    this.period,
    required this.targetAmount,
    required this.achievedAmount,
    required this.percentage,
    this.status,
  });

  factory TargetModel.fromJson(Map<String, dynamic> json) {
    return TargetModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Sales Target',
      type: json['type'] ?? 'monthly',
      period: json['target_month'] ?? json['target_year']?.toString(),
      targetAmount: double.tryParse(json['target_amount']?.toString() ?? '0') ?? 0.0,
      achievedAmount: double.tryParse(json['achieved_amount']?.toString() ?? '0') ?? 0.0,
      percentage: double.tryParse(json['percentage']?.toString() ?? '0') ?? 0.0,
      status: json['status'],
    );
  }
}

