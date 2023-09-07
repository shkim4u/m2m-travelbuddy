###
### Referenes
### - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/msk_cluster
###
resource "aws_cloudwatch_log_group" "m2m_msk" {
  name = "/m2m/msk/M2M-MSK-Cluster"
  retention_in_days = 7

  tags = {
    Environment = "Test/Dev/Prod"
    Application = "M2M"
  }
}

resource "aws_security_group" "m2m_msk" {
  name = "M2M-MSK-Cluster-Security-Group"
  vpc_id = var.vpc_id
  description = "Security group for M2M MSK cluster"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
#  for_each = {
#    for k, v in {
#      PlainTextCommunication = {
#        from_port = 9092
#        to_port = 9092
#        protocol = "tcp"
#        cidr_blocks = [var.vpc_cidr_block]
#        description = "Kafka communication (Plaintext)"
#      },
#      TLSCommunication = {
#        from_port = 9094
#        to_port = 9094
#        protocol = "tcp"
#        cidr_blocks = [var.vpc_cidr_block]
#        description = "Kafka communication (TLS)"
#      },
#      SaslScramCommunication = {
#        from_port = 9096
#        to_port = 9096
#        protocol = "tcp"
#        cidr_blocks = [var.vpc_cidr_block]
#        description = "Kafka communication (SASL/SCRAM)"
#      },
#      IAMCommunication = {
#        from_port = 9098
#        to_port = 9098
#        protocol = "tcp"
#        cidr_blocks = [var.vpc_cidr_block]
#        description = "Kafka communication (IAM)"
#      },
#      ZooKeeperCommunication = {
#        from_port = 2181
#        to_port = 2181
#        protocol = "tcp"
#        cidr_blocks = [var.vpc_cidr_block]
#        description = "Kafka ZooKeeper"
#      }
#    }: k => v if true
#  }
#  ingress {
#    from_port = each.value.from_port
#    to_port = each.value.to_port
#    protocol = each.value.protocol
#    cidr_blocks = each.value.cidr_blocks
#    description = each.value.description
#  }
  ingress {
    from_port = 9092
    to_port = 9092
    protocol = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Kafka communication (Plaintext)"
  }
  ingress {
    from_port = 9094
    to_port = 9094
    protocol = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Kafka communication (TLS)"
  }
  ingress {
    from_port = 9096
    to_port = 9096
    protocol = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Kafka communication (SASL/SCRAM)"
  }
  ingress {
    from_port = 9098
    to_port = 9098
    protocol = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Kafka communication (IAM)"
  }
  ingress {
    from_port = 2181
    to_port = 2181
    protocol = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Kafka ZooKeeper"
  }
}


resource "aws_msk_cluster" "m2m_msk" {
  cluster_name = "M2M-MSK-Cluster"
  kafka_version = "2.8.1"
  number_of_broker_nodes = (length(var.subnet_ids) * 2)
  broker_node_group_info {
    client_subnets = var.subnet_ids
    instance_type = "kafka.m5.large"
    security_groups = [aws_security_group.m2m_msk.id]
  }
  encryption_info {
    encryption_in_transit {
      in_cluster = true
      client_broker = "TLS"
    }
  }
  client_authentication {
    sasl {
      iam = true
    }
  }
  enhanced_monitoring = "PER_TOPIC_PER_BROKER"
  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled = true
        log_group = aws_cloudwatch_log_group.m2m_msk.name
      }
    }
  }
  tags = {
    Description = "MSK Cluster for M2M project"
    Owner = "AWS ProServe"
  }

  timeouts {
    create = "2h"
    update = "2h"
    delete = "2h"
  }
}
