//https://capitol-import-assisted-doors.trycloudflare.com

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:trainbuddy/travel_buddy/models/train_miss_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TrainMissComponent extends StatefulWidget {
  final String sourceName;
  final String sourceCode;
  final String destinationName;
  final String destinationCode;

  const TrainMissComponent({
    super.key,
    required this.sourceName,
    required this.sourceCode,
    required this.destinationName,
    required this.destinationCode,
  });

  @override
  State<TrainMissComponent> createState() => _TrainMissComponentState();
}

class _TrainMissComponentState extends State<TrainMissComponent> {
  bool isLoading = false;
  TrainMissResponse? trainResponse;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height :0.001);
  }

  Future<void> _fetchTrainData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = Uri.parse(
        'https://capitol-import-assisted-doors.trycloudflare.com/trains/json?src_name=${Uri.encodeComponent(widget.sourceName)}&src_code=${widget.sourceCode}&dst_name=${Uri.encodeComponent(widget.destinationName)}&dst_code=${widget.destinationCode}'
      );

      debugPrint('=== TRAIN MISS API REQUEST ===');
      debugPrint('URL: $url');
      debugPrint('Source Name: ${widget.sourceName}');
      debugPrint('Source Code: ${widget.sourceCode}');
      debugPrint('Destination Name: ${widget.destinationName}');
      debugPrint('Destination Code: ${widget.destinationCode}');
      debugPrint('Encoded URL: ${url.toString()}');
      debugPrint('Request Method: GET');
      debugPrint('Request Headers: ${jsonEncode({'accept': 'application/json'})}');

      final startTime = DateTime.now();
      debugPrint('Request Start Time: ${startTime.toIso8601String()}');

      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out after 30 seconds');
        },
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;
      
      debugPrint('=== TRAIN MISS API RESPONSE ===');
      debugPrint('Response Time: ${endTime.toIso8601String()}');
      debugPrint('Request Duration: $duration ms');
      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Headers: ${jsonEncode(response.headers)}');
      debugPrint('Response Body Length: ${response.body.length} characters');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          debugPrint('=== PARSED JSON DATA ===');
          debugPrint('JSON Data: $jsonData');
          debugPrint('Success Field: ${jsonData['success']}');
          debugPrint('Message Field: ${jsonData['message']}');
          debugPrint('Total Count: ${jsonData['total_count']}');
          debugPrint('Data Array Length: ${jsonData['data']?.length ?? 0}');
          
          if (jsonData['data'] != null) {
            debugPrint('=== TRAIN DATA DETAILS ===');
            for (int i = 0; i < jsonData['data'].length; i++) {
              final train = jsonData['data'][i];
              debugPrint('Train $i:');
              debugPrint('  Number: ${train['train_number']}');
              debugPrint('  Name: ${train['train_name']}');
              debugPrint('  Type: ${train['train_type']}');
              debugPrint('  Departure: ${train['departure_time']}');
              debugPrint('  Arrival: ${train['arrival_time']}');
              debugPrint('  Duration: ${train['duration']}');
              debugPrint('  Source: ${train['source']}');
              debugPrint('  Destination: ${train['destination']}');
              debugPrint('  Classes: ${train['booking_classes']}');
            }
          }
          
          final trainResponse = TrainMissResponse.fromJson(jsonData);
          debugPrint('=== MODEL CREATION ===');
          debugPrint('Model Created Successfully');
          debugPrint('Response Success: ${trainResponse.success}');
          debugPrint('Response Message: ${trainResponse.message}');
          debugPrint('Total Count: ${trainResponse.totalCount}');
          debugPrint('Data Length: ${trainResponse.data.length}');
          
          setState(() {
            this.trainResponse = trainResponse;
            isLoading = false;
          });
          
          _showTrainDialog();
        } catch (e, stackTrace) {
          debugPrint('=== JSON PARSING ERROR ===');
          debugPrint('Error: $e');
          debugPrint('Stack Trace: $stackTrace');
          debugPrint('Raw Response Body: ${response.body}');
          throw Exception('Failed to parse response JSON: $e');
        }
      } else {
        debugPrint('=== HTTP ERROR ===');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        debugPrint('Response Headers: ${response.headers}');
        
        String errorMessage = 'HTTP ${response.statusCode}';
        if (response.statusCode == 404) {
          errorMessage = 'API endpoint not found. Please check the URL.';
        } else if (response.statusCode == 500) {
          errorMessage = 'Server error. Please try again later.';
        } else if (response.statusCode == 403) {
          errorMessage = 'Access forbidden. Please check API permissions.';
        } else if (response.statusCode == 401) {
          errorMessage = 'Unauthorized. Please check API credentials.';
        } else {
          errorMessage = 'Failed to load train data: ${response.statusCode} - ${response.body}';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      debugPrint('=== EXCEPTION DETAILS ===');
      debugPrint('Exception Type: ${e.runtimeType}');
      debugPrint('Exception Message: $e');
      debugPrint('Stack Trace: $stackTrace');
      
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      
      String userMessage = 'Failed to load train data';
      if (e.toString().contains('timed out')) {
        userMessage = 'Request timed out. Please check your internet connection.';
      } else if (e.toString().contains('404')) {
        userMessage = 'API endpoint not found. Please contact support.';
      } else if (e.toString().contains('Failed to parse')) {
        userMessage = 'Invalid response format. Please try again.';
      } else {
        userMessage = e.toString();
      }
      
      Get.snackbar(
        'Error',
        userMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        mainButton: TextButton(
          onPressed: () {
            Get.back(); // Close snackbar
            _fetchTrainData(); // Retry
          },
          child: const Text(
            'Retry',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  void _showTrainDialog() {
    if (trainResponse == null) return;

    Get.dialog(
      Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1E1E), Color(0xFF2C2F33)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header

            // Content
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 500),
                child: trainResponse!.data.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.train_outlined,
                                size: 48,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No trains found',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try different stations or check back later',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: trainResponse!.data.length,
                        itemBuilder: (context, index) {
                          final train = trainResponse!.data[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF00E676).withOpacity(0.1),
                                  const Color(0xFF00C853).withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
                            ),
                            child: Column(
                              children: [
                                // Train header
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00E676),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          train.trainNumber,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              train.trainName,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              train.trainType.toUpperCase(),
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 12,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00E676).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          train.duration,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF00E676),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Journey details
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2C2F33),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      // Station details
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'From',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 12,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  train.source,
                                                  style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            child: const Icon(
                                              Icons.arrow_forward,
                                              color: Color(0xFF00E676),
                                              size: 20,
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'To',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 12,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  train.destination,
                                                  style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Time and additional details
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTrainDetailChip(
                                              icon: Icons.schedule,
                                              label: 'Departure',
                                              value: train.departureTime,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildTrainDetailChip(
                                              icon: Icons.schedule,
                                              label: 'Arrival',
                                              value: train.arrivalTime,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (train.status != null || train.platform != null) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            if (train.status != null) ...[
                                              Expanded(
                                                child: _buildTrainDetailChip(
                                                  icon: Icons.info_outline,
                                                  label: 'Status',
                                                  value: train.status!,
                                                ),
                                              ),
                                            ],
                                            if (train.platform != null) ...[
                                              if (train.status != null) const SizedBox(width: 8),
                                              Expanded(
                                                child: _buildTrainDetailChip(
                                                  icon: Icons.train,
                                                  label: 'Platform',
                                                  value: train.platform!,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      // Booking classes
                                      if (train.bookingClasses.isNotEmpty) ...[
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.airline_seat_recline_normal,
                                              color: const Color(0xFF00E676),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Available Classes:',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: train.bookingClasses.map((className) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF00E676).withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
                                              ),
                                              child: Text(
                                                className,
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF00E676),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total: ${trainResponse!.totalCount} trains found',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildTrainDetailChip({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF00E676).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF00E676), size: 14),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}