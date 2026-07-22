"""Module for predicting priority using a DistilBERT model.

This module loads a preâtrained DistilBERT model and tokenizer from the
``priority_ai_model`` directory.  It exposes two public functions:

* :func:`predict_priority` â takes a raw text string and returns the
  predicted priority label (``"low"``, ``"medium"``, or ``"high"``).
* :func:`final_priority_decision` â accepts a dictionary of patient
  attributes, formats it into a text prompt, and returns a capitalised
  priority string (``"Low"``, ``"Medium"``, or ``"High"``).

The model and tokenizer are loaded once at import time to avoid
reâinitialising them on every call.
"""

import torch  # PyTorch for tensor operations and model inference
from transformers import (
    DistilBertTokenizerFast,  # Tokenizer for fast tokenisation
    DistilBertForSequenceClassification,  # DistilBERT model for classification
)

# Load the trained model and tokenizer once at import time.
# The model directory ``priority_ai_model`` must contain the
# ``config.json`` and ``pytorch_model.bin`` files.
model = DistilBertForSequenceClassification.from_pretrained(
    "priority_ai_model", num_labels=3
)
tokenizer = DistilBertTokenizerFast.from_pretrained("priority_ai_model")


def predict_priority(text):
    """Predict priority using the trained DistilBERT model.

    Parameters
    ----------
    text : str
        The input text containing patient information.

    Returns
    -------
    str
        The predicted priority label: ``"low"``, ``"medium"``, or ``"high"``.
    """
    # Tokenise the input text and convert it to PyTorch tensors.
    inputs = tokenizer(
        text,
        return_tensors="pt",
        truncation=True,
        padding=True,
        max_length=512,
    )

    # Run inference without computing gradients.
    with torch.no_grad():
        outputs = model(**inputs)
        # Convert logits to probabilities.
        predictions = torch.nn.functional.softmax(outputs.logits, dim=-1)
        # Choose the class with the highest probability.
        predicted_class = torch.argmax(predictions, dim=-1).item()

    # Map the numerical prediction back to a humanâreadable label.
    label_names = {0: "low", 1: "medium", 2: "high"}
    return label_names[predicted_class]


def final_priority_decision(data):
    """Main function to determine priority using the AI model.

    Parameters
    ----------
    data : dict
        Dictionary containing patient attributes. Expected keys are:
        ``age`` (int), ``gender`` (str), ``income`` (str or int),
        ``disability`` (str), ``dependents`` (int), and ``description`` (str).

    Returns
    -------
    str
        The capitalised priority string: ``"Low"``, ``"Medium"``, or ``"High"``.
    """
    # Extract values with sensible defaults if keys are missing.
    age = data.get("age", 0)
    gender = data.get("gender", "Unknown")
    income = data.get("income", "Unknown")
    disability = data.get("disability", "No")
    dependents = data.get("dependents", 0)
    description = data.get("description", "")

    # Format the data into a single text prompt that matches the training format.
    text = (
        f"Age: {age} Gender: {gender} Income: {income} "
        f"Disability: {disability} Dependents: {dependents} "
        f"Description: {description}"
    )

    # Use the AI model to predict the priority.
    priority = predict_priority(text)
    # Return the priority with the first letter capitalised.
    return priority.capitalize()
