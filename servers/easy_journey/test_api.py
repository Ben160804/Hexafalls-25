#!/usr/bin/env python3

"""Test script for the Smart Indian Travel Planner API"""

import requests
import json
import sys
import time
from datetime import datetime, timedelta

# Configuration
BASE_URL = "http://localhost:8000"  # Change this to your Railway URL when deployed

def test_health():
    """Test health endpoint"""
    print("Testing health endpoint...")
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    print()

def test_valid_request():
    """Test a valid travel request"""
    print("Testing valid travel request...")
    data = {
        "source": "Mumbai",
        "destination": "Delhi",
        "start_date": "2024-12-25",
        "duration": 5,
        "adults": 2,
        "children": 1,
        "budget": 50000,
        "trip_type": "family"
    }
    
    response = requests.post(f"{BASE_URL}/generate-plan", json=data)
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        result = response.json()
        print("✅ Valid request successful")
        print(f"Trip summary: {result['trip_summary']['source']} to {result['trip_summary']['destination']}")
        print(f"Total cost: ₹{result['budget_breakdown']['total_estimated']:,.0f}")
    else:
        print(f"❌ Valid request failed: {response.text}")
    print()

def test_invalid_locations():
    """Test various invalid location inputs"""
    print("Testing invalid locations...")
    
    invalid_locations = [
        "banana",  # gibberish
        "pluto",   # fictional place
        "new york",  # foreign city
        "tokyo",   # foreign city
        "mars",    # fictional place
        "12345",   # numbers
        "a",       # too short
        "x" * 101, # too long
        "",        # empty
        "   ",     # whitespace only
        "Mumbai@", # invalid characters
        "Delhi#",  # invalid characters
        "Chennai123", # mixed invalid
    ]
    
    for location in invalid_locations:
        data = {
            "source": location,
            "destination": "Mumbai",
            "start_date": "2024-12-25",
            "duration": 3,
            "adults": 1,
            "children": 0,
            "budget": 10000,
            "trip_type": "solo"
        }
        
        response = requests.post(f"{BASE_URL}/generate-plan", json=data)
        print(f"Source '{location}': {response.status_code} - {response.text[:100]}...")
    
    print()

def test_spelling_corrections():
    """Test location spelling corrections"""
    print("Testing spelling corrections...")
    
    misspelled_locations = [
        "Mumbay",      # should correct to Mumbai
        "Dilli",       # should correct to Delhi
        "Bangalore",   # should correct to Bengaluru
        "Calcutta",    # should correct to Kolkata
        "Madras",      # should correct to Chennai
        "Bombay",      # should correct to Mumbai
    ]
    
    for location in misspelled_locations:
        data = {
            "source": "Mumbai",
            "destination": location,
            "start_date": "2024-12-25",
            "duration": 3,
            "adults": 1,
            "children": 0,
            "budget": 10000,
            "trip_type": "solo"
        }
        
        response = requests.post(f"{BASE_URL}/generate-plan", json=data)
        print(f"Destination '{location}': {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"  ✅ Corrected to: {result['trip_summary']['destination']}")
        else:
            print(f"  ❌ Failed: {response.text[:100]}...")
    
    print()

def test_invalid_dates():
    """Test various invalid date inputs"""
    print("Testing invalid dates...")
    
    invalid_dates = [
        "2023-01-01",  # past date
        "2024-13-01",  # invalid month
        "2024-12-32",  # invalid day
        "2024/12/25",  # wrong format
        "25-12-2024",  # wrong format
        "2024-12-25T10:00:00",  # datetime instead of date
        "invalid",     # gibberish
        "",           # empty
        "2024-02-30", # invalid date (February 30)
    ]
    
    for date in invalid_dates:
        data = {
            "source": "Mumbai",
            "destination": "Delhi",
            "start_date": date,
            "duration": 3,
            "adults": 1,
            "children": 0,
            "budget": 10000,
            "trip_type": "solo"
        }
        
        response = requests.post(f"{BASE_URL}/generate-plan", json=data)
        print(f"Date '{date}': {response.status_code} - {response.text[:100]}...")
    
    print()

def test_invalid_durations():
    """Test invalid duration values"""
    print("Testing invalid durations...")
    
    invalid_durations = [
        0,      # zero
        -1,     # negative
        366,    # too long
        1000,   # very long
        "3",    # string instead of int
        3.5,    # float instead of int
    ]
    
    for duration in invalid_durations:
        data = {
            "source": "Mumbai",
            "destination": "Delhi",
            "start_date": "2024-12-25",
            "duration": duration,
            "adults": 1,
            "children": 0,
            "budget": 10000,
            "trip_type": "solo"
        }
        
        response = requests.post(f"{BASE_URL}/generate-plan", json=data)
        print(f"Duration {duration}: {response.status_code} - {response.text[:100]}...")
    
    print()

def test_invalid_travelers():
    """Test invalid traveler counts"""
    print("Testing invalid traveler counts...")
    
    invalid_travelers = [
        {"adults": 0, "children": 0},  # no travelers
        {"adults": -1, "children": 0}, # negative adults
        {"adults": 0, "children": -1}, # negative children
        {"adults": 51, "children": 0}, # too many adults
        {"adults": 0, "children": 51}, # too many children
        {"adults": 25, "children": 26}, # too many total
    ]
    
    for travelers in invalid_travelers:
        data = {
            "source": "Mumbai",
            "destination": "Delhi",
            "start_date": "2024-12-25",
            "duration": 3,
            "adults": travelers["adults"],
            "children": travelers["children"],
            "budget": 10000,
            "trip_type": "solo"
        }
        
        response = requests.post(f"{BASE_URL}/generate-plan", json=data)
        print(f"Travelers {travelers}: {response.status_code} - {response.text[:100]}...")
    
    print()

def test_invalid_budgets():
    """Test invalid budget values"""
    print("Testing invalid budgets...")
    
    invalid_budgets = [
        50,     # too low
        0,      # zero
        -100,   # negative
        10000001, # too high
        "1000", # string instead of number
        1000.5, # float (should work)
    ]
    
    for budget in invalid_budgets:
        data = {
            "source": "Mumbai",
            "destination": "Delhi",
            "start_date": "2024-12-25",
            "duration": 3,
            "adults": 1,
            "children": 0,
            "budget": budget,
            "trip_type": "solo"
        }
        
        response = requests.post(f"{BASE_URL}/generate-plan", json=data)
        print(f"Budget {budget}: {response.status_code} - {response.text[:100]}...")
    
    print()

def test_invalid_trip_types():
    """Test invalid trip types"""
    print("Testing invalid trip types...")
    
    invalid_trip_types = [
        "invalid_type",
        "random",
        "xyz",
        "",
        "   ",
        "FAMILY",  # should be case insensitive
        "Family",
        "123",
        "type@",
    ]
    
    for trip_type in invalid_trip_types:
        data = {
            "source": "Mumbai",
            "destination": "Delhi",
            "start_date": "2024-12-25",
            "duration": 3,
            "adults": 1,
            "children": 0,
            "budget": 10000,
            "trip_type": trip_type
        }
        
        response = requests.post(f"{BASE_URL}/generate-plan", json=data)
        print(f"Trip type '{trip_type}': {response.status_code} - {response.text[:100]}...")
    
    print()

def test_insufficient_budgets():
    """Test insufficient budget scenarios"""
    print("Testing insufficient budgets...")
    
    budget_scenarios = [
        {"source": "Mumbai", "destination": "Delhi", "budget": 1000, "duration": 5},  # very low budget
        {"source": "Mumbai", "destination": "Kolkata", "budget": 5000, "duration": 7}, # low budget for long distance
        {"source": "Delhi", "destination": "Chennai", "budget": 2000, "duration": 3},  # very low budget
    ]
    
    for scenario in budget_scenarios:
        data = {
            "source": scenario["source"],
            "destination": scenario["destination"],
            "start_date": "2024-12-25",
            "duration": scenario["duration"],
            "adults": 2,
            "children": 1,
            "budget": scenario["budget"],
            "trip_type": "family"
        }
        
        response = requests.post(f"{BASE_URL}/generate-plan", json=data)
        print(f"Budget ₹{scenario['budget']} for {scenario['source']} to {scenario['destination']}: {response.status_code}")
        if response.status_code == 400:
            print(f"  ❌ Insufficient budget detected: {response.text[:100]}...")
        else:
            print(f"  ✅ Budget accepted")
    
    print()

def test_edge_cases():
    """Test various edge cases"""
    print("Testing edge cases...")
    
    edge_cases = [
        # Same source and destination
        {
            "source": "Mumbai",
            "destination": "Mumbai",
            "start_date": "2024-12-25",
            "duration": 1,
            "adults": 1,
            "children": 0,
            "budget": 5000,
            "trip_type": "solo"
        },
        # Very short trip
        {
            "source": "Mumbai",
            "destination": "Pune",
            "start_date": "2024-12-25",
            "duration": 1,
            "adults": 1,
            "children": 0,
            "budget": 5000,
            "trip_type": "solo"
        },
        # Very long trip
        {
            "source": "Mumbai",
            "destination": "Delhi",
            "start_date": "2024-12-25",
            "duration": 30,
            "adults": 1,
            "children": 0,
            "budget": 100000,
            "trip_type": "solo"
        },
        # Large group
        {
            "source": "Mumbai",
            "destination": "Goa",
            "start_date": "2024-12-25",
            "duration": 5,
            "adults": 10,
            "children": 5,
            "budget": 200000,
            "trip_type": "family"
        },
    ]
    
    for i, case in enumerate(edge_cases):
        print(f"Edge case {i+1}: {case['source']} to {case['destination']} for {case['duration']} days")
        response = requests.post(f"{BASE_URL}/generate-plan", json=case)
        print(f"  Status: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"  ✅ Success - Cost: ₹{result['budget_breakdown']['total_estimated']:,.0f}")
        else:
            print(f"  ❌ Failed: {response.text[:100]}...")
        print()

def test_malformed_requests():
    """Test malformed JSON requests"""
    print("Testing malformed requests...")
    
    # Missing fields
    incomplete_data = {
        "source": "Mumbai",
        "destination": "Delhi",
        # missing other fields
    }
    
    response = requests.post(f"{BASE_URL}/generate-plan", json=incomplete_data)
    print(f"Incomplete data: {response.status_code} - {response.text[:100]}...")
    
    # Extra fields
    extra_data = {
        "source": "Mumbai",
        "destination": "Delhi",
        "start_date": "2024-12-25",
        "duration": 3,
        "adults": 1,
        "children": 0,
        "budget": 10000,
        "trip_type": "solo",
        "extra_field": "should be ignored"
    }
    
    response = requests.post(f"{BASE_URL}/generate-plan", json=extra_data)
    print(f"Extra fields: {response.status_code}")
    if response.status_code == 200:
        print("  ✅ Extra fields ignored successfully")
    else:
        print(f"  ❌ Failed: {response.text[:100]}...")
    
    print()

def run_all_tests():
    """Run all tests"""
    print("🚀 Starting comprehensive API tests...")
    print("=" * 60)
    
    tests = [
        test_health,
        test_valid_request,
        test_invalid_locations,
        test_spelling_corrections,
        test_invalid_dates,
        test_invalid_durations,
        test_invalid_travelers,
        test_invalid_budgets,
        test_invalid_trip_types,
        test_insufficient_budgets,
        test_edge_cases,
        test_malformed_requests,
    ]
    
    for test in tests:
        try:
            test()
            time.sleep(1)  # Rate limiting
        except Exception as e:
            print(f"❌ Test {test.__name__} failed: {str(e)}")
            print()
    
    print("=" * 60)
    print("✅ All tests completed!")

if __name__ == "__main__":
    run_all_tests() 