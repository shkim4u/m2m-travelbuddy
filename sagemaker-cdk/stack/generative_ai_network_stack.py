from aws_cdk import (
    Stack,
    aws_ec2 as ec2
)
from constructs import Construct

"""
VPC CIDR Candidates:
- 10.0.0.0/8
- 172.16.0.0/12
- 192.168.0.0/16
"""


class GenerativeAiNetworkStackStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Access the "env" variable from kwargs using the environment property
        region = kwargs.get('region')
        # region = env.get('region')
        self.output_vpc = ec2.Vpc(
            self,
            "VPC",
            nat_gateways=1,
            ip_addresses=ec2.IpAddresses.cidr("192.168.0.0/16"),
            # max_azs=2,
            availability_zones=[f"{region}a", f"{region}c"],
            subnet_configuration=[
                ec2.SubnetConfiguration(name="public", subnet_type=ec2.SubnetType.PUBLIC, cidr_mask=24),
                ec2.SubnetConfiguration(name="private", subnet_type=ec2.SubnetType.PRIVATE_WITH_EGRESS, cidr_mask=24)
            ]
        )

    @property
    def vpc(self) -> ec2.Vpc:
        return self.output_vpc
