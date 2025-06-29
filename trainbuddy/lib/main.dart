import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trainbuddy/chatbot/screens/chat_screen.dart';
import 'package:trainbuddy/landing_page.dart';
import 'package:trainbuddy/travel_buddy/controllers/travel-plan-controller.dart';
import 'package:trainbuddy/travel_buddy/screens/travel-plan.dart';


import 'train_buddy/screens/dashboard.dart';

import 'train_buddy/screens/train_details_screen.dart';
import 'train_buddy/screens/train_finder_screen.dart';
import 'train_buddy/screens/train_list_screen.dart';
import 'travel_buddy/models/travel_model.dart';
import 'travel_buddy/screens/intro_buddy.dart';
import 'travel_buddy/screens/travel-info.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> dummyData = {
      "trip_summary": {
        "source": "Kolkata",
        "destination": "Varanasi",
        "start_date": "2025-08-21",
        "end_date": "2025-08-25",
        "duration_days": 5,
        "travelers": {
          "adults": 3,
          "children": 0
        },
        "total_budget": 45000.0,
        "trip_type": "group"
      },
      "min_budget_analysis": {
        "min_budget": 24600.0,
        "breakdown": {
          "transport": 8400.0,
          "accommodation": 8400.0,
          "food": 4200.0,
          "local_transport": 1200.0,
          "buffer": 2460.0
        },
        "feasibility_notes": "The cheapest round-trip transport from Kolkata to Varanasi is by train (Sleeper class). Basic shared accommodation can be found in hostels or guesthouses. Minimum food costs are estimated at \u20b9500 per person per day. Essential local transport includes auto-rickshaws and buses. The 10% buffer is added for any unexpected expenses."
      },
      "transport_plan": {
        "mode": "Train",
        "route": "Kolkata (HWH) to Varanasi (BSB) via Rajdhani Express (12301/12302)",
        "departure_timing": "Recommended departure time: 16:55 from Kolkata",
        "duration_hours": 8.5,
        "total_cost": 21600.0,
        "availability": "High",
        "booking_notes": "Book 2AC tickets in advance to ensure availability and comfort"
      },
      "accommodation_plan": {
        "property_name": "Hotel Ganges View",
        "property_type": "Mid-range",
        "location": "Assi Ghat",
        "total_cost": 12600.0,
        "per_night_rate": 3150.0,
        "amenities": "Free Wi-Fi, Restaurant, 24-hour front desk, Laundry service",
        "booking_notes": "Book at least 2 weeks in advance to ensure availability"
      },
      "daily_costs_estimate": {
        "food_per_day": 240.0,
        "local_transport_per_day": 72.0,
        "misc_per_day": 120.0,
        "total_daily_per_person": 432.0,
        "cost_saving_tips": "Consider staying in a hostel or budget hotel, eat at local eateries and street food stalls, and use public transport or walk whenever possible to save money."
      },
      "detailed_itinerary": {
        "itinerary": [
          {
            "day": 1,
            "date": "2025-08-21",
            "theme": "Arrival & Spiritual Immersion",
            "morning": {
              "activity": "Check-in at hotel & Visit Kashi Vishwanath Temple",
              "description": "Explore the sacred temple dedicated to Lord Shiva",
              "transport": "Taxi from station/airport",
              "cost": 500.0
            },
            "afternoon": {
              "activity": "Boat Ride on Ganges River",
              "description": "Witness the spiritual significance of the river",
              "transport": "Walk",
              "cost": 800.0
            },
            "evening": {
              "activity": "Ganga Aarti at Dasaswamedh Ghat",
              "description": "Experience the mesmerizing evening prayer ceremony",
              "transport": "Walk",
              "cost": 300.0
            },
            "meals": {
              "breakfast": "Hotel",
              "lunch": "Local restaurant",
              "dinner": "Street food"
            },
            "total_daily_cost": 1600.0
          },
          {
            "day": 2,
            "date": "2025-08-22",
            "theme": "Spiritual Exploration",
            "morning": {
              "activity": "Visit Sarnath Museum & Dhamek Stupa",
              "description": "Discover the history and significance of Buddhism",
              "transport": "Taxi",
              "cost": 600.0
            },
            "afternoon": {
              "activity": "Explore the narrow alleys of Varanasi",
              "description": "Get lost in the vibrant streets of the old city",
              "transport": "Walk",
              "cost": 0.0
            },
            "evening": {
              "activity": "Enjoy a Cultural Program",
              "description": "Witness traditional Indian music and dance",
              "transport": "Taxi",
              "cost": 500.0
            },
            "meals": {
              "breakfast": "Hotel",
              "lunch": "Local restaurant",
              "dinner": "Street food"
            },
            "total_daily_cost": 1100.0
          },
          {
            "day": 3,
            "date": "2025-08-23",
            "theme": "Rural Exploration",
            "morning": {
              "activity": "Visit a nearby village",

              "description": "Experience rural Indian life",
              "transport": "Taxi",
              "cost": 800.0
            },
            "afternoon": {
              "activity": "Lunch at a local's house",
              "description": "Savor authentic Indian cuisine",
              "transport": "",
              "cost": 300.0
            },
            "evening": {
              "activity": "Return to Varanasi",
              "description": "",
              "transport": "Taxi",
              "cost": 500.0
            },
            "meals": {
              "breakfast": "Hotel",
              "lunch": "Local's house",
              "dinner": "Street food"
            },
            "total_daily_cost": 1600.0
          },
          {
            "day": 4,
            "date": "2025-08-24",
            "theme": "Spiritual Significance",
            "morning": {
              "activity": "Visit Tulsi Manas Temple",
              "description": "Explore the temple dedicated to Lord Rama",
              "transport": "Taxi",
              "cost": 400.0
            },
            "afternoon": {
              "activity": "Visit Banaras Hindu University",
              "description": "Discover the largest residential university in Asia",
              "transport": "Taxi",
              "cost": 300.0
            },
            "evening": {
              "activity": "Explore the local markets",
              "description": "Shop for souvenirs",
              "transport": "Walk",
              "cost": 0.0
            },
            "meals": {
              "breakfast": "Hotel",
              "lunch": "Local restaurant",
              "dinner": "Street food"
            },
            "total_daily_cost": 700.0
          },
          {
            "day": 5,
            "date": "2025-08-25",
            "theme": "Departure",
            "morning": {
              "activity": "Check-out from hotel",
              "description": "",
              "transport": "Taxi to station/airport",
              "cost": 300.0
            },
            "afternoon": "",
            "evening": "",
            "meals": {
              "breakfast": "Hotel",
              "lunch": "",
              "dinner": ""
            },
            "total_daily_cost": 300.0
          }
        ],
        "total_trip_cost": 9240.0,
        "important_notes": "Please respect the local culture and traditions. Dress modestly while visiting temples and other religious sites."
      }
    };

    return GetMaterialApp(
      title: 'Travel Buddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF86A3C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF86A3C),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/intro',
      getPages: [
        GetPage(name: "/intro", page:() => IntroBuddyScreen()),

        GetPage(name: "/chat", page:() => ChatScreen()),
        GetPage(name: "/travelinfo", page:() => TravelInfoScreen()),
        GetPage(name: "/landing", page:() => LandingScreen()),
        GetPage(name: '/', page: () => const DashboardScreen()),
        GetPage(name: '/train-finder', page: () => const TrainFinderScreen()),
        GetPage(name: '/train-list', page: () => const TrainListScreen()),
        GetPage(name: '/train-details', page: () => const TrainDetailsScreen()),

      ],
    );
  }
}


