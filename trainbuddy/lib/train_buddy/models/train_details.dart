class TrainDetails {
    TrainDetails({
        required this.data,
        required this.status,
    });

    final Data? data;
    final String? status;

    factory TrainDetails.fromJson(Map<String, dynamic> json){ 
        return TrainDetails(
            data: json["data"] == null ? null : Data.fromJson(json["data"]),
            status: json["status"],
        );
    }

}

class Data {
    Data({
        required this.schedule,
        required this.trainInfo,
    });

    final List<Schedule> schedule;
    final TrainInfo? trainInfo;

    factory Data.fromJson(Map<String, dynamic> json){ 
        return Data(
            schedule: json["schedule"] == null ? [] : List<Schedule>.from(json["schedule"]!.map((x) => Schedule.fromJson(x))),
            trainInfo: json["train_info"] == null ? null : TrainInfo.fromJson(json["train_info"]),
        );
    }

}

class Schedule {
    Schedule({
        required this.arrival,
        required this.arrivalDay,
        required this.departure,
        required this.departureDay,
        required this.distance,
        required this.hasWifi,
        required this.isSource,
        required this.name,
        required this.platform,
        required this.predictedDelay,
        required this.stationCode,
        required this.stationNumber,
        required this.isDestination,
    });

    final String? arrival;
    final int? arrivalDay;
    final String? departure;
    final int? departureDay;
    final String? distance;
    final bool? hasWifi;
    final bool? isSource;
    final String? name;
    final String? platform;
    final double? predictedDelay;
    final String? stationCode;
    final int? stationNumber;
    final bool? isDestination;

    factory Schedule.fromJson(Map<String, dynamic> json){ 
        return Schedule(
            arrival: json["arrival"],
            arrivalDay: json["arrival_day"],
            departure: json["departure"],
            departureDay: json["departure_day"],
            distance: json["distance"],
            hasWifi: json["has_wifi"],
            isSource: json["is_source"],
            name: json["name"],
            platform: json["platform"],
            predictedDelay: json["predicted_delay"],
            stationCode: json["station_code"],
            stationNumber: json["station_number"],
            isDestination: json["is_destination"],
        );
    }

}

class TrainInfo {
    TrainInfo({
        required this.availableClasses,
        required this.hasPantry,
        required this.runningDays,
    });

    final String? availableClasses;
    final bool? hasPantry;
    final String? runningDays;

    factory TrainInfo.fromJson(Map<String, dynamic> json){ 
        return TrainInfo(
            availableClasses: json["available_classes"],
            hasPantry: json["has_pantry"],
            runningDays: json["running_days"],
        );
    }

}
