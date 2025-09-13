/// Event status for user participation
enum EventStatus { interested, going, notGoing }

/// Event model for events management
class Event {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime startTime;
  final DateTime? endTime;
  final String location;
  final String? address;
  final String organizerId;
  final List<String> interestedUserIds;
  final List<String> goingUserIds;
  final int maxParticipants;
  final bool isPublic;
  final List<String> tags;
  final double? latitude;
  final double? longitude;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.startTime,
    this.endTime,
    required this.location,
    this.address,
    required this.organizerId,
    this.interestedUserIds = const [],
    this.goingUserIds = const [],
    this.maxParticipants = 0,
    this.isPublic = true,
    this.tags = const [],
    this.latitude,
    this.longitude,
  });

  /// Factory constructor for creating Event from JSON
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      location: json['location'] ?? '',
      address: json['address'],
      organizerId: json['organizerId'] ?? '',
      interestedUserIds: List<String>.from(json['interestedUserIds'] ?? []),
      goingUserIds: List<String>.from(json['goingUserIds'] ?? []),
      maxParticipants: json['maxParticipants'] ?? 0,
      isPublic: json['isPublic'] ?? true,
      tags: List<String>.from(json['tags'] ?? []),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  /// Convert Event to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'location': location,
      'address': address,
      'organizerId': organizerId,
      'interestedUserIds': interestedUserIds,
      'goingUserIds': goingUserIds,
      'maxParticipants': maxParticipants,
      'isPublic': isPublic,
      'tags': tags,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Create a copy of Event with updated fields
  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? address,
    String? organizerId,
    List<String>? interestedUserIds,
    List<String>? goingUserIds,
    int? maxParticipants,
    bool? isPublic,
    List<String>? tags,
    double? latitude,
    double? longitude,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      address: address ?? this.address,
      organizerId: organizerId ?? this.organizerId,
      interestedUserIds: interestedUserIds ?? this.interestedUserIds,
      goingUserIds: goingUserIds ?? this.goingUserIds,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  /// Check if user is interested in this event
  bool isUserInterested(String userId) {
    return interestedUserIds.contains(userId);
  }

  /// Check if user is going to this event
  bool isUserGoing(String userId) {
    return goingUserIds.contains(userId);
  }

  /// Get total participant count
  int get totalParticipants => goingUserIds.length;

  /// Check if event is full
  bool get isFull => maxParticipants > 0 && totalParticipants >= maxParticipants;

  /// Check if event has started
  bool get hasStarted => DateTime.now().isAfter(startTime);

  /// Check if event has ended
  bool get hasEnded => endTime != null && DateTime.now().isAfter(endTime!);

  /// Get formatted date string
  String get formattedDate {
    final now = DateTime.now();
    final eventDate = startTime;
    
    if (eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day) {
      return 'Today';
    } else if (eventDate.year == now.year &&
               eventDate.month == now.month &&
               eventDate.day == now.day + 1) {
      return 'Tomorrow';
    } else {
      return '${eventDate.day}/${eventDate.month}/${eventDate.year}';
    }
  }

  /// Get formatted time string
  String get formattedTime {
    final hour = startTime.hour;
    final minute = startTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}
