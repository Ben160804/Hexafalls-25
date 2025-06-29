# Journeyease

A comprehensive Flutter-based travel companion app that provides intelligent journey planning, train delay predictions, last-minute alternatives, and AI-powered travel assistance.

![TrainBuddy Landing Page](images/landing_page.png)

## 🚀 Features

### 1. Smart Journey Planning
![Journey Planning](images/journey_planning.png)

Plan your complete journey with intelligent recommendations:
- **Source to Destination Planning**: Enter your starting point and destination
- **Budget Optimization**: Set your budget and get cost-effective travel plans
- **Group Travel Support**: Specify number of travelers for group bookings
- **Date-based Planning**: Choose your travel dates with seasonal considerations
- **Comprehensive Itineraries**: Get detailed plans including transportation, accommodation, and activities

*Backend: [Smart Indian Travel Planner API](servers/easy_journey/README.md)*

### 2. Train Delay Prediction
![Train Delay Prediction](images/train_delay_prediction.png)

Predict train delays using in-house built ML models:
- **Real-time Predictions**: Get delay estimates for any train
- **ML-Powered Accuracy**: Advanced machine learning algorithms
- **Schedule Integration**: View complete schedules with predicted delays
- **Station-wise Analysis**: Track delays at each station
- **Historical Data**: Learn from past performance patterns

*Backend: [Train Delay Prediction API](servers/train_delay_backend/README.md)*

### 3. Last-Minute Alternative Trains
![Alternative Trains](images/alternative_trains.png)

Never miss your journey with emergency alternatives:
- **Quick Train Search**: Find upcoming trains instantly
- **Emergency Assistance**: Perfect for missed train scenarios
- **Real-time Availability**: Live data from Indian Railways
- **Booking Classes**: View available seating options
- **Route Alternatives**: Discover different travel routes

*Backend: [Indian Railways Train Scraper](servers/alt_trains/README.md)*

### 4. AI Travel Assistant
![Travel Chatbot](images/travel_chatbot.png)

Your personal travel companion powered by AI:
- **Tour Spot Recommendations**: Discover the best places to visit
- **Dining Suggestions**: Find local restaurants and cuisines
- **Travel Planning Help**: Get personalized travel advice
- **Interactive Conversations**: Natural language interaction
- **Context-Aware Responses**: Remembers your preferences

*Backend: [Gemini 2.0 API Chat Server](servers/chatbot/README.md)*

## 📱 App Structure

- **Frontend**: Flutter app in `trainbuddy/` folder
- **Backend Services**: Multiple microservices in `servers/` folder
  - `easy_journey/` - Journey planning API
  - `train_delay_backend/` - Delay prediction service
  - `alt_trains/` - Alternative trains finder
  - `chatbot/` - AI travel assistant

## 🛠️ Technology Stack

- **Frontend**: Flutter (Cross-platform mobile app)
- **Backend**: Python (FastAPI/Flask), Go
- **AI/ML**: Custom ML models, Google Gemini 2.0
- **Data Sources**: Indian Railways APIs, etrain.info
- **Deployment**: Render, Cloud platforms

## 🚀 Getting Started

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Hexafalls-25
   ```

2. **Set up the Flutter app**
   ```bash
   cd trainbuddy
   flutter pub get
   flutter run
   ```

3. **Configure backend services**
   - Follow individual README files in each `servers/` subdirectory
   - Set up required API keys and environment variables

## 📸 Screenshots

All screenshots are optimized for Android aspect ratio (9:16) and stored in the `images/` folder:
- `landing_page.png` - Main app landing page
- `journey_planning.png` - Journey planning feature
- `train_delay_prediction.png` - Delay prediction interface
- `alternative_trains.png` - Alternative trains finder
- `travel_chatbot.png` - AI travel assistant

## 🤝 Contributing

This project was developed for Hexafalls-25 hackathon. For contributions:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is part of the Hexafalls-25 hackathon submission.
