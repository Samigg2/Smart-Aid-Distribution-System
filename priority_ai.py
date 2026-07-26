import torch
from transformers import DistilBertTokenizerFast, DistilBertForSequenceClassification
from typing import Dict

"""
priority_ai.py

This module provides a simple interface for predicting the priority level of a
request or case using a preâtrained DistilBERT model fineâtuned for
sequence classification.  The model outputs one of three priority labels
(`low`, `medium`, `high`).  The `final_priority_decision` function formats
input data into a single text string that matches the format used during
training, then delegates to `predict_priority` to obtain the prediction.
"""

# Load the trained model and tokenizer
# The model is expected to be located in a directory named "priority_ai_model"
# containing the model weights and tokenizer files.
model = DistilBertForSequenceClassification.from_pretrained(
    "priority_ai_model",
    num_labels=3
)
tokenizer = DistilBertTokenizerFast.from_pretrained("priority_ai_model")


def predict_priority(text: str) -> str:
    """
    Predict priority using the trained DistilBERT model.

    Parameters
    ----------
    text : str
        A single string containing the formatted input data.

    Returns
    -------
    str
        The predicted priority label: "low", "medium", or "high".
    """
    # Tokenise the input text and prepare tensors for the model
    inputs = tokenizer(
        text,
        return_tensors="pt",
        truncation=True,
        padding=True,
        max_length=512,
    )

    # Forward pass through the model without computing gradients
    with torch.no_grad():
        outputs = model(**inputs)
        # Convert logits to probabilities
        predictions = torch.nn.functional.softmax(outputs.logits, dim=-1)
        # Choose the class with the highest probability
        predicted_class = torch.argmax(predictions, dim=-1).item()

    # Map the numeric prediction back to a humanâreadable label
    label_names = {0: "low", 1: "medium", 2: "high"}
    return label_names[predicted_class]


def final_priority_decision(data: Dict) -> str:
    """
    Main function to determine priority using the AI model.

    Parameters
    ----------
    data : dict
        Dictionary containing the following keys:
        - "age" (int)
        - "gender" (str)
        - "income" (str)
        - "disability" (str)
        - "dependents" (int)
        - "description" (str)

    Returns
    -------
    str
        The priority level capitalised ("High", "Medium", or "Low").
    """
    # Extract fields with sensible defaults
    age = data.get("age", 0)
    gender = data.get("gender", "Unknown")
    income = data.get("income", "Unknown")
    disability = data.get("disability", "No")
    dependents = data.get("dependents", 0)
    description = data.get("description", "")

    # Format data as a single string matching the training format
    text = (
        f"Age: {age} Gender: {gender} Income: {income} "
        f"Disability: {disability} Dependents: {dependents} "
        f"Description: {description}"
    )

    # Use the AI model to predict priority
    priority = predict_priority(text)
    # Return the priority with the first letter capitalised
    return priority.capitalize()
