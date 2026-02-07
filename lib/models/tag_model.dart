/// Model class for representing a tag
/// Tags are used to categorize posts and help users discover content
class Tag {
  final String id;
  final String name;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Tag({
    required this.id,
    required this.name,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor for creating Tag from JSON
  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  /// Convert Tag to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Tag(id: $id, name: $name, priority: $priority)';
  }
}
