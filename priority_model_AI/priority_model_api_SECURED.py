"""
Priority AI Model API - WITH API KEY SECURITY
Copy this to replace priority_model_api (1).py or merge the security changes
"""

import torch
from transformers import DistilBertTokenizerFast, DistilBertForSequenceClassification
import json
import pandas as pd
from typing import Dict, Any
import os

class PriorityClassifier:
    def __init__(self, model_path: str = "priority_ai_model"):
        """
        Initialize the Priority Classifier
        
        Args:
            model_path: Path to the saved model directory
        """
        self.model_path = model_path
        self.model = None
        self.tokenizer = None
        self.load_model()
    
    def load_model(self):
        """Load the trained model and tokenizer"""
        try:
            self.tokenizer = DistilBertTokenizerFast.from_pretrained(self.model_path)
            self.model = DistilBertForSequenceClassification.from_pretrained(self.model_path)
            self.model.eval()  # Set to evaluation mode
            print("✅ Model loaded successfully!")
        except Exception as e:
            print(f"❌ Error loading model: {e}")
            raise
    
    def predict_priority(self, text: str) -> str:
        """
        Predict priority using the trained DistilBERT model
        
        Args:
            text: Formatted text input
            
        Returns:
            Priority level: "low", "medium", or "high"
        """
        inputs = self.tokenizer(
            text, 
            return_tensors="pt", 
            truncation=True, 
            padding=True, 
            max_length=512
        )
        
        with torch.no_grad():
            outputs = self.model(**inputs)
            predictions = torch.nn.functional.softmax(outputs.logits, dim=-1)
            predicted_class = torch.argmax(predictions, dim=-1).item()
            confidence = torch.max(predictions).item()
        
        # Convert numerical prediction back to priority labels
        label_names = {0: "low", 1: "medium", 2: "high"}
        return {
            "priority": label_names[predicted_class],
            "confidence": round(confidence, 3)
        }
    
    def classify_beneficiary(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Main function to determine priority for a beneficiary
        
        Args:
            data: Dictionary containing beneficiary information
            
        Returns:
            Dictionary with priority and confidence
        """
        # Extract data with defaults
        age = data.get("age", 0)
        gender = data.get("gender", "Unknown")
        income = data.get("income", "Unknown")
        disability = data.get("disability", "No")
        dependents = data.get("dependents", 0)
        description = data.get("description", "")
        
        # Format data as text for the AI model
        text = (
            f"Age: {age} Gender: {gender} Income: {income} "
            f"Disability: {disability} Dependents: {dependents} "
            f"Description: {description}"
        )
        
        # Get prediction
        result = self.predict_priority(text)
        
        return {
            "priority": result["priority"].capitalize(),  # "High", "Medium", "Low"
            "confidence": result["confidence"],
            "input_data": data,
            "formatted_text": text
        }

# Flask API wrapper for web integration
from flask import Flask, request, jsonify
from flask_cors import CORS

# Initialize the classifier (load once when server starts)
classifier = None

# Get API key from environment variable (set in Cloud Run)
API_KEY = os.environ.get('API_KEY', '')

def require_api_key(f):
    """Decorator to require API key for protected routes"""
    def decorated_function(*args, **kwargs):
        # Skip API key check if not configured (for development/testing)
        if not API_KEY:
            return f(*args, **kwargs)
        
        # Check API key from header
        api_key = request.headers.get('X-API-Key')
        if api_key != API_KEY:
            return jsonify({
                "success": False,
                "error": "Unauthorized. Invalid or missing API key."
            }), 401
        return f(*args, **kwargs)
    decorated_function.__name__ = f.__name__
    return decorated_function

def create_app():
    """Application factory pattern"""
    app = Flask(__name__)
    CORS(app)  # Enable CORS for mobile app integration
    
    # Load classifier when app starts
    global classifier
    classifier = PriorityClassifier()
    
    return app

app = create_app()

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint (no auth required)"""
    return jsonify({
        "status": "healthy",
        "model_loaded": classifier is not None,
        "message": "Priority AI Model API is running",
        "api_key_configured": bool(API_KEY)  # Don't reveal the actual key
    })

@app.route('/predict', methods=['POST'])
@require_api_key  # <-- SECURITY: Requires API key if configured
def predict_priority():
    """
    Predict priority for a beneficiary
    
    Expected JSON input:
    {
        "age": 25,
        "gender": "Female",
        "income": "Low",
        "disability": "No",
        "dependents": 2,
        "description": "Single mother with two children"
    }
    
    Required header (if API_KEY env var is set):
        X-API-Key: your-api-key-here
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({"error": "No data provided"}), 400
        
        # Validate required fields
        if "age" not in data:
            return jsonify({"error": "Age is required"}), 400
        
        # Get prediction
        result = classifier.classify_beneficiary(data)
        
        return jsonify({
            "success": True,
            "result": result,
            "timestamp": str(pd.Timestamp.now())
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/batch_predict', methods=['POST'])
@require_api_key  # <-- SECURITY: Requires API key if configured
def batch_predict():
    """
    Predict priority for multiple beneficiaries
    
    Expected JSON input:
    {
        "beneficiaries": [
            {"age": 25, "income": "Low", ...},
            {"age": 65, "disability": "Yes", ...}
        ]
    }
    """
    try:
        data = request.get_json()
        beneficiaries = data.get("beneficiaries", [])
        
        if not beneficiaries:
            return jsonify({"error": "No beneficiaries provided"}), 400
        
        results = []
        for i, beneficiary in enumerate(beneficiaries):
            try:
                result = classifier.classify_beneficiary(beneficiary)
                results.append({
                    "index": i,
                    "success": True,
                    "result": result
                })
            except Exception as e:
                results.append({
                    "index": i,
                    "success": False,
                    "error": str(e)
                })
        
        return jsonify({
            "success": True,
            "results": results,
            "total_processed": len(results)
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

if __name__ == '__main__':
    # For development only
    app.run(host='0.0.0.0', port=5000, debug=True)
else:
    # For production deployment (gunicorn, etc.)
    # The app is already created via create_app()
    pass


