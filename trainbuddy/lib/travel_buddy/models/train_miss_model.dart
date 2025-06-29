class TrainMissResponse {
  final bool success;
  final List<TrainMissData> data;
  final int totalCount;
  final String timestamp;
  final String message;

  TrainMissResponse({
    required this.success,
    required this.data,
    required this.totalCount,
    required this.timestamp,
    required this.message,
  });

  factory TrainMissResponse.fromJson(Map<String, dynamic> json) {
    // Add debug logging
    print('=== PARSING TRAIN MISS RESPONSE ===');
    print('Raw JSON: $json');
    print('Success field: ${json['success']}');
    print('Data field type: ${json['data']?.runtimeType}');
    print('Data field value: ${json['data']}');
    print('Total count field: ${json['total_count']}');
    print('Message field: ${json['message']}');
    
    List<TrainMissData> data = [];
    if (json['data'] != null && json['data'] is List) {
      data = (json['data'] as List).map((x) => TrainMissData.fromJson(x)).toList();
    }
    
    print('Parsed data length: ${data.length}');
    
    return TrainMissResponse(
      success: json['success'] ?? false,
      data: data,
      totalCount: json['total_count'] ?? 0,
      timestamp: json['timestamp'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

class TrainMissData {
  final String trainNumber;
  final String trainName;
  final String trainType;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final String source;
  final String destination;
  final List<String> bookingClasses;
  final String? status;
  final String? platform;
  final String? fare;

  TrainMissData({
    required this.trainNumber,
    required this.trainName,
    required this.trainType,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.source,
    required this.destination,
    required this.bookingClasses,
    this.status,
    this.platform,
    this.fare,
  });

  factory TrainMissData.fromJson(Map<String, dynamic> json) {
    return TrainMissData(
      trainNumber: json['train_number'] ?? '',
      trainName: json['train_name'] ?? '',
      trainType: json['train_type'] ?? '',
      departureTime: json['departure_time'] ?? '',
      arrivalTime: json['arrival_time'] ?? '',
      duration: json['duration'] ?? '',
      source: json['source'] ?? '',
      destination: json['destination'] ?? '',
      bookingClasses: json['booking_classes'] != null 
          ? List<String>.from(json['booking_classes'])
          : [],
      status: json['status'],
      platform: json['platform'],
      fare: json['fare'],
    );
  }
}
