import json
import boto3
import os
import traceback
import dns.query

from urllib.parse import urlparse


def extract_dns(url):
    parsed_url = urlparse(url)
    return parsed_url.netloc

# websocket
connection_url = os.environ.get('connection_url')
print('connection_url: ', connection_url)

dns_name = extract_dns(connection_url)
print('dns_name: ', dns_name)

# my_resolver = dns.resolver.Resolver()
# my_resolver.nameservers = ['8.8.8.8']
# print("nameservers: ", my_resolver.nameservers)

client = None


def sendMessage(id, body):
    # Connect to the client if client is none.
    global client
    if client is None:
        client = boto3.client('apigatewaymanagementapi', endpoint_url=connection_url)
    try:
        client.post_to_connection(
            ConnectionId=id,
            Data=json.dumps(body)
        )
    except:
        # Tell what kind of error it was.
        err_msg = traceback.format_exc()
        raise Exception("Not able to send a message: " + err_msg)


def lambda_handler(event, context):
    print('event: ', event)

    # (For debug) Get all environment variables
    env_vars = os.environ

    # Print each environment variable
    for key, value in env_vars.items():
        print(f'{key}: {value}')

    msg = ""
    if event['requestContext']:
        connectionId = event['requestContext']['connectionId']
        print('connectionId: ', connectionId)
        routeKey = event['requestContext']['routeKey']
        print('routeKey: ', routeKey)

        if routeKey == '$connect':
            print('connected!')
        elif routeKey == '$disconnect':
            print('disconnected!')
        else:
            body = event.get("body", "")
            # print("data[0:8]: ", body[0:8])
            if body[0:8] == "__ping__":
                print("ping!.....")
                sendMessage(connectionId, "__pong__")
            else:
                jsonBody = json.loads(body)
                print('body: ', jsonBody)

                requestId = jsonBody['request_id']

                result = {
                    'request_id': requestId,
                    'msg': "Hello from Lambda!"
                }
                # print('result: ', json.dumps(result))
                sendMessage(connectionId, result)

    return {
        'statusCode': 200
    }
