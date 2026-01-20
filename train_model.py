import pandas as pd
import torch
from transformers import (
    DistilBertTokenizerFast,
    DistilBertForSequenceClassification,
    Trainer,
    TrainingArguments
)
from sklearn.model_selection import train_test_split

class PriorityDataset(torch.utils.data.Dataset):
    def __init__(self, encodings, labels):
        self.encodings = encodings
        self.labels = labels

    def __getitem__(self, idx):
        item = {k: torch.tensor(v[idx]) for k, v in self.encodings.items()}
        item["labels"] = torch.tensor(self.labels[idx])
        return item

    def __len__(self):
        return len(self.labels)

def train_priority_model():
    # Load and prepare data
    df = pd.read_csv("training_data.csv")
    
    # Map priority labels to numbers
    label_map = {"low": 0, "medium": 1, "high": 2}
    df["label"] = df["priority"].map(label_map)
    
    # Split data
    train_texts, val_texts, train_labels, val_labels = train_test_split(
        df["description"].tolist(),
        df["label"].tolist(),
        test_size=0.2,
        random_state=42
    )
    
    # Initialize tokenizer and model
    tokenizer = DistilBertTokenizerFast.from_pretrained("distilbert-base-uncased")
    model = DistilBertForSequenceClassification.from_pretrained(
        "distilbert-base-uncased", num_labels=3
    )
    
    # Tokenize data
    train_encodings = tokenizer(train_texts, truncation=True, padding=True)
    val_encodings = tokenizer(val_texts, truncation=True, padding=True)
    
    # Create datasets
    train_dataset = PriorityDataset(train_encodings, train_labels)
    val_dataset = PriorityDataset(val_encodings, val_labels)
    
    # Training arguments
    training_args = TrainingArguments(
        output_dir="./results",
        num_train_epochs=3,
        per_device_train_batch_size=16,
        per_device_eval_batch_size=64,
        warmup_steps=500,
        weight_decay=0.01,
        logging_dir="./logs",
    )
    
    # Initialize trainer
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        eval_dataset=val_dataset,
    )
    
    # Train model
    trainer.train()
    
    # Evaluate model
    results = trainer.evaluate()
    print(f"Evaluation results: {results}")
    
    # Save model
    model.save_pretrained("priority_ai_model")
    tokenizer.save_pretrained("priority_ai_model")
    
    print("Model training completed and saved!")

if __name__ == "__main__":
    train_priority_model()