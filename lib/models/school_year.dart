class SchoolYear {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;

  SchoolYear({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SchoolYear.fromFirestore(Map<String, dynamic> data, String id) {
    return SchoolYear(
      id: id,
      name: data['name'] ?? '',
      startDate: data['startDate'] != null
          ? (data['startDate'] as dynamic).toDate()
          : DateTime.now(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as dynamic).toDate()
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}
