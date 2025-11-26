import json
from code_corruptor.infer import CodeCorruptor

def test_corruption_model(model_path, snippets_file):
    """
    Test the corruption model by applying it to code snippets.

    Args:
        model_path (str): Path to the trained corruption model.
        snippets_file (str): Path to the file containing code snippets.

    Returns:
        list: A list of corrupted code snippets.
    """
    # Load the corruption model
    corruptor = CodeCorruptor(model_path)

    # Read code snippets from file
    with open(snippets_file, 'r') as f:
        snippets = json.load(f)

    corrupted_snippets = []

    for snippet in snippets:
        try:
            corrupted = corruptor.corrupt_code(snippet, num_beams=2, temperature=0.8)
            corrupted_snippets.append({"original": snippet, "corrupted": corrupted})
        except Exception as e:
            corrupted_snippets.append({"original": snippet, "error": str(e)})

    return corrupted_snippets

if __name__ == "__main__":
    # Replace with your actual model path and snippets file
    MODEL_PATH = "./code_corruptor_model/final_model"
    SNIPPETS_FILE = "./code_snippets_0_200.json"

    results = test_corruption_model(MODEL_PATH, SNIPPETS_FILE)

    # Print results
    for result in results:
        print(json.dumps(result, indent=2))