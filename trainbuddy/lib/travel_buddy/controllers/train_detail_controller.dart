import 'package:get/get.dart';
import 'dart:developer' as developer;

import '../api/api_service.dart';
import '../models/train_model.dart';

class TrainDetailsController extends GetxController {
  final ApiService _apiService = ApiService();

  final Rx<TrainDetails?> trainDetails = Rx<TrainDetails?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  Future<void> fetchTrainDetails({
    required String trainName,
    required String trainNumber,
    required String date,
  }) async {
    try {
      print('🚂 Fetching train details for: Train: $trainName, Number: $trainNumber, Date: $date');

      isLoading.value = true;
      errorMessage.value = '';

      final response = await _apiService.fetchTrainDelaySchedule(
        trainName: trainName,
        trainNumber: trainNumber,
        date: date,
      );

      print('📥 Response received: ${response != null}');

      if (response == null) {
        throw Exception('No response received from the server');
      }

      print('🔑 Response keys: ${response.keys.toList()}');

      // Validate required fields
      if (!response.containsKey('schedule') || !response.containsKey('train_info')) {
        print('❌ Missing required fields. Available keys: ${response.keys.toList()}');
        throw Exception('Invalid response format: missing required fields');
      }

      // Structure the response to match our model
      final structuredResponse = {
        'status': response['status'] ?? 'error',  // Use status from API or default to error
        'data': {
          'schedule': response['schedule'],
          'train_info': response['train_info']
        }
      };

      try {
        final details = TrainDetails.fromJson(structuredResponse);

        if (details.data == null) {
          throw Exception('Failed to parse train details');
        }

        if (details.data!.schedule.isEmpty) {
          throw Exception('No stations found in schedule');
        }

        trainDetails.value = details;

        print('✅ Successfully parsed schedule with ${details.data!.schedule.length} stations');

      } catch (e, stackTrace) {
        print('❌ Parsing error: $e\nStack trace: $stackTrace');
        throw Exception('Failed to process train details: $e');
      }
    } catch (e) {
      print('❌ Error: $e');
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  void clearDetails() {
    trainDetails.value = null;
    errorMessage.value = '';
    developer.log(
      'Cleared train details',
      name: 'TrainDetailsController',
    );
  }
}