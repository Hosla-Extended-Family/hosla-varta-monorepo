import 'package:hosla/models/event_model.dart';

/// Service class for handling event-related API calls and data management
class EventService {
  // TODO: Add HTTP client dependency injection
  // final http.Client _httpClient;
  
  /// Dummy data for testing - replace with actual API calls
  static final List<Event> _dummyEvents = [
    Event(
      id: '1',
      title: 'Tech Meetup 2024',
      description: 'Join us for an exciting tech meetup featuring the latest trends in mobile development, AI, and web technologies. Network with fellow developers and learn from industry experts.',
      imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400&h=300&fit=crop',
      startTime: DateTime.now().add(const Duration(days: 3)),
      endTime: DateTime.now().add(const Duration(days: 3, hours: 4)),
      location: 'Tech Hub Convention Center',
      address: '123 Innovation Street, Tech City, TC 12345',
      organizerId: 'org_1',
      interestedUserIds: ['user_1', 'user_2', 'user_3'],
      goingUserIds: ['user_1', 'user_4'],
      maxParticipants: 100,
      tags: ['Technology', 'Networking', 'Programming'],
      latitude: 37.7749,
      longitude: -122.4194,
    ),
    Event(
      id: '2',
      title: 'Community Clean-up Drive',
      description: 'Help make our community cleaner and greener! Join our monthly clean-up drive. We\'ll provide all necessary supplies including gloves, bags, and refreshments.',
      imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=400&h=300&fit=crop',
      startTime: DateTime.now().add(const Duration(days: 7)),
      endTime: DateTime.now().add(const Duration(days: 7, hours: 3)),
      location: 'Central Park',
      address: 'Central Park, Green Valley, GV 67890',
      organizerId: 'org_2',
      interestedUserIds: ['user_2', 'user_3', 'user_5'],
      goingUserIds: ['user_2', 'user_3'],
      maxParticipants: 50,
      tags: ['Community', 'Environment', 'Volunteer'],
      latitude: 40.7829,
      longitude: -73.9654,
    ),
    Event(
      id: '3',
      title: 'Photography Workshop',
      description: 'Learn the basics of photography from professional photographers. Bring your camera or smartphone and discover techniques for capturing stunning photos.',
      imageUrl: 'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=400&h=300&fit=crop',
      startTime: DateTime.now().add(const Duration(days: 14)),
      endTime: DateTime.now().add(const Duration(days: 14, hours: 2)),
      location: 'Art Studio Downtown',
      address: '456 Creative Avenue, Art District, AD 13579',
      organizerId: 'org_3',
      interestedUserIds: ['user_1', 'user_4', 'user_6'],
      goingUserIds: ['user_4'],
      maxParticipants: 20,
      tags: ['Photography', 'Art', 'Workshop'],
      latitude: 34.0522,
      longitude: -118.2437,
    ),
    Event(
      id: '4',
      title: 'Startup Pitch Night',
      description: 'Calling all entrepreneurs! Present your startup ideas to a panel of investors and industry experts. Great networking opportunities and potential funding.',
      imageUrl: 'https://images.unsplash.com/photo-1559136555-9303baea8ebd?w=400&h=300&fit=crop',
      startTime: DateTime.now().add(const Duration(days: 21)),
      endTime: DateTime.now().add(const Duration(days: 21, hours: 3)),
      location: 'Entrepreneur Hub',
      address: '789 Startup Lane, Business District, BD 24680',
      organizerId: 'org_4',
      interestedUserIds: ['user_3', 'user_5', 'user_7'],
      goingUserIds: ['user_3', 'user_5'],
      maxParticipants: 75,
      tags: ['Startup', 'Business', 'Networking', 'Pitch'],
      latitude: 41.8781,
      longitude: -87.6298,
    ),
    Event(
      id: '5',
      title: 'Yoga in the Park',
      description: 'Start your weekend with a peaceful yoga session in the beautiful surroundings of nature. Suitable for all levels. Bring your own mat.',
      imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&h=300&fit=crop',
      startTime: DateTime.now().add(const Duration(days: 2)),
      endTime: DateTime.now().add(const Duration(days: 2, hours: 1)),
      location: 'Riverside Park',
      address: 'Riverside Park, Wellness District, WD 97531',
      organizerId: 'org_5',
      interestedUserIds: ['user_2', 'user_6', 'user_8'],
      goingUserIds: ['user_6', 'user_8'],
      maxParticipants: 30,
      tags: ['Yoga', 'Wellness', 'Outdoor'],
      latitude: 40.7589,
      longitude: -73.9851,
    ),
    Event(
      id: '6',
      title: 'Book Club Meeting',
      description: 'Join our monthly book club discussion. This month we\'re reading "The Innovation Dilemma" by Clayton Christensen. Coffee and snacks provided.',
      imageUrl: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400&h=300&fit=crop',
      startTime: DateTime.now().add(const Duration(days: 10)),
      endTime: DateTime.now().add(const Duration(days: 10, hours: 2)),
      location: 'City Library',
      address: '321 Knowledge Street, Literary Quarter, LQ 86420',
      organizerId: 'org_6',
      interestedUserIds: ['user_1', 'user_7', 'user_9'],
      goingUserIds: ['user_7'],
      maxParticipants: 15,
      tags: ['Books', 'Literature', 'Discussion'],
      latitude: 42.3601,
      longitude: -71.0589,
    ),
  ];

  /// Get all events
  /// TODO: Implement actual API call
  /// Example: GET /api/events
  Future<List<Event>> getEvents() async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.get(Uri.parse('$baseUrl/events'));
    // if (response.statusCode == 200) {
    //   final List<dynamic> jsonList = json.decode(response.body);
    //   return jsonList.map((json) => Event.fromJson(json)).toList();
    // }
    // throw Exception('Failed to load events');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return _dummyEvents;
  }

  /// Get events by category/tag
  /// TODO: Implement actual API call
  /// Example: GET /api/events?category={category}
  Future<List<Event>> getEventsByCategory(String category) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.get(Uri.parse('$baseUrl/events?category=$category'));
    // if (response.statusCode == 200) {
    //   final List<dynamic> jsonList = json.decode(response.body);
    //   return jsonList.map((json) => Event.fromJson(json)).toList();
    // }
    // throw Exception('Failed to load events by category');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _dummyEvents.where((event) => 
      event.tags.any((tag) => tag.toLowerCase().contains(category.toLowerCase()))
    ).toList();
  }

  /// Search events by title or description
  /// TODO: Implement actual API call
  /// Example: GET /api/events/search?q={query}
  Future<List<Event>> searchEvents(String query) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.get(Uri.parse('$baseUrl/events/search?q=$query'));
    // if (response.statusCode == 200) {
    //   final List<dynamic> jsonList = json.decode(response.body);
    //   return jsonList.map((json) => Event.fromJson(json)).toList();
    // }
    // throw Exception('Failed to search events');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));
    return _dummyEvents.where((event) => 
      event.title.toLowerCase().contains(query.toLowerCase()) ||
      event.description.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  /// Get a specific event by ID
  /// TODO: Implement actual API call
  /// Example: GET /api/events/{eventId}
  Future<Event?> getEvent(String eventId) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.get(Uri.parse('$baseUrl/events/$eventId'));
    // if (response.statusCode == 200) {
    //   return Event.fromJson(json.decode(response.body));
    // } else if (response.statusCode == 404) {
    //   return null;
    // }
    // throw Exception('Failed to load event');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _dummyEvents.firstWhere((event) => event.id == eventId);
    } catch (e) {
      return null;
    }
  }

  /// Create a new event
  /// TODO: Implement actual API call
  /// Example: POST /api/events
  Future<Event> createEvent(Event event) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.post(
    //   Uri.parse('$baseUrl/events'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode(event.toJson()),
    // );
    // if (response.statusCode == 201) {
    //   return Event.fromJson(json.decode(response.body));
    // }
    // throw Exception('Failed to create event');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    return event;
  }

  /// Update an existing event
  /// TODO: Implement actual API call
  /// Example: PUT /api/events/{eventId}
  Future<Event> updateEvent(Event event) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.put(
    //   Uri.parse('$baseUrl/events/${event.id}'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode(event.toJson()),
    // );
    // if (response.statusCode == 200) {
    //   return Event.fromJson(json.decode(response.body));
    // }
    // throw Exception('Failed to update event');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));
    return event;
  }

  /// Delete an event
  /// TODO: Implement actual API call
  /// Example: DELETE /api/events/{eventId}
  Future<void> deleteEvent(String eventId) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.delete(Uri.parse('$baseUrl/events/$eventId'));
    // if (response.statusCode != 204) {
    //   throw Exception('Failed to delete event');
    // }
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Mark user as interested in an event
  /// TODO: Implement actual API call
  /// Example: POST /api/events/{eventId}/interested
  Future<void> markUserInterested(String eventId) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.post(Uri.parse('$baseUrl/events/$eventId/interested'));
    // if (response.statusCode != 200) {
    //   throw Exception('Failed to mark as interested');
    // }
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Mark user as going to an event
  /// TODO: Implement actual API call
  /// Example: POST /api/events/{eventId}/going
  Future<void> markUserGoing(String eventId) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.post(Uri.parse('$baseUrl/events/$eventId/going'));
    // if (response.statusCode != 200) {
    //   throw Exception('Failed to mark as going');
    // }
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Remove user from an event
  /// TODO: Implement actual API call
  /// Example: DELETE /api/events/{eventId}/participation
  Future<void> removeUserFromEvent(String eventId) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.delete(Uri.parse('$baseUrl/events/$eventId/participation'));
    // if (response.statusCode != 200) {
    //   throw Exception('Failed to remove from event');
    // }
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Get user's event preferences (interested/going status for all events)
  /// TODO: Implement actual API call
  /// Example: GET /api/user/event-preferences
  Future<Map<String, EventStatus>> getUserEventPreferences() async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.get(Uri.parse('$baseUrl/user/event-preferences'));
    // if (response.statusCode == 200) {
    //   final Map<String, dynamic> json = json.decode(response.body);
    //   return json.map((key, value) => MapEntry(key, EventStatus.values.firstWhere(
    //     (status) => status.toString().split('.').last == value,
    //   )));
    // }
    // throw Exception('Failed to load user event preferences');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Return dummy preferences
    return {
      '1': EventStatus.interested,
      '2': EventStatus.going,
      '5': EventStatus.going,
    };
  }

  /// Get events user is participating in
  /// TODO: Implement actual API call
  /// Example: GET /api/user/events
  Future<List<Event>> getUserEvents() async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.get(Uri.parse('$baseUrl/user/events'));
    // if (response.statusCode == 200) {
    //   final List<dynamic> jsonList = json.decode(response.body);
    //   return jsonList.map((json) => Event.fromJson(json)).toList();
    // }
    // throw Exception('Failed to load user events');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Return events user is participating in
    return _dummyEvents.where((event) => 
      event.interestedUserIds.contains('current_user') ||
      event.goingUserIds.contains('current_user')
    ).toList();
  }
}
