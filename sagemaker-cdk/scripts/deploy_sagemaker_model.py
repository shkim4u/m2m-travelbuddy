import sys

import boto3
import sagemaker
from sagemaker.jumpstart.model import JumpStartModel

sagemaker_session = sagemaker.Session()


def main():
    # Take model_id argument.
    # model_id = meta-textgeneration-llama-codellama-7b-instruct ml.g5.4xlarge
    model_id = sys.argv[1]
    model_name = "{}-{}".format(model_id, "model")
    endpoint_name = "{}-{}".format(model_id, "endpoint")

    # instance_type = ml.g5.4xlarge
    instance_type = sys.argv[2]
    model = JumpStartModel(model_id=model_id, name=model_name)
    predictor = model.deploy(initial_instance_count=1, instance_type=instance_type, endpoint_name=endpoint_name,
                             accept_eula=True)

    # Perform some examples.
    example_payloads = model.retrieve_all_examples()
    model.retrieve_example_payload()

    for payload in example_payloads:
        response = predictor.predict(payload.body)
        print("\nInput\n", payload.body, "\n\nOutput\n", response[0]["generated_text"], "\n\n===============")

    print("Model: ", model.name)
    print("Endpoint: ", model.endpoint_name)

    # Get AWS boto3 session.
    boto_session = boto3.Session()
    ssm_client = boto_session.client("ssm")
    ssm_client.put_parameter(
        Name="text_generation_sagemaker_endpoint",
        Value=model.endpoint_name,
        Type="String",
        Overwrite=True
    )
    print("Model endpoint written to SSM parameter store: ", "text_generation_sagemaker_endpoint")


if __name__ == "__main__":
    main()
