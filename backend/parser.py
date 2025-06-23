import cv2
import pytesseract
import pandas as pd
import numpy as np
import re
from PIL import Image
import spacy
import subprocess
import importlib

# Ensure Med7 model is installed and loaded
try:
    # Try loading by name (if already linked)
    nlp_med7 = spacy.load("en_core_med7_lg")
except OSError:
    # Install the Med7 model
    subprocess.run([
        "pip", "install",
        "https://huggingface.co/kormilitzin/en_core_med7_lg/resolve/main/en_core_med7_lg-any-py3-none-any.whl"
    ])
    # Try importing it now
    en_core_med7_lg = importlib.import_module("en_core_med7_lg")
    nlp_med7 = en_core_med7_lg.load()

class PrescriptionParser:
    def __init__(self, drug_csv_path):
        """Initialize parser with a drug database"""
        self.drug_names = self.load_drug_names(drug_csv_path)
        self.nlp_med7 = nlp_med7

    def load_drug_names(self, csv_path):
        """Load drug names from a CSV file with possible variations in column names"""
        try:
            df = pd.read_csv(csv_path)
            possible_columns = ['Drug Name', 'drug_name', 'name', 'Name', 'DRUG_NAME', 'medicine_name']
            drug_column = next((col for col in possible_columns if col in df.columns), None)
            if not drug_column:
                print(f"❌ Available columns: {list(df.columns)}")
                return set()
            drugs = df[drug_column].dropna().astype(str).str.lower().str.strip().tolist()
            print(f"[DEBUG] Loaded {len(drugs)} drugs from CSV")
            return drugs
        except Exception as e:
            print(f"❌ Error loading drugs: {e}")
            return []

    def preprocess_image(self, image_path: str) -> np.ndarray:
        """Preprocess image for better OCR: grayscale, resize, threshold"""
        image = Image.open(image_path)
        image_array = np.array(image)
        gray = cv2.cvtColor(image_array, cv2.COLOR_BGR2GRAY)
        resized = cv2.resize(gray, None, fx=2, fy=2, interpolation=cv2.INTER_LINEAR)
        processed = cv2.adaptiveThreshold(
            resized, 255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY,
            103, 52
        )
        return processed

    def extract_all_words(self, text):
        """Extract all words excluding common non-medicine terms"""
        text = text.lower().replace('0', 'o').replace('1', 'l').replace('5', 's')
        words = re.findall(r'\b[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9]\b', text)

        # Also check within parentheses
        parentheses_words = re.findall(r'\(([^)]+)\)', text)
        for phrase in parentheses_words:
            words.extend(re.findall(r'\b[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9]\b', phrase))

        exclude_words = {
            'the', 'and', 'for', 'with', 'day', 'days', 'tablet', 'tablets', 
            'once', 'twice', 'three', 'times', 'sig', 'bedtime', 'water', 
            'glass', 'first', 'dissolve', 'take', 'morning', 'evening'
        }

        return [w for w in words if len(w) >= 3 and w not in exclude_words]

    def detect_combination_medicines(self, text):
        """Identify lines that mention medicine combinations like 'X + Y'"""
        combinations = []
        lines = text.split('\n')
        combination_words = ['plus', 'with', '+', 'and', '&']
        for line in lines:
            if any(combo in line.lower() for combo in combination_words):
                line_words = self.extract_all_words(line)
                drugs_in_line = [w for w in line_words if w in self.drug_names]
                if len(drugs_in_line) >= 2:
                    combo_name = " + ".join([w for w in drugs_in_line if w.lower() != "plus"])
                    combinations.append({
                        'name': combo_name,
                        'components': drugs_in_line,
                        'line': line.strip()
                    })
        return combinations

    def find_medicines(self, text):
        """Detect both combination and individual medicines in text"""
        matches = {}

        # Detect combinations first
        combinations = self.detect_combination_medicines(text)
        for combo in combinations:
            matches[combo['name']] = {
                'line': combo['line'], 'confidence': 100, 'method': 'combination_match'
            }

        # Avoid double-matching
        already_matched = set(comp for c in combinations for comp in c['components'])

        ocr_words = self.extract_all_words(text)
        lines = text.split('\n')

        # Match individual words to drug names
        for word in ocr_words:
            if word in self.drug_names and word not in already_matched:
                found_line = next((l for l in lines if word in l.lower()), "")
                matches[word] = {
                    'line': found_line.strip(), 'confidence': 100, 'method': 'exact_match'
                }

        return matches

    def extract_quantity(self, text):
        """Find quantities like '#24', 'Disp: 30', etc."""
        quantities = []
        for match in re.finditer(r'#\s*(\d+)', text, re.IGNORECASE):
            quantities.append({
                'text': match.group(0), 'number': int(match.group(1)),
                'start': match.start(), 'end': match.end()
            })

        # Other patterns for quantity
        patterns = [
            r'(?:disp|dispense|qty|quantity)[\s:]*(\d+)',
            r'(\d+)\s*(?:tabs?|caps?|tablets?|capsules?|pieces?|pcs?)\s*(?:total|to\s+dispense|dispense)',
            r'(?:total|give|supply)[\s:]*(\d+)'
        ]
        for pattern in patterns:
            for match in re.finditer(pattern, text, re.IGNORECASE):
                quantities.append({
                    'text': match.group(0), 'number': int(match.group(1)),
                    'start': match.start(), 'end': match.end()
                })
        return quantities

    def extract_med7_entities(self, text):
        """Use Med7 model to extract dosage, frequency, duration, etc."""
        if not self.nlp_med7:
            print("❌ Med7 not available")
            return {}
        doc = self.nlp_med7(text)
        entities = {
            'DOSAGE': [], 'DRUG': [], 'DURATION': [], 'FORM': [],
            'FREQUENCY': [], 'ROUTE': [], 'STRENGTH': [], 'QUANTITY': []
        }
        for ent in doc.ents:
            if ent.label_ in entities:
                entities[ent.label_].append({
                    'text': ent.text, 'start': ent.start_char,
                    'end': ent.end_char, 'confidence': 1.0
                })

        # Add custom quantity matches
        for qty in self.extract_quantity(text):
            entities['QUANTITY'].append({
                'text': qty['text'], 'number': qty['number'],
                'start': qty['start'], 'end': qty['end'], 'confidence': 1.0
            })
        return entities

    def deduplicate_and_prioritize(self, items, entity_type):
        """Clean duplicates and apply priority rules for dosage, form, etc."""
        if not items:
            return []
        seen, unique = set(), []
        for i in items:
            i_lower = i.lower().strip()
            if i_lower not in seen:
                seen.add(i_lower)
                unique.append(i)

        # Special prioritization rules
        if entity_type == 'dosage':
            def priority(x): return 0 if re.search(r'\d+', x) else 1
            unique.sort(key=lambda x: (priority(x), len(x)))
            return unique[:1]
        elif entity_type == 'form':
            roots, filtered = set(), []
            for f in unique:
                r = f.lower().rstrip('s')
                if r not in roots:
                    roots.add(r)
                    filtered.append(f)
            form_priority = {
                'tablet': 1, 'tablets': 1, 'tab': 1,
                'capsule': 2, 'capsules': 2, 'cap': 2,
                'syrup': 3, 'liquid': 4, 'injection': 5,
                'cream': 6, 'ointment': 7, 'drops': 8
            }
            filtered.sort(key=lambda x: form_priority.get(x.lower().strip(), 999))
            return filtered[:2]
        elif entity_type == 'quantity':
            def priority(x):
                if x.startswith('#'): return 0
                if any(w in x.lower() for w in ['disp', 'qty', 'quantity']): return 1
                return 2
            unique.sort(key=lambda x: priority(x))
            return unique[:1]
        elif entity_type == 'instructions':
            # For instructions, keep all unique items and sort by length (longer instructions first)
            unique.sort(key=lambda x: len(x), reverse=True)
            return unique
        return unique

    def merge_frequency_and_duration(self, frequency_items, duration_items):
        """Merge frequency and duration into a single instructions field"""
        instructions = []
        
        # Add frequency items
        instructions.extend(frequency_items)
        
        # Add duration items
        instructions.extend(duration_items)
        
        # Remove duplicates and prioritize
        return self.deduplicate_and_prioritize(instructions, 'instructions')

    def match_entities_to_medicines(self, text, medicines, med7_entities):
        """Align extracted entities to each detected medicine based on nearby lines"""
        lines = text.split('\n')
        items = []
        for name, info in medicines.items():
            entry = {
                'medicine': name, 'line': info['line'],
                'confidence': info['confidence'], 'method': info['method'],
                'dosage': [], 'strength': [], 'instructions': [],
                'form': [], 'route': [], 'quantity': []
            }
            # Get line where medicine was found
            line_num = next((i for i, l in enumerate(lines) if info['line'].lower() in l.lower()), -1)
            search_lines = lines[line_num:line_num+2] if line_num >= 0 else [info['line']]
            search_text = ' '.join(search_lines).lower()

            # Extract frequency and duration separately first
            frequency_matched = [e['text'] for e in med7_entities.get('FREQUENCY', []) if e['text'].lower() in search_text]
            duration_matched = [e['text'] for e in med7_entities.get('DURATION', []) if e['text'].lower() in search_text]
            
            # Merge frequency and duration into instructions
            entry['instructions'] = self.merge_frequency_and_duration(frequency_matched, duration_matched)

            # Handle other entities (excluding FREQUENCY and DURATION as they're now merged)
            for key, ents in med7_entities.items():
                if key in ['DRUG', 'FREQUENCY', 'DURATION']:
                    continue
                matched = [e['text'] for e in ents if e['text'].lower() in search_text]
                entry[key.lower()] = self.deduplicate_and_prioritize(matched, key.lower())
            
            items.append(entry)
        return items

    def parse_prescription(self, image_path):
        """Full pipeline to parse and analyze a prescription image"""
        print("🏥 COMPLETE PRESCRIPTION PARSER\n" + "=" * 60)
        print("[1] Preprocessing image...")
        processed_img = self.preprocess_image(image_path)

        print("[2] Performing OCR...")
        ocr_text = pytesseract.image_to_string(processed_img)
        if not ocr_text.strip():
            print("❌ No text extracted!")
            return None

        print("✅ OCR completed")
        print(f"[📄] EXTRACTED TEXT:\n{'-'*40}\n{ocr_text}\n{'-'*40}")
        
        print("[3] Detecting medicines...")
        medicines = self.find_medicines(ocr_text)

        print("[4] Extracting Med7 entities...")
        med7_entities = self.extract_med7_entities(ocr_text)

        print("[5] Matching entities to medicines...")
        items = self.match_entities_to_medicines(ocr_text, medicines, med7_entities)

        return {
            'ocr_text': ocr_text,
            'medicines': medicines,
            'med7_entities': med7_entities,
            'prescription_items': items
        }

    def display_results(self, results):
        """Print structured output of extracted prescription details"""
        if not results:
            print("❌ No results to display")
            return

        print("\n" + "=" * 70)
        print("📋 COMPLETE PRESCRIPTION ANALYSIS")
        print("=" * 70)

        for i, item in enumerate(results['prescription_items'], 1):
            print(f"\n{i}. MEDICINE: {item['medicine'].upper()}")
            if item['strength']:
                print(f"   💪 Strength: {', '.join(item['strength'])}")
            if item['dosage']:
                print(f"   📊 Dosage: {', '.join(item['dosage'])}")
            if item['instructions']:
                print(f"   📋 Instructions: {', '.join(item['instructions'])}")
            if item['form']:
                print(f"   💊 Form: {', '.join(item['form'])}")
            if item['route']:
                print(f"   🎯 Route: {', '.join(item['route'])}")
            if item['quantity']:
                print(f"   📦 Quantity: {', '.join(item['quantity'])}")

        # Show medicine summary
        meds = [item['medicine'].upper() for item in results['prescription_items']]
        print(f"\n💊 DETECTED MEDICINES: {', '.join(meds)}")

# Entry point
def main():
    parser = PrescriptionParser("/Users/gemwincanete/Prescription_Reader/prescriptionreader/backend/datasets/combined_drug_names.csv")
    image_path = "/Users/gemwincanete/Documents/prescription_parser/images/pre_2.jpg"
    results = parser.parse_prescription(image_path)
    parser.display_results(results)

if __name__ == "__main__":
    main()