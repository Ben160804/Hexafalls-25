import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../api/api_service.dart';
import '../models/train.dart' as train_model;
import '../models/station.dart';

class TrainFinderController extends GetxController {
  final ApiService _apiService = ApiService();
  
  final sourceNameController = TextEditingController();
  final sourceCodeController = TextEditingController();
  final destinationNameController = TextEditingController();
  final destinationCodeController = TextEditingController();
  final dateController = TextEditingController();

  final isLoading = false.obs;
  final errorMessage = RxnString();
  final trainData = Rxn<train_model.Train>();
  
  // Station data
  final stations = <Station>[].obs;
  final sourceSuggestions = <Station>[].obs;
  final destinationSuggestions = <Station>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadStations();
    _setupListeners();
  }

  void _setupListeners() {
    sourceNameController.addListener(() {
      _updateSourceSuggestions(sourceNameController.text);
    });

    destinationNameController.addListener(() {
      _updateDestinationSuggestions(destinationNameController.text);
    });
  }

  Future<void> _loadStations() async {
    try {
      final jsonString = await rootBundle.loadString('stationcode.json');
      final jsonData = json.decode(jsonString);
      final stationsList = (jsonData['stations'] as List)
          .map((station) => Station.fromJson(station))
          .toList();
      stations.value = stationsList;
    } catch (e) {
      debugPrint('Error loading stations: $e');
      errorMessage.value = 'Failed to load station data';
    }
  }

  void _updateSourceSuggestions(String query) {
    if (query.isEmpty) {
      sourceSuggestions.clear();
      return;
    }
    sourceSuggestions.value = stations
        .where((station) =>
            station.name.toLowerCase().contains(query.toLowerCase()) ||
            station.code.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();
  }

  void _updateDestinationSuggestions(String query) {
    if (query.isEmpty) {
      destinationSuggestions.clear();
      return;
    }
    destinationSuggestions.value = stations
        .where((station) =>
            station.name.toLowerCase().contains(query.toLowerCase()) ||
            station.code.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();
  }

  void selectSourceStation(Station station) {
    sourceNameController.text = station.name;
    sourceCodeController.text = station.code;
    sourceSuggestions.clear();
  }

  void selectDestinationStation(Station station) {
    destinationNameController.text = station.name;
    destinationCodeController.text = station.code;
    destinationSuggestions.clear();
  }

  @override
  void onClose() {
    sourceNameController.dispose();
    sourceCodeController.dispose();
    destinationNameController.dispose();
    destinationCodeController.dispose();
    dateController.dispose();
    super.onClose();
  }

  Future<void> searchTrains() async {
    if (!_validateInputs()) return;

    try {
      isLoading.value = true;
      errorMessage.value = null;

      debugPrint('🔍 Starting train search...');
      debugPrint('📝 Form Data:');
      debugPrint('   Source Name: ${sourceNameController.text}');
      debugPrint('   Source Code: ${sourceCodeController.text}');
      debugPrint('   Destination Name: ${destinationNameController.text}');
      debugPrint('   Destination Code: ${destinationCodeController.text}');
      debugPrint('   Date: ${dateController.text}');

      final result = await _apiService.getTrainsBetweenStations(
        sourceName: sourceNameController.text,
        sourceCode: sourceCodeController.text,
        destinationName: destinationNameController.text,
        destinationCode: destinationCodeController.text,
        date: dateController.text,
      );

      debugPrint('✅ Train search completed successfully');
      debugPrint('📊 Found ${result.data.length} trains');

      trainData.value = result;
      // Pass both train data and date to the train list screen
      Get.toNamed('/train-list', arguments: {'trainData': result, 'date': dateController.text});
    } catch (e) {
      debugPrint('❌ Error in train search: $e');
      errorMessage.value = _getUserFriendlyErrorMessage(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateInputs() {
    debugPrint('🔍 Validating form inputs...');
    
    if (sourceNameController.text.isEmpty ||
        sourceCodeController.text.isEmpty ||
        destinationNameController.text.isEmpty ||
        destinationCodeController.text.isEmpty ||
        dateController.text.isEmpty) {
      debugPrint('❌ Validation failed: Empty fields');
      errorMessage.value = 'Please fill all fields';
      return false;
    }

    // Validate date format (YYYYMMDD)
    final dateRegex = RegExp(r'^\d{8}$');
    if (!dateRegex.hasMatch(dateController.text)) {
      debugPrint('❌ Validation failed: Invalid date format');
      errorMessage.value = 'Date must be in YYYYMMDD format (e.g., 20250521)';
      return false;
    }

    // Validate station codes (3-4 characters)
    final stationCodeRegex = RegExp(r'^[A-Z]{2,4}$');
    if (!stationCodeRegex.hasMatch(sourceCodeController.text) ||
        !stationCodeRegex.hasMatch(destinationCodeController.text)) {
      debugPrint('❌ Validation failed: Invalid station code format');
      errorMessage.value = 'Station codes must be 3-4 uppercase letters';
      return false;
    }

    debugPrint('✅ Form validation passed');
    return true;
  }

  String _getUserFriendlyErrorMessage(String error) {
    if (error.contains('Network error')) {
      return 'Unable to connect to the server. Please check your internet connection.';
    } else if (error.contains('No trains found')) {
      return 'No trains found for the selected route. Please try different stations or date.';
    } else if (error.contains('Invalid request parameters')) {
      return 'Invalid station details. Please check the station names and codes.';
    } else if (error.contains('Server error')) {
      return 'Server is currently unavailable. Please try again later.';
    } else if (error.contains('Failed to parse')) {
      return 'Received invalid data from server. Please try again.';
    }
    return 'An error occurred. Please try again.';
  }
}
