class BudgetCategory {
  const BudgetCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.monthlyLimit,
    this.archived = false,
  });

  final int id;
  final String name;
  final String icon;
  final double monthlyLimit;
  final bool archived;

  factory BudgetCategory.fromMap(Map<String, Object?> map) => BudgetCategory(
        id: map['id'] as int,
        name: map['name'] as String,
        icon: map['icon'] as String,
        monthlyLimit: (map['monthly_limit'] as num).toDouble(),
        archived: (map['archived'] as int? ?? 0) == 1,
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'icon': icon,
        'monthly_limit': monthlyLimit,
        'archived': archived ? 1 : 0,
      };
}
