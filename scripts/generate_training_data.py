"""
Generate synthetic training data for AI-based priority classification.
Each record contains multiple columns with detailed beneficiary information.
"""

import json
import random
from typing import List, Dict, Any

# Templates for generating realistic beneficiary cases
TITLES = {
    'high': [
        'Pregnant Woman in Third Trimester with No Income',
        'Bedridden Elderly Living Alone',
        'Severe Disability with No Caregiver',
        'Multiple Children Under 5 in Female-Headed Household',
        'Chronic Illness Requiring Urgent Medical Care',
        'Lactating Mother with Malnourished Infant',
        'Elderly with Severe Mobility Issues and No Support',
        'Pregnant Woman with Complications and Low Income',
        'Disabled Person with No Assistive Devices',
        'Family of 8 with Income Below 1000 ETB',
    ],
    'medium': [
        'Pregnant Woman in Second Trimester',
        'Elderly with Moderate Mobility Issues',
        'Moderate Disability with Limited Support',
        'Child Under 5 in Single Parent Household',
        'Chronic Illness on Medication',
        'Lactating Mother with Basic Needs',
        'Female-Headed Household with Low Income',
        'Elderly Living Alone with Caregiver',
        'Disabled Person Using Assistive Device',
        'Family Receiving Partial Aid',
    ],
    'low': [
        'Pregnant Woman in First Trimester with Support',
        'Elderly with Good Mobility and Caregiver',
        'Mild Disability with Full Support',
        'Child Under 5 in Stable Household',
        'Chronic Illness Under Control',
        'Lactating Mother with Adequate Resources',
        'Household with Moderate Income',
        'Elderly with Family Support',
        'Disabled Person with Assistive Devices',
        'Family Receiving Other Aid',
    ],
}

DESCRIPTION_TEMPLATES = {
    'high': [
        '{name} is a {age}-year-old {gender} from {region}. {category_details} The household has {family_size} members with an income of {income}. {urgency_factors} This case requires immediate attention and priority assistance.',
        '{name}, a {age}-year-old {gender} residing in {region}, faces critical challenges. {category_details} With {family_size} family members and income level of {income}, {urgency_factors} Urgent intervention is necessary to address immediate needs.',
        'Critical case: {name} ({age} years, {gender}) from {region}. {category_details} Family size: {family_size}, income: {income}. {urgency_factors} This beneficiary needs high-priority support immediately.',
    ],
    'medium': [
        '{name} is a {age}-year-old {gender} from {region}. {category_details} The household consists of {family_size} members with an income of {income}. {urgency_factors} This case requires moderate priority attention.',
        '{name}, a {age}-year-old {gender} living in {region}, has moderate vulnerability. {category_details} Family size: {family_size}, income level: {income}. {urgency_factors} Standard priority assistance is recommended.',
        'Moderate priority case: {name} ({age} years, {gender}) from {region}. {category_details} Household: {family_size} members, income: {income}. {urgency_factors} This beneficiary would benefit from timely support.',
    ],
    'low': [
        '{name} is a {age}-year-old {gender} from {region}. {category_details} The household has {family_size} members with an income of {income}. {urgency_factors} This case can be addressed with standard priority.',
        '{name}, a {age}-year-old {gender} residing in {region}, has basic needs. {category_details} Family size: {family_size}, income: {income}. {urgency_factors} Low priority assistance is appropriate.',
        'Standard case: {name} ({age} years, {gender}) from {region}. {category_details} Household: {family_size} members, income: {income}. {urgency_factors} This beneficiary can be processed with regular priority.',
    ],
}

CATEGORY_DETAILS = {
    'pregnant_woman': [
        'Currently pregnant in the {trimester} trimester.',
        'Pregnant and in need of nutritional support.',
        'Expecting mother requiring maternal care.',
    ],
    'lactating_mother': [
        'Currently breastfeeding an infant.',
        'Lactating mother with a {child_age}-month-old child.',
        'Breastfeeding mother in need of support.',
    ],
    'child_under_5': [
        'Has {children_count} children under 5 years old, with youngest being {youngest_age} months.',
        'Caring for {children_count} young children requiring attention.',
        'Parent of {children_count} children under 5 years of age.',
    ],
    'elderly': [
        'Elderly person ({age} years) with {mobility} mobility.',
        'Senior citizen requiring assistance.',
        'Elderly individual ({age} years) with limited mobility.',
    ],
    'disabled': [
        'Person with {disability_type} disability, severity: {severity}.',
        'Has {disability_type} disability requiring support.',
        'Individual with {severity} {disability_type} disability.',
    ],
    'chronically_ill': [
        'Diagnosed with {illness_type} and requires medical care.',
        'Living with {illness_type} chronic condition.',
        'Has {illness_type} requiring ongoing treatment.',
    ],
}

URGENCY_FACTORS = {
    'high': [
        'No other aid is currently being received.',
        'Living in extreme poverty conditions.',
        'No caregiver or support system available.',
        'Facing severe food insecurity.',
        'Urgent medical needs not being met.',
        'Critical housing situation.',
    ],
    'medium': [
        'Receiving limited support from other sources.',
        'Moderate financial constraints.',
        'Some caregiver support available.',
        'Basic needs partially met.',
        'Regular medical care needed.',
    ],
    'low': [
        'Receiving support from other aid programs.',
        'Stable financial situation.',
        'Adequate caregiver support available.',
        'Basic needs are being met.',
        'Medical condition is stable.',
    ],
}

REGIONS = [
    'Addis Ababa', 'Oromia', 'Amhara', 'Tigray', 'SNNPR',
    'Afar', 'Somali', 'Gambela', 'Harari', 'Dire Dawa',
]

INCOME_LEVELS = {
    'high': ['less_than_1000'],
    'medium': ['1000-3000', 'less_than_1000'],
    'low': ['3000-5000', 'above_5000', '1000-3000'],
}

NAMES = [
    'Alemitu', 'Birtukan', 'Chaltu', 'Desta', 'Etenesh',
    'Fikirte', 'Genet', 'Hirut', 'Kebebush', 'Mulu',
    'Netsanet', 'Rahel', 'Selam', 'Tigist', 'Wubalem',
    'Yenenesh', 'Zewditu', 'Abebe', 'Bekele', 'Chala',
    'Dawit', 'Elias', 'Fikru', 'Girma', 'Haile',
]

def generate_category_info(priority: str) -> Dict[str, Any]:
    """Generate category-specific information based on priority."""
    categories = {
        'high': ['pregnant_woman', 'elderly', 'disabled', 'child_under_5', 'chronically_ill'],
        'medium': ['pregnant_woman', 'elderly', 'disabled', 'child_under_5', 'lactating_mother'],
        'low': ['lactating_mother', 'child_under_5', 'elderly'],
    }
    
    category = random.choice(categories[priority])
    category_info = {
        'vulnerable_category': category,
        'category_details': '',
        'pregnancy_trimester': None,
        'children_under_5_count': 0,
        'youngest_child_age_months': None,
        'elderly_age': None,
        'mobility_level': None,
        'disability_type': None,
        'disability_severity': None,
        'chronic_illness_type': None,
        'child_age_months': None,
    }
    
    if category == 'pregnant_woman':
        trimester = random.choice(['first', 'second', 'third'])
        category_info['pregnancy_trimester'] = trimester
        category_info['category_details'] = random.choice(CATEGORY_DETAILS[category]).format(trimester=trimester)
    elif category == 'lactating_mother':
        child_age = random.randint(1, 12)
        category_info['child_age_months'] = child_age
        category_info['category_details'] = random.choice(CATEGORY_DETAILS[category]).format(child_age=child_age)
    elif category == 'child_under_5':
        children_count = random.randint(1, 3)
        youngest_age = random.randint(1, 48)
        category_info['children_under_5_count'] = children_count
        category_info['youngest_child_age_months'] = youngest_age
        category_info['category_details'] = random.choice(CATEGORY_DETAILS[category]).format(
            children_count=children_count, youngest_age=youngest_age
        )
    elif category == 'elderly':
        elderly_age = random.randint(60, 85)
        mobility = random.choice(['limited', 'moderate', 'severe'])
        category_info['elderly_age'] = elderly_age
        category_info['mobility_level'] = mobility
        category_info['category_details'] = random.choice(CATEGORY_DETAILS[category]).format(age=elderly_age, mobility=mobility)
    elif category == 'disabled':
        disability_type = random.choice(['physical', 'visual', 'hearing', 'intellectual'])
        severity = random.choice(['mild', 'moderate', 'severe'])
        category_info['disability_type'] = disability_type
        category_info['disability_severity'] = severity
        category_info['category_details'] = random.choice(CATEGORY_DETAILS[category]).format(
            disability_type=disability_type, severity=severity
        )
    elif category == 'chronically_ill':
        illness_type = random.choice([
            'HIV/AIDS', 'tuberculosis', 'diabetes', 'heart disease', 'cancer'
        ])
        category_info['chronic_illness_type'] = illness_type
        category_info['category_details'] = random.choice(CATEGORY_DETAILS[category]).format(illness_type=illness_type)
    else:
        category_info['category_details'] = 'Member of vulnerable population group.'
    
    return category_info

def generate_income_label(income_level: str) -> str:
    """Convert income level code to readable label."""
    labels = {
        'less_than_1000': 'less than 1,000 ETB per month',
        '1000-3000': '1,000 to 3,000 ETB per month',
        '3000-5000': '3,000 to 5,000 ETB per month',
        'above_5000': 'above 5,000 ETB per month',
    }
    return labels.get(income_level, income_level)

def generate_record(priority: str, record_id: str) -> Dict[str, Any]:
    """Generate a single training record with multiple columns."""
    name = random.choice(NAMES)
    age = random.randint(18, 85) if priority != 'low' else random.randint(25, 70)
    gender = random.choice(['female', 'male'])
    region = random.choice(REGIONS)
    family_size = random.randint(1, 8) if priority == 'high' else random.randint(2, 6)
    income_level = random.choice(INCOME_LEVELS[priority])
    income_label = generate_income_label(income_level)
    is_female_headed = random.choice([True, False]) if priority == 'high' else random.choice([False, True])
    receiving_other_aid = False if priority == 'high' else random.choice([True, False])
    
    title = random.choice(TITLES[priority])
    category_info = generate_category_info(priority)
    urgency_factors = random.choice(URGENCY_FACTORS[priority])
    
    # Generate full description
    description_template = random.choice(DESCRIPTION_TEMPLATES[priority])
    description = description_template.format(
        name=name,
        age=age,
        gender=gender,
        region=region,
        category_details=category_info['category_details'],
        family_size=family_size,
        income=income_label,
        urgency_factors=urgency_factors,
    )
    
    # Build comprehensive record with all columns
    record = {
        'id': record_id,
        'title': f'{title} (ID: {record_id[:8]})',
        'name': name,
        'age': age,
        'gender': gender,
        'region': region,
        'vulnerable_category': category_info['vulnerable_category'],
        'category_details': category_info['category_details'],
        'family_size': family_size,
        'income_level': income_level,
        'income_label': income_label,
        'is_female_headed_household': is_female_headed,
        'currently_receiving_other_aid': receiving_other_aid,
        'urgency_factors': urgency_factors,
        'description': description,
        'priority': priority,
    }
    
    # Add category-specific fields
    if category_info['pregnancy_trimester']:
        record['pregnancy_trimester'] = category_info['pregnancy_trimester']
    if category_info['children_under_5_count'] > 0:
        record['children_under_5_count'] = category_info['children_under_5_count']
        record['youngest_child_age_months'] = category_info['youngest_child_age_months']
    if category_info['elderly_age']:
        record['elderly_age'] = category_info['elderly_age']
        record['mobility_level'] = category_info['mobility_level']
    if category_info['disability_type']:
        record['disability_type'] = category_info['disability_type']
        record['disability_severity'] = category_info['disability_severity']
    if category_info['chronic_illness_type']:
        record['chronic_illness_type'] = category_info['chronic_illness_type']
    if category_info['child_age_months']:
        record['child_age_months'] = category_info['child_age_months']
    
    return record

def generate_training_data(num_records: int = 10000, balanced: bool = True) -> List[Dict[str, Any]]:
    """
    Generate synthetic training data with multiple columns.
    
    Args:
        num_records: Total number of records to generate
        balanced: If True, generate equal number of each priority level
    
    Returns:
        List of training records with detailed columns
    """
    records = []
    record_counter = 1
    
    if balanced:
        records_per_priority = num_records // 3
        for priority in ['high', 'medium', 'low']:
            for _ in range(records_per_priority):
                record_id = f'BEN{str(record_counter).zfill(8)}'
                records.append(generate_record(priority, record_id))
                record_counter += 1
        # Add remaining records to make up for rounding
        remaining = num_records - len(records)
        for _ in range(remaining):
            priority = random.choice(['high', 'medium', 'low'])
            record_id = f'BEN{str(record_counter).zfill(8)}'
            records.append(generate_record(priority, record_id))
            record_counter += 1
    else:
        for _ in range(num_records):
            priority = random.choice(['high', 'medium', 'low'])
            record_id = f'BEN{str(record_counter).zfill(8)}'
            records.append(generate_record(priority, record_id))
            record_counter += 1
    
    # Shuffle records
    random.shuffle(records)
    
    return records

def get_all_fieldnames(records: List[Dict[str, Any]]) -> List[str]:
    """Get all unique field names from records."""
    fieldnames = set()
    for record in records:
        fieldnames.update(record.keys())
    # Order important fields first
    ordered_fields = [
        'id', 'title', 'name', 'age', 'gender', 'region',
        'vulnerable_category', 'category_details', 'family_size',
        'income_level', 'income_label', 'is_female_headed_household',
        'currently_receiving_other_aid', 'urgency_factors',
        'pregnancy_trimester', 'children_under_5_count', 'youngest_child_age_months',
        'elderly_age', 'mobility_level', 'disability_type', 'disability_severity',
        'chronic_illness_type', 'child_age_months', 'description', 'priority'
    ]
    # Add any additional fields
    for field in sorted(fieldnames):
        if field not in ordered_fields:
            ordered_fields.append(field)
    return ordered_fields

def save_to_json(records: List[Dict[str, Any]], filename: str = 'training_data.json'):
    """Save training data to JSON file."""
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(records, f, indent=2, ensure_ascii=False)
    print(f'Saved {len(records)} records to {filename}')

def save_to_csv(records: List[Dict[str, Any]], filename: str = 'training_data.csv'):
    """Save training data to CSV file with all columns."""
    import csv
    
    fieldnames = get_all_fieldnames(records)
    
    with open(filename, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
        writer.writeheader()
        for record in records:
            # Convert boolean and None values to strings for CSV
            csv_record = {}
            for key, value in record.items():
                if value is None:
                    csv_record[key] = ''
                elif isinstance(value, bool):
                    csv_record[key] = 'Yes' if value else 'No'
                else:
                    csv_record[key] = value
            writer.writerow(csv_record)
    print(f'Saved {len(records)} records with {len(fieldnames)} columns to {filename}')

def main():
    """Main function to generate and save training data."""
    print('Generating synthetic training data...')
    
    # Generate balanced dataset (10,000 records, evenly mixed across priorities)
    records = generate_training_data(num_records=10000, balanced=True)
    
    # Print statistics
    priority_counts = {}
    for record in records:
        priority = record['priority']
        priority_counts[priority] = priority_counts.get(priority, 0) + 1
    
    print(f'\nGenerated {len(records)} records:')
    for priority, count in priority_counts.items():
        print(f'  {priority}: {count}')
    
    # Save to both JSON and CSV
    save_to_json(records, 'training_data.json')
    save_to_csv(records, 'training_data.csv')
    
    print('\nTraining data generation complete!')
    print('Files created:')
    print('  - training_data.json')
    print('  - training_data.csv')

if __name__ == '__main__':
    main()