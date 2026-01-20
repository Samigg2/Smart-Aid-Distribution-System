import torch
from transformers import DistilBertTokenizerFast, DistilBertForSequenceClassification

# Load the trained model and tokenizer
model = DistilBertForSequenceClassification.from_pretrained("priority_ai_model", num_labels=3)
tokenizer = DistilBertTokenizerFast.from_pretrained("priority_ai_model")

def predict_priority(text):
    """Predict priority using the trained DistilBERT model"""
    inputs = tokenizer(
        text, 
        return_tensors="pt", 
        truncation=True, 
        padding=True, 
        max_length=512
    )
    
    with torch.no_grad():
        outputs = model(**inputs)
        predictions = torch.nn.functional.softmax(outputs.logits, dim=-1)
        predicted_class = torch.argmax(predictions, dim=-1).item()
    
    # Convert numerical prediction back to priority labels
    label_names = {0: "low", 1: "medium", 2: "high"}
    return label_names[predicted_class]

def final_priority_decision(data):
    """Main function to determine priority using AI model"""
    age = data.get("age", 0)
    gender = data.get("gender", "Unknown")
    income = data.get("income", "Unknown")
    disability = data.get("disability", "No")
    dependents = data.get("dependents", 0)
    description = data.get("description", "")
    
    # Format data as text for the AI model (same format as training data)
    text = (
        f"Age: {age} Gender: {gender} Income: {income} "
        f"Disability: {disability} Dependents: {dependents} "
        f"Description: {description}"
    )
    
    # Use AI model for prediction
    priority = predict_priority(text)
    return priority.capitalize()  # Return "High", "Medium", or "Low"