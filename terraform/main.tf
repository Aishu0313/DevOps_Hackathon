###########################################
# Terraform + AWS Provider
###########################################
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

###########################################
# ECR Repositories
###########################################
resource "aws_ecr_repository" "app1_repo" {
  name = "node-app1"
}

resource "aws_ecr_repository" "app2_repo" {
  name = "node-app2"
}

###########################################
# IAM Role for Lambda
###########################################
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_exec_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

###########################################
# IAM Policy for ECR Access
###########################################
resource "aws_iam_policy" "ecr_read_policy" {
  name        = "LambdaECRReadPolicy-6"
  description = "Allow Lambda to pull container images from ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRReadAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:DescribeImages"
        ]
        Resource = [
          aws_ecr_repository.app1_repo.arn,
          aws_ecr_repository.app2_repo.arn
        ]
      },
      {
        Sid      = "ECRAuth"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ecr_read" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.ecr_read_policy.arn
}

###########################################
# Lambda Functions (Container Image)
###########################################
resource "aws_lambda_function" "app1_lambda" {
  function_name = "node-app1-fn"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.app1_repo.repository_url}:latest"
  role          = aws_iam_role.lambda_exec.arn
  timeout       = 10
  memory_size   = 512
}

resource "aws_lambda_function" "app2_lambda" {
  function_name = "node-app2-fn"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.app2_repo.repository_url}:latest"
  role          = aws_iam_role.lambda_exec.arn
  timeout       = 10
  memory_size   = 512
}

###########################################
# API Gateway (HTTP API)
###########################################
resource "aws_apigatewayv2_api" "http_api" {
  name          = "lambda-http-api"
  protocol_type = "HTTP"
}

# Lambda permission for API Gateway to invoke
resource "aws_lambda_permission" "api_permission" {
  statement_id  = "AllowInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.patient_service.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# ANY /{proxy+}
resource "aws_apigatewayv2_route" "proxy_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Integration
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type        = "AWS_PROXY"
  integration_uri         = aws_lambda_function.patient_service.invoke_arn
  payload_format_version  = "2.0"
}

# Deployment stage
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "prod"
  auto_deploy = true
}

output "api_url" {
  value = aws_apigatewayv2_stage.prod.invoke_url
}
}
