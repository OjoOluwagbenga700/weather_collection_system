30 Days DevOps Challenge - Weather Dashboard

Day 1: Building a weather data collection system using AWS S3 and OpenWeather API

Weather Data Collection System - DevOps Day 1 Challenge

Project Overview
This project is a Weather Data Collection System that demonstrates core DevOps principles by combining:

External API Integration (OpenWeather API)
Cloud Storage (AWS S3)
Infrastructure as Code
Version Control (Git)
Python Development
Error Handling
Environment Management

Features: 
Terraform codes deploys an EC2 instance in the default VPC that runs a python script that : 
Fetches real-time weather data for multiple cities
Displays temperature (°F), humidity, and weather conditions
Automatically stores weather data in AWS S3
Supports multiple cities tracking
Timestamps all data for historical tracking

Technical Architecture
IAC: Terraform
Language: Python 3.x
Cloud Provider: AWS (S3)
External API: OpenWeather API
Dependencies:
boto3 (AWS SDK)
python-dotenv
requests

## Setup Instructions
1. Clone the repository and CD into the project directory
--bash
git clone 

2. Configure environment variables (.env) in the root of your project directory
OPENWEATHER_API_KEY=your_api_key
AWS_BUCKET_NAME=your_bucket_name


3. Run Terraform Init
This will initialiaze the neccessary plugins for infrastructure deployment


4. Run Terraform Plan
This will preview all the resources that terraform will deploy 


5. Run Terraform Apply
This will Deploy all the resources on AWS, SSH into the EC2 instance and then run the phyton script(weather_dashboard.py )  that will fetch data from the External API (OpenWeatherAPI) and then save the formated JSON data in S3.

5. Confirm Resources and Data uploaded to S3


What I Learned

AWS S3 bucket creation and management
Environment variable management for secure API keys
Git workflow for project development
Error handling in distributed systems
Cloud resource management

Future Enhancements

Add weather forecasting
Implement data visualization
Add more cities
Create automated testing
Set up CI/CD pipeline