import pandas as pd
import re

INPUT_FILENAME = '../../data/raw/initial_dataset.xlsx'
OUTPUT_FILENAME = '../../data/processed/master_dataset.csv'

def normalize_code(code_string):
    if pd.isna(code_string):
        return ""
    
    code_string = str(code_string)
    
    code_string = re.sub(r"^#!.*", "", code_string, flags=re.MULTILINE)
    code_string = re.sub(r"#[^\n]*", "", code_string)
    code_string = re.sub(r"raw_input\s*\([^\)]*?\)", " ", code_string) 
    code_string = re.sub(r"input\s*\([^\)]*?\)", " ", code_string)
    code_string = re.sub(r"print\s*\(", " ", code_string)
    code_string = re.sub(r"print\s+", " ", code_string)
    
    code_string = code_string.replace("\t", " ")
    code_string = re.sub(r"\s+", " ", code_string) 
    
    code_string = code_string.replace("==", " == ")
    code_string = code_string.replace("!=", " != ")
    code_string = code_string.replace("=", " = ")
    code_string = code_string.replace("<", " < ")
    code_string = code_string.replace(">", " > ")
    code_string = code_string.replace(",", " , ")

    code_string = code_string.lower().strip()

    return code_string

try:
    df = pd.read_excel(INPUT_FILENAME) 
    print(f"Successfully read data from {INPUT_FILENAME}")
except Exception as e:
    print(f"ERROR reading file.Error: {e}")
    exit()

df['Normalized_Student_Code'] = df['raw_student_code'].apply(normalize_code)
df['Normalized_Canonical_Code'] = df['canonical_reference'].apply(normalize_code)

print("Normalization complete.")

df.to_csv(OUTPUT_FILENAME, index=False)

print(f"Successfully saved normalized data to: {OUTPUT_FILENAME}")