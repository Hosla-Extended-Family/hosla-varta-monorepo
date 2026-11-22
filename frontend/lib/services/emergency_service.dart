import 'dart:convert';

import 'package:hosla/core/constants/api_constants.dart';
import 'package:hosla/services/api_client.dart';

/// Result of an emergency log request.
class EmergencyResult {
  final bool success;
  final String? errorMessage;

  const EmergencyResult({required this.success, this.errorMessage});
}

/// Possible emergency button types that can be reported.
enum EmergencyType { fire, medical, police, hosla, other }

extension EmergencyTypeValue on EmergencyType {
  String get apiValue {
    switch (this) {
      case EmergencyType.fire:
        return 'fire';
      case EmergencyType.medical:
        return 'medical';
      case EmergencyType.police:
        return 'police';
      case EmergencyType.hosla:
        return 'hosla';
      case EmergencyType.other:
        return 'other';
    }
  }
}

class EmergencyService {
  EmergencyService._internal();
  static final EmergencyService instance = EmergencyService._internal();

  /// Logs an emergency with the backend.
  ///
  /// POST /api/emergency/log
  /// Body: { "button": "<type>" }
  Future<EmergencyResult> logEmergency(EmergencyType type) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.emergencyEndpoint}',
      );

      final response = await ApiClient.instance
          .post(uri, body: jsonEncode({'button': type.apiValue}))
          .timeout(ApiConstants.timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const EmergencyResult(success: true);
      }

      return EmergencyResult(
        success: false,
        errorMessage: 'Unable to send emergency request. Please try again.',
      );
    } catch (_) {
      return const EmergencyResult(
        success: false,
        errorMessage: 'Unable to send emergency request. Please try again.',
      );
    }
  }
}
