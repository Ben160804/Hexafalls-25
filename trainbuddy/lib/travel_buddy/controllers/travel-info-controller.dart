import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TravelInfoController extends GetxController {
  final RxString source = ''.obs;
  final RxString destination = ''.obs;
  final RxString travelDates = ''.obs;
  final RxInt duration = 7.obs; // Default 7 days
  final RxInt numberOfAdults = 1.obs; // Default 1 adult
  final RxInt numberOfChildren = 0.obs; // Default 0 children
  final RxInt numberOfTravellers = 1.obs; // Computed as adults + children
  final RxDouble budget = 0.0.obs; // Default 0.0
  final RxString tripType = 'Solo'.obs;

  void updateTravelInfo({
    String? source,
    String? destination,
    String? travelDates,
    int? duration,
    int? numberOfAdults,
    int? numberOfChildren,
    double? budget,
    String? tripType,
  }) {
    if (source != null) this.source.value = source;
    if (destination != null) this.destination.value = destination;
    if (travelDates != null) this.travelDates.value = travelDates;
    if (duration != null) this.duration.value = duration;
    if (numberOfAdults != null) this.numberOfAdults.value = numberOfAdults;
    if (numberOfChildren != null) this.numberOfChildren.value = numberOfChildren;
    if (budget != null) this.budget.value = budget;
    if (tripType != null) this.tripType.value = tripType;

    // Update numberOfTravellers as sum of adults and children
    numberOfTravellers.value = this.numberOfAdults.value + this.numberOfChildren.value;
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source.value,
      'destination': destination.value,
      'start_date': travelDates.value,
      'duration': duration.value,
      'adults': numberOfAdults.value,
      'children': numberOfChildren.value,
      'budget': budget.value,
      'trip_type': tripType.value,
    };
  }
}