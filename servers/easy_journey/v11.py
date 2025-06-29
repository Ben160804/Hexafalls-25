#!/usr/bin/env python3

"""Smart Indian Travel Planner - JSON Output Edition"""

import os
import json
import sys
import re
import datetime
from groq import Groq
from dotenv import load_dotenv

load_dotenv()

# Configuration
GROQ_API_KEY = os.environ.get("GROQ_API_KEY")
if not GROQ_API_KEY:
    print("Error: GROQ_API_KEY environment variable not set.")
    sys.exit(1)

LLM_MODEL = "llama3-70b-8192"
client = Groq(api_key=GROQ_API_KEY)

# Helper Functions
def validate_date(date_str):
    try:
        date = datetime.datetime.strptime(date_str, "%Y-%m-%d").date()
        if date < datetime.date.today():
            print("Start date cannot be in the past")
            return None
        return date
    except ValueError:
        print("Invalid date format. Use YYYY-MM-DD")
        return None

def validate_location(name):
    """Basic validation for city names"""
    if not re.match(r"^[a-zA-Z\s\-']{2,50}$", name):
        print("Invalid location name. Use 2-50 characters (letters/spaces/hyphens)")
        return False
    return True

def get_user_input():
    print("\n" + "=" * 50)
    print("SMART INDIAN TRAVEL PLANNER".center(50))
    print("=" * 50)

    source = ""
    while not source or not validate_location(source):
        source = input("\nFrom which city are you starting? ").strip()

    destination = ""
    while not destination or not validate_location(destination):
        destination = input("Where are you going? ").strip()

    start_date = None
    while not start_date:
        start_date = validate_date(input("Start date (YYYY-MM-DD): ").strip())

    duration = 0
    while duration < 1:
        try:
            duration = int(input("Trip duration (days, min 1): "))
            if duration < 1:
                print("Duration must be at least 1 day")
        except ValueError:
            print("Please enter a valid number")

    adults = 0
    children = 0
    while adults + children < 1:
        try:
            adults = int(input("Number of adults: "))
            children = int(input("Number of children: "))
            if adults + children == 0:
                print("At least 1 traveler required")
        except ValueError:
            print("Please enter valid numbers")

    budget = 0
    while budget < 100:
        try:
            budget = float(input("Your total budget (INR): "))
            if budget < 100:
                print("Budget must be at least ₹100")
        except ValueError:
            print("Please enter a valid amount")

    trip_type = ""
    valid_trip_types = ["solo", "couple", "family", "adventure", "cultural", "religious"]
    while trip_type not in valid_trip_types:
        trip_type = input("Trip type (solo/couple/family/adventure/cultural/religious): ").strip().lower()
        if trip_type not in valid_trip_types:
            print(f"Invalid type. Choose from: {', '.join(valid_trip_types)}")

    print("=" * 50)
    return {
        "source": source,
        "destination": destination,
        "start_date": start_date.isoformat(),
        "duration": duration,
        "adults": adults,
        "children": children,
        "budget": budget,
        "trip_type": trip_type
    }

def generate_comprehensive_plan(user_input):
    print("\nGenerating comprehensive travel plan...")

    try:
        # Calculate end date
        start_date = datetime.date.fromisoformat(user_input["start_date"])
        end_date = start_date + datetime.timedelta(days=user_input["duration"] - 1)

        prompt = f"""
        Create a detailed JSON travel plan according to EXACTLY this structure:
        {{
            "trip_summary": {{...}},
            "transportation": {{
                "trains": [{{...}}],
                "flights": [{{...}}],
                "buses": [{{...}}]
            }},
            "accommodation": [{{...}}],
            "itinerary": [{{...}}],
            "budget_breakdown": {{...}},
            "recommendations": {{...}}
        }}
        
        Travel details:
        - From: {user_input["source"]} to {user_input["destination"]} (round trip)
        - Dates: {user_input["start_date"]} to {end_date.isoformat()} ({user_input["duration"]} days)
        - Travelers: {user_input["adults"]} adults, {user_input["children"]} children
        - Budget: ₹{user_input["budget"]:,.0f}
        - Trip type: {user_input["trip_type"]}

        IMPORTANT RULES:
        0. Sometimes you give wrong trains like shiv ganga express is coming for kolkata to varanasi which doesnot go to kolkata and rather goes to delhi.
        1. MUST include return journey to {user_input["source"]}
        2. Use ONLY this JSON structure with separate transportation sections
        3. For train links: Use 'https://www.redbus.in/trains/train-name-train-number' format
        4. Make sure the train is right and double check it and dont give wrong trains
        5. Include REALISTIC pricing for India
        6. Buffer must be exactly 10% of total costs
        7. budget_breakdown.total_estimated MUST match sum of categories
        8. Itinerary must cover ALL {user_input["duration"]} days
        9. Double check everything and make sure you are not sharing wrong information 
        10. Use separate sections for trains, flights, and buses in transportation

        EXAMPLE TRANSPORTATION STRUCTURE:
        "transportation": {{
            "trains": [
                {{
                    "segment": "Kolkata to Varanasi",
                    "name": "Howrah-Jodhpur Superfast Express",
                    "number": "12309",
                    "departure": {{"station": "Kolkata Howrah", "time": "21:30", "date": "2025-08-21"}},
                    "arrival": {{"station": "Varanasi Junction", "time": "19:15", "date": "2025-08-22"}},
                    "duration": "21h 45m",
                    "class": "AC 3-Tier",
                    "cost_per_adult": 1200,
                    "cost_per_child": 800,
                    "total_cost": 4000,
                    "booking_link": "https://www.redbus.in/trains/howrah-jodhpur-superfast-express-12309"
                }}
            ],
            "flights": [
                {{
                    "segment": "Varanasi to Kolkata",
                    "airline": "IndiGo",
                    "flight_number": "6E-123",
                    "departure": {{"airport": "Varanasi Airport (VNS)", "time": "10:30", "date": "2025-08-25"}},
                    "arrival": {{"airport": "Kolkata Airport (CCU)", "time": "12:45", "date": "2025-08-25"}},
                    "duration": "2h 15m",
                    "class": "Economy",
                    "cost_per_adult": 4500,
                    "cost_per_child": 4000,
                    "total_cost": 17000,
                    "booking_link": "https://www.goindigo.in/"
                }}
            ],
            "buses": []
        }}

        If you're unsure about a train, RESEARCH before including it.
        """

        response = client.chat.completions.create(
            model=LLM_MODEL,
            messages=[
                {
                    "role": "system",
                    "content": "You are an expert travel planner for Indian destinations. Output valid JSON ONLY with separate transportation sections."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            temperature=0.3,
            response_format={"type": "json_object"},
            timeout=120  # Increased timeout for complex plans
        )
        
        # Basic JSON validation
        plan = json.loads(response.choices[0].message.content)
        
        # Check for required keys
        required_keys = [
            "trip_summary", 
            "transportation", 
            "accommodation", 
            "itinerary", 
            "budget_breakdown", 
            "recommendations"
        ]
        
        # Check for transportation sub-sections
        transportation_sections = ["trains", "flights", "buses"]
        
        if not all(key in plan for key in required_keys):
            raise ValueError("Incomplete JSON structure from API")
            
        if not all(section in plan["transportation"] for section in transportation_sections):
            raise ValueError("Transportation sections incomplete")
            
        return plan

    except Exception as e:
        print(f"Error generating travel plan: {str(e)}")
        return {
            "error": "Failed to generate travel plan",
            "details": str(e)
        }

def save_plan_to_file(plan, filename="travel_plan.json"):
    try:
        with open(filename, 'w') as f:
            json.dump(plan, f, indent=2)
        print(f"\nPlan saved to {filename}")
        return True
    except Exception as e:
        print(f"Error saving file: {str(e)}")
        return False

def display_plan(plan):
    try:
        print(json.dumps(plan, indent=2))
        print("\n" + "=" * 50)
        print("TRAVEL PLAN GENERATED SUCCESSFULLY".center(50))
        print("=" * 50)
        
        # Show budget comparison
        budget = plan.get('trip_summary', {}).get('total_budget', 0)
        estimated = plan.get('budget_breakdown', {}).get('total_estimated', 0)
        status = "Within budget" if estimated <= budget else "Over budget"
        
        print(f"Budget: ₹{budget:,.0f} | Estimated: ₹{estimated:,.0f} | Status: {status}")
        print("=" * 50)
        print("Disclaimer: Verify all details before booking. Prices are estimates.")
        print("=" * 50)
        
        return True
    except Exception as e:
        print(f"Error displaying travel plan: {str(e)}")
        return False

def main():
    user_input = get_user_input()
    plan = generate_comprehensive_plan(user_input)

    if "error" not in plan:
        display_plan(plan)
        if input("\nSave to file? (y/n): ").lower() == 'y':
            filename = input("Filename (default: travel_plan.json): ").strip() or "travel_plan.json"
            save_plan_to_file(plan, filename)
    else:
        print("\nFailed to create travel plan:")
        print(plan["details"])

if __name__ == "__main__":
    main()
