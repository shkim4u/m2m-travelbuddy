from sarif import loader
import json

import attrs
import sarif_om

import json
import os
import sys

import boto3
import botocore

# module_path = ".."
# sys.path.append(os.path.abspath(module_path))
from utils import bedrock, print_ww
from utils.sarif_utils import get_code_snippet, construct_prompt, materialize

# Ensure that at least one argument is passed.
if len(sys.argv) < 2:
    # Show usage.
    print("Usage: python sarif_riches_all.py <path_to_sarif_file>")
    sys.exit(1)

# Take the first argument and pass that to "path_to_sarif_file".
# path_to_sarif_file = "spotbugs-sarif.json"
path_to_sarif_file = sys.argv[1]

# End verify it is not empty.
if path_to_sarif_file == "":
    print("Error: path_to_sarif_file is empty.")
    sys.exit(1)

sarif_data = loader.load_sarif_file(path_to_sarif_file)
issue_count_by_severity = sarif_data.get_result_count_by_severity()
error_histogram = sarif_data.get_issue_code_histogram("error")
warning_histogram = sarif_data.get_issue_code_histogram("warning")
note_histogram = sarif_data.get_issue_code_histogram("note")

print(f"Issue count by severity: {issue_count_by_severity}")
print(f"Error histogram: {error_histogram}")
print(f"Warning histogram: {warning_histogram}")
print(f"Note histogram: {note_histogram}")

with open('spotbugs-sarif.json', 'r') as file:
    data = json.load(file)

with open('sarif-schema-2.1.0.json', 'r') as file:
    schema = json.load(file)

sarif_log = materialize(data, sarif_om.SarifLog, schema, '#')

# Typically only one run in SARIF format.
sarif_run = sarif_log.runs[0]
sarif_rules = sarif_run.tool.driver.rules
sarif_results = sarif_run.results

# Initialize Bedrock client.
# ---- ⚠️ Un-comment and edit the below lines as needed for your AWS setup ⚠️ ----
os.environ["AWS_DEFAULT_REGION"] = "us-east-1"  # E.g. "us-east-1"
boto3_bedrock = bedrock.get_bedrock_client(
    assumed_role=os.environ.get("BEDROCK_ASSUME_ROLE", None),
    region=os.environ.get("AWS_DEFAULT_REGION", None)
)

# Convert sarif_results to iterable.
sarif_results = enumerate(sarif_results)

# Iterate over all results.
for index, sarif_result in sarif_results:
    # Get the message and rule index of the current finding.
    message_text = sarif_result.message.text
    rule_index = sarif_result.rule_index

    # Get the rule of the current finding.
    rule = sarif_rules[rule_index]
    # Consider only the first relationship (eg. CWE).
    relationship = rule.relationships[0]
    target_id = relationship.target.id
    target_name = relationship.target.tool_component.name

    # Consider the first location for now.
    location = sarif_result.locations[0]
    artifact_location_uri = location.physical_location.artifact_location.uri
    relevant_code_line = location.physical_location.region.start_line

    code_snippet = get_code_snippet(artifact_location_uri, relevant_code_line)
    prompt = construct_prompt(target_name, target_id, message_text, code_snippet)
    print(f"=== [{index}] Prompt 시작 ===")
    print(prompt)
    print(f"=== [{index}] Prompt 끝 ===")

    # Request body.
    body = json.dumps({
        "prompt": f"\n\nHuman: {prompt}\n\nAssistant:",
        "max_tokens_to_sample": 1024,
        "temperature": 0.05,
        "top_p": 0.9,
        "stop_sequences": ["\n\nHuman:"]
    })

    # https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids-arns.html
    modelId = 'anthropic.claude-v2:1'
    # modelId = 'anthropic.claude-instant-v1'
    accept = 'application/json'
    contentType = 'application/json'
    outputText = "\n"

    try:
        response = boto3_bedrock.invoke_model(body=body, modelId=modelId, accept=accept,
                                              contentType=contentType)
        response_body = json.loads(response.get('body').read())
        print(f"=== [{index}] 답변 시작 ===")
        print_ww(response_body.get('completion'))
        print(f"=== [{index}] 답변 끝 ===")
    except botocore.exceptions.ClientError as error:
        if error.response['Error']['Code'] == 'AccessDeniedException':
            print(f"\x1b[41m{error.response['Error']['Message']}\
                    \n해당 이슈를 트러블슈팅하기 위해서는 다음 문서를 참고하세요.\
                     \nhttps://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_access-denied.html\
                     \nhttps://docs.aws.amazon.com/bedrock/latest/userguide/security-iam.html\x1b[0m\n")

        else:
            raise error
