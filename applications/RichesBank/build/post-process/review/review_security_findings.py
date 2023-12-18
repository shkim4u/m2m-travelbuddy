import json
import os
import sys

import botocore
import sarif_om
from sarif import loader

# module_path = ".."
# sys.path.append(os.path.abspath(module_path))
from utils import bedrock, print_ww
from utils.sarif_utils import get_code_snippet, construct_prompt, materialize
from utils.send_to_collaboration_channel import send_to_slack_channel

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

with open(path_to_sarif_file, 'r') as file:
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

# Check the environment variable integer value "SLACK_SEND_BATCH_SIZE".
# 0: send all vulnerability infos to Slack at once at last.
# <N>: send all vulnerability infos to Slack at once at last, but also in batches of <N> vulnerabilities.

slack_send_batch_size = os.environ.get("SLACK_SEND_BATCH_SIZE", 1)

vulnerability_infos = []
# Iterate over all results.
for index, sarif_result in sarif_results:
    # Get the message and rule index of the current finding.
    message_text = sarif_result.message.text
    rule_index = sarif_result.rule_index

    # Get the rule of the current finding.
    rule = sarif_rules[rule_index]
    rule_help_uri = rule.help_uri
    # TODO: Find some other useful links to include something like below.
    # There are shown when loading SpotBugs report XML file onto the SpotBugs UI.
    # References
    # Wikipedia: Authenticated encryption: https://en.wikipedia.org/wiki/Authenticated_encryption
    # NIST: Authenticated Encryption Modes: https://csrc.nist.gov/projects/block-cipher-techniques/bcm/modes-development#01
    # Moxie Marlinspike's blog: The Cryptographic Doom Principle: https://moxie.org/blog/the-cryptographic-doom-principle/
    # CWE-353: Missing Support for Integrity Check: https://cwe.mitre.org/data/definitions/353.html

    # Consider only the first relationship for now (eg. CWE).
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
        "temperature": 0.1,
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
        completion = response_body.get('completion')
        print(f"=== [{index}] 답변 시작 ===")
        print_ww(completion)
        print(f"=== [{index}] 답변 끝 ===")

        vulnerability_infos.append({
            "pretext": f"보안 취약점 정보 [{index}]: {artifact_location_uri}: [line {relevant_code_line}]",
            "title": f"{target_name}-{target_id}: {message_text}",
            "title_link": rule_help_uri,
            "fields": [
                {
                    "title": "취약점 코드 조각",
                    "value": f"```java\n{code_snippet}\n```",
                    "short": False
                },
                {
                    "title": "권장 조치 사항",
                    "value": f"```{completion}```",
                    "short": False
                }
            ]
        })

        # Check if "slack_send_batch_size" is multiple of "index + 1" and not "0".
        # If so, send the vulnerability infos to Slack.
        if slack_send_batch_size != 0 and (index + 1) % int(slack_send_batch_size) == 0:
            slack_webhook_url = os.environ.get("SLACK_WEBHOOK_URL", None)
            slack_channel = os.environ.get("SLACK_CHANNEL", None)
            send_to_slack_channel(
                webhook_url=slack_webhook_url,
                channel=slack_channel,
                icon_emoji=":warning:",
                text="어플리케이션 보안 취약점: (TODO) 스캔 시간, Application 이름, Committer, CommitId 등",
                vulnerability_infos=vulnerability_infos
            )
            vulnerability_infos = []

    except botocore.exceptions.ClientError as error:
        if error.response['Error']['Code'] == 'AccessDeniedException':
            print(f"\x1b[41m{error.response['Error']['Message']}\
                    \n해당 이슈를 트러블슈팅하기 위해서는 다음 문서를 참고하세요.\
                     \nhttps://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_access-denied.html\
                     \nhttps://docs.aws.amazon.com/bedrock/latest/userguide/security-iam.html\x1b[0m\n")

        else:
            raise error

# TODO: 전체 취약점 정보를 모아 한번에 Slack으로 보내는데, Slack 메시지의 최대 길이는 40,000자이므로 이 사항을 확인하여 건별로 보내는 것도 고려할 것.
# Truncating content
# ===
# For best results, limit the number of characters in the text field to 4,000 characters. Ideally, messages should be short and human-readable. Slack will truncate messages containing more than 40,000 characters. If you need to post longer messages, please consider uploading a snippet instead.
# # If using blocks, the limit and truncation of characters will be determined by the specific type of block.
# ===
# https://api.slack.com/methods/chat.postMessage
# For Free and Standard plans: The maximum message size is 1MB, which includes the message text, any attachments, and inline images.
# For Plus and Enterprise Grid plans: The maximum message size is 2GB.
# Check if "vulnerability_infos" has any vulnerability info left.
if len(vulnerability_infos) > 0:
    slack_webhook_url = os.environ.get("SLACK_WEBHOOK_URL", None)
    slack_channel = os.environ.get("SLACK_CHANNEL", None)
    send_to_slack_channel(
        webhook_url=slack_webhook_url,
        channel=slack_channel,
        icon_emoji=":warning:",
        text="어플리케이션 보안 취약점: (TODO) 스캔 시간, Application 이름, Committer, CommitId 등",
        vulnerability_infos=vulnerability_infos
    )
