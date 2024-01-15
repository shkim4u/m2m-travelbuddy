# Get the policy by name
data "aws_iam_policy" "lambda_execution_policy" {
  name = "AWSLambdaExecute"
}
