#!/bin/bash

source .venv/bin/activate

# Retrieve "DEV_SLACK_WEBHOOK_URL" from the first argument.
DEV_SLACK_WEBHOOK_URL=$1
# Retrieve "DEV_SLACK_CHANNEL" from the second argument.
DEV_SLACK_CHANNEL=$2

# Check if the "DEV_SLACK_WEBHOOK_URL" or "DEV_SLACK_CHANNEL" is empty.
if [ -z "$DEV_SLACK_WEBHOOK_URL" ] || [ -z "$DEV_SLACK_CHANNEL" ]; then
    echo "Usage: $0 <DEV_SLACK_WEBHOOK_URL> <DEV_SLACK_CHANNEL>"
    exit 1
fi

export DEV_SLACK_WEBHOOK_URL=$1
export DEV_SLACK_CHANNEL=$2

python review_security_findings.py spotbugs-sarif.json
