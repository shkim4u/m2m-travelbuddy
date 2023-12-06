import json
import boto3

runtime = boto3.client('runtime.sagemaker')

MAX_NEW_TOKEN = 512
TOP_P = 0.9
TEMPERATURE = 0.2
DECODER_INPUT_DETAILS = True
DETAILS = True


def lambda_handler(event, context):
    body = json.loads(event['body'])
    prompt = body['prompt']
    endpoint_name = body['endpoint_name']

    payload = {
        'inputs': prompt,
        'parameters': {
            'max_new_tokens': MAX_NEW_TOKEN,
            'top_p': TOP_P,
            'temperature': TEMPERATURE,
            'decoder_input_details': DECODER_INPUT_DETAILS,
            'details': DETAILS
        }
    }

    payload = json.dumps(payload).encode('utf-8')

    response = runtime.invoke_endpoint(EndpointName=endpoint_name,
                                       ContentType='application/json',
                                       Body=payload)

    model_predictions = json.loads(response['Body'].read())
    # generated_text = model_predictions['generated_texts'][0]
    generated_text = model_predictions[0]['generated_text']

    message = {"prompt": prompt, 'generated_text': generated_text}

    return {
        "statusCode": 200,
        "body": json.dumps(message),
        "headers": {
            "Content-Type": "application/json"
        }
    }
