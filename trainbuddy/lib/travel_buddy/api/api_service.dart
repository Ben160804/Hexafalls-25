
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'http://traindelaybackend-production.up.railway.app/api/';


Future<Map<String, dynamic>> fetchTrainDelaySchedule({
  required String trainName,
  required String trainNumber,
  required String date,
}) async {
  final String url =
      'http://traindelaybackend-production.up.railway.app/api/train-schedule?train_name=${Uri.encodeComponent(trainName)}&train_number=$trainNumber&date=$date';
  try {
    debugPrint('🌐 Delay API Request URL: $url');
    final response = await http.get(Uri.parse(url));
    debugPrint('📥 Delay API Response Status Code: ${response.statusCode}');
    debugPrint('📥 Delay API Response Body: ${response.body}');
    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          return {
            'schedule': jsonResponse['data']['schedule'] as List<dynamic>,
            'train_name': trainName,
            'train_number': trainNumber,
            'train_info': jsonResponse['data']['train_info']
          };
        } else {
          throw Exception('Failed to fetch delay data.');
        }
      } catch (e) {
        debugPrint('❌ Delay JSON Parsing Error: $e');
        throw Exception('Sorry, we could not process the delay data. Please try again.');
      }
    } else if (response.statusCode == 404) {
      throw Exception('No delay data found for this train.');
    } else {
      throw Exception('Failed to fetch delay data: ${response.statusCode}');
    }
  } on http.ClientException catch (e) {
    throw Exception('Network error: Unable to connect to the delay server.');
  } on FormatException catch (e) {
    debugPrint('❌ Format Error: $e');
    throw Exception('Received invalid delay data from the server.');
  } catch (e) {
    throw Exception('An unexpected error occurred while fetching delay data.');
  }
}
}
