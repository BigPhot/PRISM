import openai
import base64
import json 

def gpt_api_call(user_input, rule):
    """
    Call OpenAI's GPT API using a rule-based system prompt and user input.

    Parameters:
    user_input (str | dict): User message or data (converted to JSON if needed).
    rule (str): The system-level instruction or behavior rule.

    Returns:
    str: GPT response content or error message.
    """
    try:
        # Read the base64-encoded API key from the file
        with open('C:/Users/adhir/Development/LeJarvis/api_key.txt', 'r') as file:
            encoded_key = file.read().strip()  # Remove any extra whitespace/newlines

        # Decode the base64-encoded key
        decoded_key = base64.b64decode(encoded_key).decode('utf-8').strip()
        print(decoded_key)

        # Set the API key
        client = openai.OpenAI(api_key=decoded_key) 

        if not isinstance(user_input, str):
        # Convert user_input to a JSON string if it's not already a string
            user_input_str = json.dumps(user_input)
        else:
            # If it's already a string, use it as is
            user_input_str = user_input

        # Make the API call
        response = client.chat.completions.create(
            model="gpt-4o-mini-2024-07-18",
            messages=[
                {"role": "system", "content": rule},
                {"role": "user", "content": user_input_str}
            ]
        )
    
        # Extract and return the response content
        return response.choices[0].message.content

    except FileNotFoundError:
        return "Error: The file 'api_key.txt' was not found. Please ensure it exists."
    except base64.binascii.Error:
        return "Error: The API key in 'api_key.txt' is not correctly base64-encoded."
    except Exception as e:
        return f"An unexpected error occurred: {str(e)}"
