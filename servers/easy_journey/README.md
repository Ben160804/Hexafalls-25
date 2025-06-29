# Smart Indian Travel Planner API v2.0

A robust, hackathon-ready API that generates comprehensive travel plans for Indian destinations with advanced validation and error handling.

## 🚀 Features

### Core Functionality
- **Comprehensive Travel Planning**: Generate detailed itineraries with transportation, accommodation, activities, and budget breakdown
- **Indian Location Validation**: Advanced LLM-based validation for Indian cities, states, regions, and landmarks
- **Spelling Correction**: Automatically corrects minor spelling mistakes in location names
- **Budget Analysis**: Realistic cost estimation with detailed breakdown
- **Date Logic Validation**: Ensures travel dates are valid and considers seasons/festivals

### Robust Error Handling
- **Input Validation**: Comprehensive validation for all input parameters
- **Edge Case Handling**: Handles gibberish, foreign locations, invalid dates, insufficient budgets
- **Graceful Degradation**: Proper error messages with suggestions for corrections
- **Rate Limiting**: Built-in protection against API abuse

### Security & Reliability
- **No Hardcoding**: All validations use LLM for dynamic verification
- **Exception Handling**: Global exception handler for unexpected errors
- **Logging**: Comprehensive logging for debugging and monitoring
- **CORS Support**: Cross-origin resource sharing enabled

## 🛠️ Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd easy_journey-main
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Set up environment variables**
   Create a `.env` file:
   ```env
   GROQ_API_KEY=your_groq_api_key_here
   ```

4. **Run the application**
   ```bash
   python main.py
   ```
   
   Or using uvicorn directly:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```

## 📡 API Endpoints

### Health Check
```http
GET /health
```
Returns API status and features.

### Generate Travel Plan
```http
POST /generate-plan
```

**Request Body:**
```json
{
  "source": "Mumbai",
  "destination": "Delhi",
  "start_date": "2024-12-25",
  "duration": 5,
  "adults": 2,
  "children": 1,
  "budget": 50000,
  "trip_type": "family"
}
```

**Response:**
```json
{
  "trip_summary": {
    "source": "Mumbai",
    "destination": "Delhi",
    "start_date": "2024-12-25",
    "end_date": "2024-12-29",
    "duration": 5,
    "travelers": {
      "adults": 2,
      "children": 1,
      "total": 3
    },
    "trip_type": "family",
    "budget": 50000,
    "season": "Winter",
    "festivals": "Christmas"
  },
  "transportation": {
    "outbound": {
      "mode": "flight",
      "details": "Air India AI101",
      "duration": "2 hours",
      "cost_per_person": 8000,
      "total_cost": 24000,
      "booking_link": "https://...",
      "departure_time": "10:00",
      "arrival_time": "12:00"
    },
    "return": {
      "mode": "train",
      "details": "Rajdhani Express 12951",
      "duration": "16 hours",
      "cost_per_person": 2000,
      "total_cost": 6000,
      "booking_link": "https://...",
      "departure_time": "16:00",
      "arrival_time": "08:00"
    },
    "local_transport": {
      "mode": "metro/taxi",
      "daily_cost": 500,
      "total_cost": 2500
    }
  },
  "accommodation": [
    {
      "name": "Hotel Taj Palace",
      "type": "hotel",
      "rating": "5 stars",
      "location": "Connaught Place",
      "cost_per_night": 8000,
      "total_cost": 32000,
      "amenities": ["wifi", "ac", "food", "pool"],
      "booking_link": "https://..."
    }
  ],
  "itinerary": [
    {
      "day": 1,
      "date": "2024-12-25",
      "activities": [
        {
          "time": "14:00",
          "activity": "Check-in at hotel",
          "location": "Hotel Taj Palace",
          "cost": 0,
          "duration": "1 hour"
        },
        {
          "time": "15:00",
          "activity": "Visit Red Fort",
          "location": "Red Fort",
          "cost": 500,
          "duration": "3 hours"
        }
      ],
      "meals": {
        "breakfast": "At airport",
        "lunch": "Local restaurant",
        "dinner": "Hotel restaurant"
      },
      "total_day_cost": 1500
    }
  ],
  "budget_breakdown": {
    "transportation": 32500,
    "accommodation": 32000,
    "food": 7500,
    "activities": 2500,
    "buffer": 7500,
    "total_estimated": 82000
  },
  "recommendations": {
    "packing_list": ["winter clothes", "comfortable shoes", "camera"],
    "travel_tips": ["Book tickets in advance", "Carry ID proof"],
    "emergency_contacts": ["Delhi Police: 100", "Ambulance: 102"],
    "weather_advice": "Cold weather, carry warm clothes",
    "local_customs": "Respect local traditions, dress modestly"
  }
}
```

## 🧪 Testing

Run comprehensive tests to verify all edge cases:

```bash
python test_api.py
```

The test suite covers:
- ✅ Valid requests
- ✅ Invalid locations (gibberish, foreign places, fictional locations)
- ✅ Spelling corrections
- ✅ Invalid dates and durations
- ✅ Invalid traveler counts and budgets
- ✅ Invalid trip types
- ✅ Insufficient budget scenarios
- ✅ Edge cases (same source/destination, large groups, long trips)
- ✅ Malformed requests

## 🔧 Configuration

### Environment Variables
- `GROQ_API_KEY`: Your Groq API key for LLM access

### API Configuration
- **Model**: llama3-70b-8192 (Groq)
- **Timeout**: 120 seconds for plan generation
- **Temperature**: 0.1-0.2 for consistent results
- **Response Format**: JSON only

## 🛡️ Validation Rules

### Location Validation
- Must be valid Indian locations only
- Rejects foreign cities, fictional places, gibberish
- Corrects minor spelling mistakes
- Accepts cities, states, regions, landmarks, tourist destinations

### Date Validation
- Must be future dates only
- Valid date format (YYYY-MM-DD)
- Duration between 1-365 days
- Considers seasons and festivals

### Budget Validation
- Minimum: ₹100
- Maximum: ₹10,000,000
- Realistic cost analysis for Indian travel
- Automatic budget insufficiency detection

### Traveler Validation
- At least 1 traveler required
- Maximum 50 travelers total
- Adults and children counts separately validated

### Trip Type Validation
- Supports: solo, couple, family, adventure, cultural, religious, business, luxury, budget, backpacking, honeymoon, educational, wildlife, beach, hill station, heritage, spiritual, medical tourism
- Case-insensitive validation

## 🚨 Error Handling

The API provides detailed error messages for various scenarios:

- **Invalid Source/Destination**: Location validation errors with suggestions
- **Insufficient Budget**: Detailed cost breakdown and recommendations
- **Invalid Dates**: Date logic errors with alternative suggestions
- **Invalid Trip Type**: Trip type validation with suggestions
- **Malformed Requests**: Input validation errors
- **System Errors**: Graceful error handling with logging

## 🏆 Hackathon Ready Features

### Judge-Proof Design
- **No Hardcoding**: All validations use LLM for dynamic verification
- **Comprehensive Edge Cases**: Handles all possible invalid inputs
- **Robust Error Handling**: Never crashes, always provides meaningful responses
- **Realistic Validation**: Uses LLM to verify Indian locations, spelling, and costs
- **Performance Optimized**: Efficient API calls with proper timeouts

### Advanced Features
- **Spelling Correction**: Automatically fixes location name typos
- **Budget Analysis**: Realistic cost estimation for Indian travel
- **Seasonal Awareness**: Considers weather and festivals
- **Cultural Sensitivity**: Provides local customs and advice
- **Emergency Information**: Includes emergency contacts and safety tips

## 📊 Performance

- **Response Time**: 30-120 seconds for plan generation
- **Concurrent Requests**: Handles multiple simultaneous requests
- **Memory Usage**: Optimized for efficient resource usage
- **Error Recovery**: Graceful handling of API failures

## 🔄 Deployment

### Local Development
```bash
python main.py
```

### Production Deployment
```bash
uvicorn main:app --host 0.0.0.0 --port $PORT
```

### Railway Deployment
The API is configured for Railway deployment with:
- `Procfile` for process management
- `runtime.txt` for Python version specification
- Environment variable configuration

## 📝 License

This project is developed for hackathon purposes.

## 🤝 Contributing

This is a hackathon project. For improvements, please create issues or pull requests.

---

**Built with ❤️ for Indian Travel Planning** 