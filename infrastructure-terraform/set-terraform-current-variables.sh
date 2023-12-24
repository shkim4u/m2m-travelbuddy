#!/bin/bash

export TF_VAR_ca_arn=`terraform output -raw eks_ca_arn` && echo $TF_VAR_ca_arn
export TF_VAR_eks_cluster_name=`terraform output -raw eks_cluster_name` && echo $TF_VAR_eks_cluster_name
export TF_VAR_cicd_appsec_dev_slack_webhook_url=`terraform output -raw cicd_appsec_dev_slack_webhook_url` && echo $TF_VAR_cicd_appsec_dev_slack_webhook_url
export TF_VAR_cicd_appsec_dev_slack_channel=`terraform output -raw cicd_appsec_dev_slack_channel` && echo $TF_VAR_cicd_appsec_dev_slack_channel
export TF_VAR_cicd_appsec_sec_slack_webhook_url=`terraform output -raw cicd_appsec_sec_slack_webhook_url` && echo $TF_VAR_cicd_appsec_sec_slack_webhook_url
export TF_VAR_cicd_appsec_sec_slack_channel=`terraform output -raw cicd_appsec_sec_slack_channel` && echo $TF_VAR_cicd_appsec_sec_slack_channel
