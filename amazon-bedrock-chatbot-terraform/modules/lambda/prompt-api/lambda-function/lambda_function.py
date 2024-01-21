import json
import os
from utils import bedrock

bedrock_client = bedrock.bedrock_client(
    assumed_role=os.environ.get("BEDROCK_ASSUME_ROLE", None),
    region=os.environ.get("bedrock_region", None)
)


def lambda_handler(event, context):
    # Extract the request body from the event object
    # body = json.loads(event["body"])
    body = event["body"]

    # Extract the prompt string from the request body
    prompt = body["prompt"]
    print("Prompt = " + prompt)

    # [2024-01-21] Parameters from environment variable.
    temperature = os.environ.get("TEMPERATURE", 0.5)
    top_p = os.environ.get("TOP_P", 1)
    top_k = os.environ.get("TOP_K", 250)
    max_tokens_to_sample = os.environ.get("MAX_TOKENS_TO_SAMPLE", 768)

    # Create the body
    body = json.dumps({
        'prompt': "\n\nHuman:" + prompt + "\n\nAssistant:",
        "temperature": temperature,
        "top_p": top_p,
        "top_k": top_k,
        "max_tokens_to_sample": max_tokens_to_sample,
        "stop_sequences": ["\n\nHuman:"]
    })

    # Set the model id and other parameters required to invoke the model
    model_id = 'anthropic.claude-v2'
    accept = 'application/json'
    content_type = 'application/json'

    # Invoke Bedrock API
    response = bedrock_client.invoke_model(body=body, modelId=model_id, accept=accept, contentType=content_type)
    print("response: ", response)

    # Parse the response body
    response_body = json.loads(response.get('body').read())
    print("response_body: ", response_body)

    completion = response_body.get('completion')
    print("completion: ", completion)

    return {
        'statusCode': 200,
        # 'body': json.dumps({
        #     'generated-text': response_body
        # })
        'completion': completion
    }
