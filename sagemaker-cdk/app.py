#!/usr/bin/env python3
import os
import aws_cdk as cdk
import boto3

from stack.generative_ai_network_stack import GenerativeAiNetworkStackStack

from stack.generative_ai_web_stack import GenerativeAiWebStack

"""
* [2023-12-01]
현재 CoudFormation 및 CDK가 JumpStart 모델을 지원하지 않는 것으로 보이므로
우선 Lambda, API Gateway, Prompt용 Web App 등 외부 자원만을 CDK로 배포하고,
SageMaker JumpStart Model 및 Endpoint는 SageMaker Python SDK를 사용하여 배포하도록 구성됨
"""

region_name = boto3.Session().region_name
env={"region": region_name}
# env = cdk.Environment(account=os.getenv('CDK_DEFAULT_ACCOUNT'), region=os.getenv('CDK_DEFAULT_REGION'))

app = cdk.App()

network_stack = GenerativeAiNetworkStackStack(app, "GenerativeAiNetworkStack", env=env)
GenerativeAiWebStack(app, "GenerativeAiWebStack", vpc=network_stack.vpc, env=env)

app.synth()
