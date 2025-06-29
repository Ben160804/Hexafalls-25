import 'package:flutter/foundation.dart';

class TravelDetails {
  TravelDetails({
    required this.tripSummary,
    required this.transportation,
    required this.accommodation,
    required this.itinerary,
    required this.budgetBreakdown,
    required this.recommendations,
  });

  final TripSummary? tripSummary;
  final Transportation? transportation;
  final List<Accommodation> accommodation;
  final List<Itinerary> itinerary;
  final BudgetBreakdown? budgetBreakdown;
  final Recommendations? recommendations;

  factory TravelDetails.fromJson(Map<String, dynamic> json) {
    try {
      return TravelDetails(
        tripSummary: json["trip_summary"] == null ? null : TripSummary.fromJson(json["trip_summary"]),
        transportation: json["transportation"] == null ? null : Transportation.fromJson(json["transportation"]),
        accommodation: json["accommodation"] == null ? [] : List<Accommodation>.from(json["accommodation"]!.map((x) => Accommodation.fromJson(x))),
        itinerary: json["itinerary"] == null ? [] : List<Itinerary>.from(json["itinerary"]!.map((x) => Itinerary.fromJson(x))),
        budgetBreakdown: json["budget_breakdown"] == null ? null : BudgetBreakdown.fromJson(json["budget_breakdown"]),
        recommendations: json["recommendations"] == null ? null : Recommendations.fromJson(json["recommendations"]),
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing TravelDetails: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }
}

class Dates {
  final String? start;
  final String? end;

  Dates({this.start, this.end});

  factory Dates.fromJson(Map<String, dynamic> json) {
    return Dates(
      start: json["start"]?.toString() ?? "",
      end: json["end"]?.toString() ?? "",
    );
  }
}

class TripSummary {
  final String? from;
  final String? to;
  final String? dates; // Will handle both string and object formats
  final Travelers? travelers;
  final String? tripType;
  final int? budget;
  final int? duration;

  TripSummary({
    this.from,
    this.to,
    this.dates,
    this.travelers,
    this.tripType,
    this.budget,
    this.duration,
  });

  factory TripSummary.fromJson(Map<String, dynamic> json) {
    // Handle both field name variations
    final fromField = json["from"] ?? json["origin"] ?? json["source"];
    final toField = json["to"] ?? json["destination"];
    
    // Handle dates - can be string, object, or separate start/end dates
    String? datesString;
    final datesField = json["dates"];
    final startDateField = json["start_date"];
    final endDateField = json["end_date"];
    
    if (datesField != null) {
      if (datesField is String) {
        datesString = datesField;
      } else if (datesField is Map<String, dynamic>) {
        final datesObj = Dates.fromJson(datesField);
        datesString = '${datesObj.start} to ${datesObj.end}';
      }
    } else if (startDateField != null && endDateField != null) {
      datesString = '$startDateField to $endDateField';
    }

    // Helper function to safely convert field to string
    String? safeString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List && value.isNotEmpty) {
        final stringElements = value.whereType<String>().toList();
        if (stringElements.isNotEmpty) {
          return stringElements.join(', ');
        }
      }
      return null;
    }

    // Handle budget - can be int or double
    int? budgetValue;
    final budgetField = json["budget"];
    if (budgetField != null) {
      if (budgetField is int) {
        budgetValue = budgetField;
      } else if (budgetField is double) {
        budgetValue = budgetField.round();
      }
    }

    return TripSummary(
      from: safeString(fromField),
      to: safeString(toField),
      dates: datesString,
      travelers: json["travelers"] == null ? null : Travelers.fromJson(json["travelers"]),
      tripType: safeString(json["trip_type"]),
      budget: budgetValue,
      duration: json["duration"],
    );
  }
}

class Travelers {
  final int? adults;
  final int? children;

  Travelers({
    this.adults,
    this.children,
  });

  factory Travelers.fromJson(dynamic json) {
    // Handle case where travelers might be an integer (total count) instead of an object
    if (json is int) {
      return Travelers(
        adults: json,
        children: 0,
      );
    }
    
    if (json is Map<String, dynamic>) {
      return Travelers(
        adults: json["adults"],
        children: json["children"],
      );
    }
    
    // Default case
    return Travelers(
      adults: 0,
      children: 0,
    );
  }
}

class Accommodation {
  final String? name;
  final String? type;
  final double? rating;
  final String? location;
  final int? costPerNight;
  final int? totalCost;
  final List<String> amenities;
  final String? bookingLink;
  final DateTime? checkIn;
  final DateTime? checkOut;

  Accommodation({
    this.name,
    this.type,
    this.rating,
    this.location,
    this.costPerNight,
    this.totalCost,
    this.amenities = const [],
    this.bookingLink,
    this.checkIn,
    this.checkOut,
  });

  factory Accommodation.fromJson(Map<String, dynamic> json) {
    // Handle both field name variations
    final nameField = json["name"] ?? json["hotel_name"];
    final checkInField = json["check_in"] ?? json["checkin"];
    final checkOutField = json["check_out"] ?? json["checkout"];
    
    // Handle amenities - can be string or list
    List<String> amenitiesList = [];
    final amenitiesField = json["amenities"];
    if (amenitiesField != null) {
      if (amenitiesField is String) {
        amenitiesList = [amenitiesField];
      } else if (amenitiesField is List) {
        amenitiesList = amenitiesField.whereType<String>().toList();
      }
    }

    // Handle rating - can be string or double
    double? ratingValue;
    final ratingField = json["rating"];
    if (ratingField != null) {
      if (ratingField is double) {
        ratingValue = ratingField;
      } else if (ratingField is int) {
        ratingValue = ratingField.toDouble();
      } else if (ratingField is String) {
        // Try to extract numeric value from string like "3 stars"
        final numericMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(ratingField);
        if (numericMatch != null) {
          ratingValue = double.tryParse(numericMatch.group(1)!);
        }
      }
    }

    // Handle check-in and check-out dates - can be string or DateTime
    DateTime? checkInValue;
    DateTime? checkOutValue;
    
    if (checkInField != null) {
      if (checkInField is DateTime) {
        checkInValue = checkInField;
      } else if (checkInField is String) {
        checkInValue = DateTime.tryParse(checkInField);
      }
    }
    
    if (checkOutField != null) {
      if (checkOutField is DateTime) {
        checkOutValue = checkOutField;
      } else if (checkOutField is String) {
        checkOutValue = DateTime.tryParse(checkOutField);
      }
    }

    return Accommodation(
      name: nameField,
      type: json["type"],
      rating: ratingValue,
      location: json["location"],
      costPerNight: json["cost_per_night"],
      totalCost: json["total_cost"],
      amenities: amenitiesList,
      bookingLink: json["booking_link"],
      checkIn: checkInValue,
      checkOut: checkOutValue,
    );
  }
}

class BudgetBreakdown {
  final int? transportation;
  final int? accommodation;
  final int? food;
  final int? activities;
  final int? buffer;
  final int? totalEstimated;

  BudgetBreakdown({
    this.transportation,
    this.accommodation,
    this.food,
    this.activities,
    this.buffer,
    this.totalEstimated,
  });

  factory BudgetBreakdown.fromJson(Map<String, dynamic> json) {
    return BudgetBreakdown(
      transportation: json["transportation"],
      accommodation: json["accommodation"],
      food: json["food"],
      activities: json["activities"],
      buffer: json["buffer"],
      totalEstimated: json["total_estimated"],
    );
  }
}

class Activity {
  final String time;
  final String activity;
  final String location;
  final int cost;
  final String duration;

  Activity({
    required this.time,
    required this.activity,
    required this.location,
    required this.cost,
    required this.duration,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      time: json["time"] ?? "",
      activity: json["activity"] ?? "",
      location: json["location"] ?? "",
      cost: json["cost"] ?? 0,
      duration: json["duration"] ?? "",
    );
  }
}

class Meals {
  final String? breakfast;
  final String? lunch;
  final String? dinner;

  Meals({
    this.breakfast,
    this.lunch,
    this.dinner,
  });

  factory Meals.fromJson(Map<String, dynamic> json) {
    return Meals(
      breakfast: json["breakfast"],
      lunch: json["lunch"],
      dinner: json["dinner"],
    );
  }
}

class Itinerary {
  final int? day;
  final DateTime? date;
  final List<Activity> activities;
  final Meals? meals;
  final int? totalDayCost;

  Itinerary({
    this.day,
    this.date,
    required this.activities,
    this.meals,
    this.totalDayCost,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    // Handle activities - can be string or list of activity objects
    List<Activity> activitiesList = [];
    final activitiesField = json["activities"];
    if (activitiesField != null) {
      if (activitiesField is String) {
        activitiesList = [Activity(
          time: "",
          activity: activitiesField,
          location: "",
          cost: 0,
          duration: "",
        )];
      } else if (activitiesField is List) {
        activitiesList = activitiesField.map((activity) {
          if (activity is Map<String, dynamic>) {
            return Activity.fromJson(activity);
          } else {
            return Activity(
              time: "",
              activity: activity.toString(),
              location: "",
              cost: 0,
              duration: "",
            );
          }
        }).toList();
      }
    }

    // Handle date - can be string or DateTime
    DateTime? dateValue;
    final dateField = json["date"];
    if (dateField != null) {
      if (dateField is DateTime) {
        dateValue = dateField;
      } else if (dateField is String) {
        dateValue = DateTime.tryParse(dateField);
      }
    }

    return Itinerary(
      day: json["day"],
      date: dateValue,
      activities: activitiesList,
      meals: json["meals"] == null ? null : Meals.fromJson(json["meals"]),
      totalDayCost: json["total_day_cost"],
    );
  }
}

class Recommendations {
  final String? placesToVisit;
  final String? foodToTry;
  final String? thingsToDo; // Added from API response
  final String? tips; // Added from API response
  final List<String> packingList;
  final List<String> travelTips;
  final List<String> emergencyContacts;
  final String? weatherAdvice;
  final String? localCustoms;

  Recommendations({
    this.placesToVisit,
    this.foodToTry,
    this.thingsToDo,
    this.tips,
    required this.packingList,
    required this.travelTips,
    required this.emergencyContacts,
    this.weatherAdvice,
    this.localCustoms,
  });

  factory Recommendations.fromJson(Map<String, dynamic> json) {
    // Handle packing_list - can be string or list
    List<String> packingList = [];
    final packingListField = json["packing_list"];
    if (packingListField != null) {
      if (packingListField is String) {
        packingList = [packingListField];
      } else if (packingListField is List) {
        packingList = packingListField.whereType<String>().toList();
      }
    }

    // Handle travel_tips - can be string or list
    List<String> travelTips = [];
    final travelTipsField = json["travel_tips"];
    if (travelTipsField != null) {
      if (travelTipsField is String) {
        travelTips = [travelTipsField];
      } else if (travelTipsField is List) {
        travelTips = travelTipsField.whereType<String>().toList();
      }
    }

    // Handle emergency_contacts - can be string or list
    List<String> emergencyContacts = [];
    final emergencyContactsField = json["emergency_contacts"];
    if (emergencyContactsField != null) {
      if (emergencyContactsField is String) {
        emergencyContacts = [emergencyContactsField];
      } else if (emergencyContactsField is List) {
        emergencyContacts = emergencyContactsField.whereType<String>().toList();
      }
    }

    return Recommendations(
      placesToVisit: json["places_to_visit"],
      foodToTry: json["food_to_try"],
      thingsToDo: json["things_to_do"],
      tips: json["tips"],
      packingList: packingList,
      travelTips: travelTips,
      emergencyContacts: emergencyContacts,
      weatherAdvice: json["weather_advice"],
      localCustoms: json["local_customs"],
    );
  }
}

class TransportLeg {
  final String mode;
  final String details;
  final String duration;
  final int costPerPerson;
  final int totalCost;
  final String bookingLink;
  final String departureTime;
  final String arrivalTime;

  TransportLeg({
    required this.mode,
    required this.details,
    required this.duration,
    required this.costPerPerson,
    required this.totalCost,
    required this.bookingLink,
    required this.departureTime,
    required this.arrivalTime,
  });

  factory TransportLeg.fromJson(Map<String, dynamic> json) {
    return TransportLeg(
      mode: json["mode"] ?? "",
      details: json["details"] ?? "",
      duration: json["duration"] ?? "",
      costPerPerson: json["cost_per_person"] ?? 0,
      totalCost: json["total_cost"] ?? 0,
      bookingLink: json["booking_link"] ?? "",
      departureTime: json["departure_time"] ?? "",
      arrivalTime: json["arrival_time"] ?? "",
    );
  }
}

class LocalTransport {
  final String mode;
  final int dailyCost;
  final int totalCost;

  LocalTransport({
    required this.mode,
    required this.dailyCost,
    required this.totalCost,
  });

  factory LocalTransport.fromJson(Map<String, dynamic> json) {
    return LocalTransport(
      mode: json["mode"] ?? "",
      dailyCost: json["daily_cost"] ?? 0,
      totalCost: json["total_cost"] ?? 0,
    );
  }
}

class Transportation {
  final List<Train>? trains;
  final List<dynamic>? flights;
  final List<dynamic>? buses;
  final TransportLeg? outbound;
  final TransportLeg? returnLeg;
  final LocalTransport? localTransport;

  Transportation({
    this.trains,
    this.flights,
    this.buses,
    this.outbound,
    this.returnLeg,
    this.localTransport,
  });

  factory Transportation.fromJson(Map<String, dynamic> json) {
    // Handle new API structure with outbound/return/local_transport
    if (json.containsKey("outbound") || json.containsKey("return") || json.containsKey("local_transport")) {
      return Transportation(
        trains: null,
        flights: null,
        buses: null,
        outbound: json["outbound"] == null ? null : TransportLeg.fromJson(json["outbound"]),
        returnLeg: json["return"] == null ? null : TransportLeg.fromJson(json["return"]),
        localTransport: json["local_transport"] == null ? null : LocalTransport.fromJson(json["local_transport"]),
      );
    }
    
    // Handle old API structure with trains/flights/buses
    return Transportation(
      trains: json["trains"] == null ? null : List<Train>.from(json["trains"].map((x) => Train.fromJson(x))),
      flights: json["flights"] == null ? null : List<dynamic>.from(json["flights"].map((x) => x)),
      buses: json["buses"] == null ? null : List<dynamic>.from(json["buses"].map((x) => x)),
      outbound: null,
      returnLeg: null,
      localTransport: null,
    );
  }
}

class Train {
  final String? segment;
  final String? name;
  final String? number;
  final Arrival? departure;
  final Arrival? arrival;
  final String? duration;
  final String? trainClass;
  final int? costPerAdult;
  final int? costPerChild;
  final int? totalCost;
  final String? bookingLink;

  Train({
    this.segment,
    this.name,
    this.number,
    this.departure,
    this.arrival,
    this.duration,
    this.trainClass,
    this.costPerAdult,
    this.costPerChild,
    this.totalCost,
    this.bookingLink,
  });

  factory Train.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert field to string
    String? safeString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List && value.isNotEmpty) {
        final stringElements = value.whereType<String>().toList();
        if (stringElements.isNotEmpty) {
          return stringElements.join(', ');
        }
      }
      return null;
    }

    // Handle different API structures
    final trainName = safeString(json["name"]) ?? safeString(json["train_name"]);
    final trainNumber = safeString(json["number"]) ?? safeString(json["train_number"]);
    final fromStation = safeString(json["from"]);
    final toStation = safeString(json["to"]);
    final trainDate = safeString(json["date"]);
    final bookingLink = safeString(json["booking_link"]) ?? safeString(json["link"]);
    final fare = json["fare"] ?? json["cost_per_adult"] ?? json["total_cost"];

    // Create departure and arrival objects if we have the data
    Arrival? departure;
    Arrival? arrival;
    
    if (fromStation != null && trainDate != null) {
      departure = Arrival(
        station: fromStation,
        time: null,
        date: DateTime.tryParse(trainDate),
      );
    }
    
    if (toStation != null && trainDate != null) {
      arrival = Arrival(
        station: toStation,
        time: null,
        date: DateTime.tryParse(trainDate),
      );
    }

    return Train(
      segment: safeString(json["segment"]) ?? (fromStation != null && toStation != null ? '$fromStation to $toStation' : null),
      name: trainName,
      number: trainNumber,
      departure: json["departure"] == null ? departure : Arrival.fromJson(json["departure"]),
      arrival: json["arrival"] == null ? arrival : Arrival.fromJson(json["arrival"]),
      duration: safeString(json["duration"]),
      trainClass: safeString(json["class"]),
      costPerAdult: fare is int ? fare : null,
      costPerChild: json["cost_per_child"],
      totalCost: fare is int ? fare : json["total_cost"],
      bookingLink: bookingLink,
    );
  }
}

class Arrival {
  final String? station;
  final String? time;
  final DateTime? date;

  Arrival({
    this.station,
    this.time,
    this.date,
  });

  factory Arrival.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert field to string
    String? safeString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List && value.isNotEmpty) {
        final stringElements = value.whereType<String>().toList();
        if (stringElements.isNotEmpty) {
          return stringElements.join(', ');
        }
      }
      return null;
    }

    return Arrival(
      station: safeString(json["station"]),
      time: safeString(json["time"]),
      date: safeString(json["date"]) == null || safeString(json["date"]) == "" ? null : DateTime.tryParse(safeString(json["date"])!),
    );
  }
}