import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hosla/core/constants/api_constants.dart';
import 'package:hosla/models/tag_model.dart';
import 'package:hosla/services/api_client.dart';

/// Service class for handling tag-related API calls
class TagService {
  final ApiClient _api = ApiClient.instance;

  /// Fetch all available tags from the server
  ///
  /// Returns a list of tags ordered by priority (DESC) then name
  /// Throws an exception if the request fails
  Future<List<Tag>> fetchTags() async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.tagsEndpoint}',
      );
      debugPrint('[TagService] fetchTags() → GET $url');

      final response = await _api
          .get(url)
          .timeout(
            ApiConstants.timeout,
            onTimeout: () => throw Exception('Request timed out'),
          );

      debugPrint(
        '[TagService] response status=${response.statusCode} '
        'body=${response.body}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Check if response is successful
        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'] as Map<String, dynamic>?;
          final tagsList = data?['tags'] as List?;

          if (tagsList != null) {
            debugPrint('[TagService] parsed ${tagsList.length} tags');
            // Parse each tag from JSON
            return tagsList
                .map((tagJson) => Tag.fromJson(tagJson as Map<String, dynamic>))
                .toList();
          }
        }

        throw Exception('Invalid response format');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please log in again.');
      } else {
        throw Exception('Failed to load tags: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[TagService] fetchTags ERROR: $e');
      // Re-throw with context
      throw Exception('Error fetching tags: $e');
    }
  }
}
