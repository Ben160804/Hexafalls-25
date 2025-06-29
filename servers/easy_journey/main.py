import os
import json
import re
import datetime
import time
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from groq import Groq
from dotenv import load_dotenv
from pydantic import BaseModel, validator
from typing import Dict, Any, Optional
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Smart Indian Travel Planner API",
    description="Generates detailed travel plans for Indian destinations with comprehensive validation",
    version="2.0"
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load environment variables
load_dotenv()

# Configuration
GROQ_API_KEY = os.environ.get("GROQ_API_KEY")
if not GROQ_API_KEY:
    raise RuntimeError("GROQ_API_KEY environment variable not set")

LLM_MODEL = "llama3-70b-8192"
client = Groq(api_key=GROQ_API_KEY)

# Pydantic Models with enhanced validation
class TravelRequest(BaseModel):
    source: str
    destination: str
    start_date: str
    duration: int
    adults: int
    children: int
    budget: float
    trip_type: str

    @validator('source', 'destination')
    def validate_location_format(cls, v):
        if not v or not isinstance(v, str):
            raise ValueError("Location must be a non-empty string")
        if len(v.strip()) < 2 or len(v.strip()) > 100:
            raise ValueError("Location must be between 2 and 100 characters")
        if not re.match(r"^[a-zA-Z\s\-'\.]{2,100}$", v.strip()):
            raise ValueError("Location contains invalid characters")
        return v.strip()

    @validator('start_date')
    def validate_date_format(cls, v):
        if not v or not isinstance(v, str):
            raise ValueError("Start date must be a string")
        try:
            datetime.datetime.strptime(v, "%Y-%m-%d")
        except ValueError:
            raise ValueError("Start date must be in YYYY-MM-DD format")
        return v

    @validator('duration')
    def validate_duration(cls, v):
        if not isinstance(v, int) or v < 1 or v > 365:
            raise ValueError("Duration must be between 1 and 365 days")
        return v

    @validator('adults', 'children')
    def validate_travelers(cls, v):
        if not isinstance(v, int) or v < 0 or v > 50:
            raise ValueError("Number of travelers must be between 0 and 50")
        return v

    @validator('budget')
    def validate_budget(cls, v):
        if not isinstance(v, (int, float)) or v < 100 or v > 10000000:
            raise ValueError("Budget must be between ₹100 and ₹10,000,000")
        return float(v)

    @validator('trip_type')
    def validate_trip_type(cls, v):
        if not v or not isinstance(v, str):
            raise ValueError("Trip type must be a non-empty string")
        return v.strip().lower()

# Enhanced LLM-based validation functions
def llm_validate_indian_location(location: str, location_type: str = "location") -> Dict[str, Any]:
    """Comprehensive Indian location validation using LLM"""
    try:
        response = client.chat.completions.create(
            model=LLM_MODEL,
            messages=[
                {
                    "role": "system",
                    "content": """You are an expert in Indian geography and travel. Analyze the given location and respond with a JSON object containing:
                    {
                        "is_valid": true/false,
                        "is_indian": true/false,
                        "corrected_name": "correct spelling if needed",
                        "state": "state name if valid",
                        "type": "city/state/region/landmark",
                        "reason": "explanation for validation result"
                    }
                    
                    Rules:
                    1. Only Indian locations are valid
                    2. Check spelling accuracy
                    3. Reject gibberish, fictional places, foreign locations
                    4. Accept cities, states, regions, landmarks, tourist destinations
                    5. Provide corrected spelling if minor errors exist"""
                },
                {
                    "role": "user",
                    "content": f"Validate this {location_type}: '{location}'. Is it a valid Indian location with correct spelling?"
                }
            ],
            temperature=0.1,
            response_format={"type": "json_object"},
            timeout=30
        )
        
        result = json.loads(response.choices[0].message.content)
        return result
    except Exception as e:
        logger.error(f"LLM validation error for {location}: {str(e)}")
        return {
            "is_valid": False,
            "is_indian": False,
            "corrected_name": location,
            "state": "",
            "type": "unknown",
            "reason": f"Validation failed due to technical error: {str(e)}"
        }

def llm_validate_trip_type(trip_type: str) -> Dict[str, Any]:
    """Validate trip type using LLM"""
    try:
        response = client.chat.completions.create(
            model=LLM_MODEL,
            messages=[
                {
                    "role": "system",
                    "content": """You are a travel expert. Validate the trip type and respond with JSON:
                    {
                        "is_valid": true/false,
                        "suggested_type": "corrected type if needed",
                        "reason": "explanation"
                    }
                    
                    Valid types: solo, couple, family, adventure, cultural, religious, business, luxury, budget, backpacking, honeymoon, educational, wildlife, beach, hill station, heritage, spiritual, medical tourism"""
                },
                {
                    "role": "user",
                    "content": f"Is '{trip_type}' a valid trip type for Indian travel planning?"
                }
            ],
            temperature=0.1,
            response_format={"type": "json_object"},
            timeout=30
        )
        
        result = json.loads(response.choices[0].message.content)
        return result
    except Exception as e:
        logger.error(f"Trip type validation error: {str(e)}")
        return {
            "is_valid": False,
            "suggested_type": "family",
            "reason": f"Validation failed: {str(e)}"
        }

def calculate_minimum_budget(source: str, destination: str, duration: int, adults: int, children: int) -> Dict[str, Any]:
    """Calculate realistic minimum budget for Indian travel"""
    try:
        # Define base costs for different transportation modes
        transport_costs = {
            "local": {"train": 500, "bus": 300, "flight": 2000},  # Same city/state
            "medium": {"train": 1500, "bus": 800, "flight": 4000},  # Different states
            "long": {"train": 3000, "bus": 1500, "flight": 6000}  # Long distance
        }
        
        # Define accommodation costs per night
        accommodation_costs = {
            "budget": 800,      # Budget hotel/hostel
            "standard": 1500,   # 3-star hotel
            "luxury": 5000      # 5-star hotel
        }
        
        # Define daily costs
        daily_food = 500  # Per person per day
        daily_activities = 300  # Per person per day
        daily_local_transport = 200  # Per person per day
        
        # Estimate distance category based on common routes
        distance_category = "medium"  # Default to medium distance
        
        # Calculate transportation costs (round trip)
        transport_cost_per_person = transport_costs[distance_category]["train"] * 2  # Round trip
        total_transport = transport_cost_per_person * (adults + children)
        
        # Calculate accommodation costs
        accommodation_per_night = accommodation_costs["budget"] * adults + (accommodation_costs["budget"] * 0.5 * children)
        total_accommodation = accommodation_per_night * duration
        
        # Calculate daily costs
        total_food = daily_food * (adults + children) * duration
        total_activities = daily_activities * (adults + children) * duration
        total_local_transport = daily_local_transport * (adults + children) * duration
        
        # Calculate total
        subtotal = total_transport + total_accommodation + total_food + total_activities + total_local_transport
        buffer = subtotal * 0.1  # 10% buffer
        total_estimated = subtotal + buffer
        
        return {
            "is_sufficient": True,  # We'll let the plan generation handle budget validation
            "minimum_required": total_estimated,
            "recommended_budget": total_estimated * 1.2,
            "cost_breakdown": {
                "transportation": total_transport,
                "accommodation": total_accommodation,
                "food": total_food,
                "activities": total_activities,
                "local_transport": total_local_transport
            },
            "reason": f"Minimum budget calculated: ₹{total_estimated:,.0f}"
        }
    except Exception as e:
        logger.error(f"Budget calculation error: {str(e)}")
        return {
            "is_sufficient": True,
            "minimum_required": 5000,
            "recommended_budget": 10000,
            "cost_breakdown": {
                "transportation": 2000,
                "accommodation": 1500,
                "food": 1000,
                "activities": 300,
                "local_transport": 200
            },
            "reason": f"Budget calculation failed: {str(e)}"
        }

def llm_validate_date_logic(start_date: str, duration: int) -> Dict[str, Any]:
    """Validate date logic using LLM"""
    try:
        start_dt = datetime.date.fromisoformat(start_date)
        end_dt = start_dt + datetime.timedelta(days=duration - 1)
        today = datetime.date.today()
        
        response = client.chat.completions.create(
            model=LLM_MODEL,
            messages=[
                {
                    "role": "system",
                    "content": """You are a travel date validation expert. Analyze the dates and respond with JSON:
                    {
                        "is_valid": true/false,
                        "reason": "explanation",
                        "suggested_start_date": "YYYY-MM-DD if needed",
                        "season_info": "season and weather info",
                        "festival_info": "any major festivals during this period"
                    }"""
                },
                {
                    "role": "user",
                    "content": f"Start date: {start_date}, Duration: {duration} days, End date: {end_dt.isoformat()}, Today: {today.isoformat()}. Is this a valid travel period?"
                }
            ],
            temperature=0.1,
            response_format={"type": "json_object"},
            timeout=30
        )
        
        result = json.loads(response.choices[0].message.content)
        return result
    except Exception as e:
        logger.error(f"Date validation error: {str(e)}")
        return {
            "is_valid": False,
            "reason": f"Date validation failed: {str(e)}",
            "suggested_start_date": start_date,
            "season_info": "Unknown",
            "festival_info": "Unknown"
        }

# Enhanced plan generation with comprehensive validation
def generate_comprehensive_plan(user_input: Dict[str, Any]) -> Dict[str, Any]:
    try:
        # Step 1: Comprehensive location validation
        source_validation = llm_validate_indian_location(user_input["source"], "source")
        destination_validation = llm_validate_indian_location(user_input["destination"], "destination")
        
        if not source_validation["is_valid"]:
            return {
                "error": "invalid_source",
                "message": f"Source location error: {source_validation['reason']}",
                "suggestion": source_validation.get("corrected_name", "")
            }
        
        if not destination_validation["is_valid"]:
            return {
                "error": "invalid_destination", 
                "message": f"Destination error: {destination_validation['reason']}",
                "suggestion": destination_validation.get("corrected_name", "")
            }
        
        # Use corrected names if available
        source = source_validation.get("corrected_name", user_input["source"])
        destination = destination_validation.get("corrected_name", user_input["destination"])
        
        # Step 2: Trip type validation
        trip_type_validation = llm_validate_trip_type(user_input["trip_type"])
        if not trip_type_validation["is_valid"]:
            return {
                "error": "invalid_trip_type",
                "message": f"Trip type error: {trip_type_validation['reason']}",
                "suggestion": trip_type_validation.get("suggested_type", "family")
            }
        
        trip_type = trip_type_validation.get("suggested_type", user_input["trip_type"])
        
        # Step 3: Date validation
        date_validation = llm_validate_date_logic(user_input["start_date"], user_input["duration"])
        if not date_validation["is_valid"]:
            return {
                "error": "invalid_dates",
                "message": f"Date error: {date_validation['reason']}",
                "suggestion": date_validation.get("suggested_start_date", "")
            }
        
        # Step 4: Budget validation - Use simple calculation instead of LLM
        total_travelers = user_input["adults"] + user_input["children"]
        budget_validation = calculate_minimum_budget(
            source, 
            destination,
            user_input["duration"], 
            user_input["adults"],
            user_input["children"]
        )
        
        # Only check if budget is extremely low (less than 50% of minimum)
        if user_input["budget"] < budget_validation["minimum_required"] * 0.5:
            return {
                "error": "insufficient_budget",
                "required_budget": budget_validation["minimum_required"],
                "recommended_budget": budget_validation["recommended_budget"],
                "message": f"Budget too low for this trip. Minimum required: ₹{budget_validation['minimum_required']:,.0f}",
                "cost_breakdown": budget_validation["cost_breakdown"]
            }
        
        # Step 5: Generate comprehensive plan
        start_date = datetime.date.fromisoformat(user_input["start_date"])
        end_date = start_date + datetime.timedelta(days=user_input["duration"] - 1)

        prompt = f"""
        Create a detailed JSON travel plan according to EXACTLY this structure:
        {{
            "trip_summary": {{
                "source": "{source}",
                "destination": "{destination}",
                "start_date": "{user_input['start_date']}",
                "end_date": "{end_date.isoformat()}",
                "duration": {user_input["duration"]},
                "travelers": {{
                    "adults": {user_input["adults"]},
                    "children": {user_input["children"]},
                    "total": {total_travelers}
                }},
                "trip_type": "{trip_type}",
                "budget": {user_input["budget"]},
                "season": "{date_validation.get('season_info', 'Unknown')}",
                "festivals": "{date_validation.get('festival_info', 'None')}"
            }},
            "transportation": {{
                "outbound": {{
                    "mode": "train/flight/bus",
                    "details": "{{...}}",
                    "duration": "X hours",
                    "cost_per_person": 0,
                    "total_cost": 0,
                    "booking_link": "https://...",
                    "departure_time": "HH:MM",
                    "arrival_time": "HH:MM"
                }},
                "return": {{
                    "mode": "train/flight/bus", 
                    "details": "{{...}}",
                    "duration": "X hours",
                    "cost_per_person": 0,
                    "total_cost": 0,
                    "booking_link": "https://...",
                    "departure_time": "HH:MM",
                    "arrival_time": "HH:MM"
                }},
                "local_transport": {{
                    "mode": "metro/bus/taxi/auto",
                    "daily_cost": 0,
                    "total_cost": 0
                }}
            }},
            "accommodation": [
                {{
                    "name": "Hotel Name",
                    "type": "hotel/hostel/guesthouse",
                    "rating": "X stars",
                    "location": "area name",
                    "cost_per_night": 0,
                    "total_cost": 0,
                    "amenities": ["wifi", "ac", "food"],
                    "booking_link": "https://..."
                }}
            ],
            "itinerary": [
                {{
                    "day": 1,
                    "date": "YYYY-MM-DD",
                    "activities": [
                        {{
                            "time": "HH:MM",
                            "activity": "description",
                            "location": "place name",
                            "cost": 0,
                            "duration": "X hours"
                        }}
                    ],
                    "meals": {{
                        "breakfast": "{{...}}",
                        "lunch": "{{...}}", 
                        "dinner": "{{...}}"
                    }},
                    "total_day_cost": 0
                }}
            ],
            "budget_breakdown": {{
                "transportation": 0,
                "accommodation": 0,
                "food": 0,
                "activities": 0,
                "buffer": 0,
                "total_estimated": 0
            }},
            "recommendations": {{
                "packing_list": ["item1", "item2"],
                "travel_tips": ["tip1", "tip2"],
                "emergency_contacts": ["contact1", "contact2"],
                "weather_advice": "weather info",
                "local_customs": "cultural advice"
            }}
        }}
        
        CRITICAL REQUIREMENTS:
        0. Dont go over the budget of the user also use both and trains and planes and priotorise trains more than plane like use planes only if the budget is very very high
        1. ALL costs must be realistic for India in 2024
        2. Buffer must be exactly 10% of (transportation + accommodation + food + activities)
        3. total_estimated must equal sum of all categories
        4. Itinerary must cover ALL {user_input["duration"]} days
        5. Include return journey to {source}
        6. Use current Indian pricing (₹)
        7. Verify all transportation options exist
        8. Include realistic daily activities and meals
        9. Consider {trip_type} preferences
        10. Account for {total_travelers} travelers
        11. Stay within ₹{user_input["budget"]:,.0f} budget
        12. Include proper booking links
        13. Consider weather and festivals: {date_validation.get('season_info', '')}
        14. IMPORTANT: Use the user's budget to plan accordingly - don't always use minimum costs
        15. If budget is high, suggest better accommodation and activities
        16. If budget is low, suggest budget-friendly options
        19. Dont go over the budget stay in the budget 
        """

        response = client.chat.completions.create(
            model=LLM_MODEL,
            messages=[
                {
                    "role": "system",
                    "content": "You are an expert Indian travel planner. Generate detailed, realistic travel plans with accurate pricing and complete information. Output valid JSON ONLY."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            temperature=0.2,
            response_format={"type": "json_object"},
            timeout=120
        )
        
        # Parse and validate response
        plan = json.loads(response.choices[0].message.content)
        
        # Final validation of generated plan
        if "error" in plan:
            return plan
        
        # Validate required structure
        required_keys = ["trip_summary", "transportation", "accommodation", 
                         "itinerary", "budget_breakdown", "recommendations"]
        if not all(key in plan for key in required_keys):
            raise ValueError("Incomplete JSON structure from API")
        
        # Validate budget breakdown
        budget_keys = ["transportation", "accommodation", "food", 
                       "activities", "buffer", "total_estimated"]
        if not all(key in plan["budget_breakdown"] for key in budget_keys):
            raise ValueError("Incomplete budget breakdown structure")
        
        # Validate itinerary length
        if len(plan["itinerary"]) != user_input["duration"]:
            raise ValueError(f"Itinerary must have exactly {user_input['duration']} days")
        
        # Validate budget constraints - only check if it's way over budget
        total_estimated = plan["budget_breakdown"]["total_estimated"]
        if total_estimated > user_input["budget"] * 1.5:  # Allow 50% over budget
            return {
                "error": "insufficient_budget",
                "required_budget": total_estimated,
                "message": f"Generated plan exceeds budget significantly. Required: ₹{total_estimated:,.0f}, Available: ₹{user_input['budget']:,.0f}"
            }
        
        return plan

    except Exception as e:
        logger.error(f"Plan generation error: {str(e)}")
        return {"error": "plan_generation_failed", "details": str(e)}

@app.post("/generate-plan")
async def generate_plan(request: TravelRequest):
    try:
        user_input = request.dict()
        
        # Generate plan with comprehensive validation
        plan = generate_comprehensive_plan(user_input)
        
        # Handle specialized errors
        if "error" in plan:
            error_type = plan["error"]
            
            if error_type == "invalid_source":
                raise HTTPException(400, f"Source location error: {plan.get('message', 'Invalid Indian location')}")
            
            elif error_type == "invalid_destination":
                raise HTTPException(400, f"Destination error: {plan.get('message', 'Invalid Indian location')}")
            
            elif error_type == "invalid_trip_type":
                raise HTTPException(400, f"Trip type error: {plan.get('message', 'Invalid trip type')}")
            
            elif error_type == "invalid_dates":
                raise HTTPException(400, f"Date error: {plan.get('message', 'Invalid travel dates')}")
            
            elif error_type == "insufficient_budget":
                required = plan.get("required_budget", user_input["budget"] * 1.5)
                increase = required - user_input["budget"]
                message = plan.get("message", f"Increase budget by ₹{increase:,.0f} (Total required: ₹{required:,.0f})")
                raise HTTPException(400, f"Insufficient budget: {message}")
            
            else:
                raise HTTPException(500, f"Plan generation failed: {plan.get('details', 'Unknown error')}")
        
        return plan
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error in generate_plan: {str(e)}")
        raise HTTPException(500, f"Internal server error: {str(e)}")

@app.get("/health")
async def health_check():
    return {
        "status": "ok",
        "model": LLM_MODEL,
        "service": "Smart Indian Travel Planner v2.0",
        "features": [
            "Comprehensive LLM-based validation",
            "Indian location verification",
            "Spelling correction",
            "Budget analysis",
            "Date logic validation",
            "Trip type validation"
        ]
    }

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Global exception handler: {str(exc)}")
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error", "message": "An unexpected error occurred"}
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
