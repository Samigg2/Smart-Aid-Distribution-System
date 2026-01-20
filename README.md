# Priority AI Model

AI-powered priority classification using DistilBERT.

## Installation
```bash
pip install -r requirements.txt
```

## Usage
```python
from priority_ai import final_priority_decision

data = {
    "age": 80,
    "income": "None", 
    "disability": "Yes",
    "dependents": 0,
    "description": "Elderly person with mobility issues"
}

priority = final_priority_decision(data)
print(priority)  # "High"
```

## Files
- `priority_ai.py` - Main AI model code
- `train_model.py` - Training script
- `Priority_AI_Model_FIXED.ipynb` - Training notebook