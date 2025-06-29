class Train {
    Train({
        required this.data,
        required this.status,
    });

    final List<TrainData> data;
    final String? status;

    factory Train.fromJson(Map<String, dynamic> json) {
        return Train(
            data: List<TrainData>.from(
                json["data"].map((x) => TrainData.fromJson(x))),
            status: json["status"],
        );
    }
}

class TrainData {
    TrainData({
        required this.advanceReservationPeriod,
        required this.arrivalTime,
        required this.availableClasses,
        required this.bookingAvailable,
        required this.bookingClasses,
        required this.departureTime,
        required this.destination,
        required this.destinationDelay,
        required this.duration,
        required this.endDate,
        required this.hasPantry,
        required this.isLimitedRun,
        required this.notices,
        required this.predictedDelays,
        required this.runningDays,
        required this.source,
        required this.sourceDelay,
        required this.startDate,
        required this.stations,
        required this.trainName,
        required this.trainNumber,
        required this.trainType,
    });

    final String? advanceReservationPeriod;
    final String? arrivalTime;
    final List<String> availableClasses;
    final bool? bookingAvailable;
    final List<String> bookingClasses;
    final String? departureTime;
    final String? destination;
    final double? destinationDelay;
    final String? duration;
    final String? endDate;
    final bool? hasPantry;
    final bool? isLimitedRun;
    final List<dynamic> notices;
    final Map<String, double> predictedDelays;
    final String? runningDays;
    final String? source;
    final double? sourceDelay;
    final String? startDate;
    final List<Station> stations;
    final String? trainName;
    final String? trainNumber;
    final String? trainType;

    factory TrainData.fromJson(Map<String, dynamic> json) {
        return TrainData(
            advanceReservationPeriod: json["advance_reservation_period"],
            arrivalTime: json["arrival_time"],
            availableClasses: json["available_classes"] == null ? [] : List<String>.from(json["available_classes"]!.map((x) => x)),
            bookingAvailable: json["booking_available"],
            bookingClasses: json["booking_classes"] == null ? [] : List<String>.from(json["booking_classes"]!.map((x) => x)),
            departureTime: json["departure_time"],
            destination: json["destination"],
            destinationDelay: _parseDelay(json["destination_delay"]),
            duration: json["duration"],
            endDate: json["end_date"],
            hasPantry: json["has_pantry"],
            isLimitedRun: json["is_limited_run"],
            notices: json["notices"] == null ? [] : List<dynamic>.from(json["notices"]!.map((x) => x)),
            predictedDelays: _parsePredictedDelays(json["predicted_delays"]),
            runningDays: json["running_days"],
            source: json["source"],
            sourceDelay: _parseDelay(json["source_delay"]),
            startDate: json["start_date"],
            stations: json["stations"] == null ? [] : List<Station>.from(json["stations"]!.map((x) => Station.fromJson(x))),
            trainName: json["train_name"],
            trainNumber: json["train_number"],
            trainType: json["train_type"],
        );
    }

    static double? _parseDelay(dynamic value) {
        if (value == null) return null;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.tryParse(value);
        return null;
    }

    static Map<String, double> _parsePredictedDelays(dynamic json) {
        if (json == null) return {};
        if (json is! Map) return {};
        
        return Map.fromEntries(
            json.entries.map((entry) {
                final value = entry.value;
                double? delay;
                if (value is double) {
                    delay = value;
                } else if (value is int) {
                    delay = value.toDouble();
                } else if (value is String) {
                    delay = double.tryParse(value);
                }
                return MapEntry(entry.key, delay ?? 0.0);
            })
        );
    }
}

class Station {
    Station({
        required this.code,
        required this.isSource,
        required this.name,
        required this.isDestination,
    });

    final String? code;
    final bool? isSource;
    final String? name;
    final bool? isDestination;

    factory Station.fromJson(Map<String, dynamic> json) {
        return Station(
            code: json["code"],
            isSource: json["is_source"],
            name: json["name"],
            isDestination: json["is_destination"],
        );
    }
}
