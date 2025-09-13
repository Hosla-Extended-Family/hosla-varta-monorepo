import 'package:riverpod/riverpod.dart';
import 'package:hosla/models/event_model.dart';
import 'package:hosla/services/event_service.dart';

/// Provider for EventService instance
final eventServiceProvider = Provider<EventService>((ref) => EventService());

/// Provider for list of events
final eventsProvider = StateNotifierProvider<EventsNotifier, List<Event>>((ref) {
  return EventsNotifier(ref.read(eventServiceProvider));
});

/// Provider for user's event preferences
final userEventPreferencesProvider = StateNotifierProvider<UserEventPreferencesNotifier, Map<String, EventStatus>>((ref) {
  return UserEventPreferencesNotifier(ref.read(eventServiceProvider));
});

/// Notifier for managing events list
class EventsNotifier extends StateNotifier<List<Event>> {
  final EventService _eventService;

  EventsNotifier(this._eventService) : super([]) {
    loadEvents();
  }

  /// Load all events
  Future<void> loadEvents() async {
    try {
      // TODO: Implement API call
      final events = await _eventService.getEvents();
      state = events;
    } catch (e) {
      print('Error loading events: $e');
    }
  }

  /// Create a new event
  Future<void> createEvent(Event event) async {
    try {
      // TODO: Implement API call
      await _eventService.createEvent(event);
      state = [...state, event];
    } catch (e) {
      print('Error creating event: $e');
    }
  }

  /// Update an existing event
  Future<void> updateEvent(Event updatedEvent) async {
    try {
      // TODO: Implement API call
      await _eventService.updateEvent(updatedEvent);
      state = state.map((event) {
        return event.id == updatedEvent.id ? updatedEvent : event;
      }).toList();
    } catch (e) {
      print('Error updating event: $e');
    }
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      // TODO: Implement API call
      await _eventService.deleteEvent(eventId);
      state = state.where((event) => event.id != eventId).toList();
    } catch (e) {
      print('Error deleting event: $e');
    }
  }

  /// Search events by query
  Future<void> searchEvents(String query) async {
    try {
      // TODO: Implement API call
      final events = await _eventService.searchEvents(query);
      state = events;
    } catch (e) {
      print('Error searching events: $e');
    }
  }

  /// Filter events by category/tag
  void filterEventsByTag(String tag) {
    if (tag.isEmpty) {
      loadEvents();
      return;
    }
    
    state = state.where((event) => 
      event.tags.any((eventTag) => 
        eventTag.toLowerCase().contains(tag.toLowerCase())
      )
    ).toList();
  }
}

/// Notifier for managing user's event preferences (interested/going)
class UserEventPreferencesNotifier extends StateNotifier<Map<String, EventStatus>> {
  final EventService _eventService;

  UserEventPreferencesNotifier(this._eventService) : super({}) {
    loadUserPreferences();
  }

  /// Load user's event preferences
  Future<void> loadUserPreferences() async {
    try {
      // TODO: Implement API call
      final preferences = await _eventService.getUserEventPreferences();
      state = preferences;
    } catch (e) {
      print('Error loading user preferences: $e');
    }
  }

  /// Mark user as interested in an event
  Future<void> markInterested(String eventId) async {
    try {
      // TODO: Implement API call
      await _eventService.markUserInterested(eventId);
      state = {...state, eventId: EventStatus.interested};
    } catch (e) {
      print('Error marking as interested: $e');
    }
  }

  /// Mark user as going to an event
  Future<void> markGoing(String eventId) async {
    try {
      // TODO: Implement API call
      await _eventService.markUserGoing(eventId);
      state = {...state, eventId: EventStatus.going};
    } catch (e) {
      print('Error marking as going: $e');
    }
  }

  /// Remove user from event (not going)
  Future<void> removeFromEvent(String eventId) async {
    try {
      // TODO: Implement API call
      await _eventService.removeUserFromEvent(eventId);
      state = {...state, eventId: EventStatus.notGoing};
    } catch (e) {
      print('Error removing from event: $e');
    }
  }

  /// Get user's status for a specific event
  EventStatus? getUserEventStatus(String eventId) {
    return state[eventId];
  }
}
