import ollama
import os

def test_ollama_api(api_key):
    """
    Test the Ollama API key by making a chat request using the official library.

    Args:
        api_key (str): The Ollama API key.

    Returns:
        dict: The response from the API.
    """
    try:
        # Initialize Ollama client with API key
        client = ollama.Client(
            host='https://ollama.com',
            headers={'Authorization': f'Bearer {api_key}'}
        )
        
        # First, try to list available models
        try:
            models = client.list()
            if models.get('models'):
                print(f"Available models: {[m.get('name', m.get('model', 'unknown')) for m in models['models']]}")
        except Exception as list_error:
            print(f"Could not list models: {list_error}")
        
        # Test with a simple chat request - try available models
        available_models = ['gpt-oss:20b', 'gemini-3-pro-preview', 'qwen3-coder:480b']
        for model_name in available_models:
            try:
                print(f"Trying model: {model_name}")
                response = client.chat(
                    model=model_name,
                    messages=[{'role': 'user', 'content': 'Say hello in one word.'}]
                )
                
                return {
                    "success": True,
                    "message": response['message']['content'],
                    "model": model_name
                }
            except Exception as model_error:
                print(f"  Failed: {model_error}")
                continue
        
        raise Exception("All model attempts failed")
    except Exception as e:
        return {"success": False, "error": str(e)}

if __name__ == "__main__":
    # Use environment variable or hardcoded key (use the newer key from the file)
    API_KEY = os.getenv('OLLAMA_API_KEY', 'api key')
    
    print("Testing Ollama API with official Python library...")
    print(f"Using API key: {API_KEY[:20]}...")
    print("-" * 60)
    
    result = test_ollama_api(API_KEY)
    
    if result["success"]:
        print("✓ SUCCESS: Ollama API is working!")
        print(f"Model: {result.get('model', 'N/A')}")
        print(f"Response: {result['message']}")
    else:
        print("✗ FAILED: Could not connect to Ollama API")
        print(f"Error: {result['error']}")
    
    print("-" * 60)

