provider "aws" {
  region = "us-east-1"
 }
 
resource "aws_ecr_repository" "app1_repo" {
  name = "node-app1"
}

resource "aws_ecr_repository" "app2_repo" {
  name = "node-app2"
}

resource "aws_lambda_function" "app1_lambda" {
  function_name = "node-app1-fn"
  image_uri     = "${aws_ecr_repository.app1_repo.repository_url}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda_exec.arn
  timeout       = 10
  memory_size   = 512
}

resource "aws_lambda_function" "app2_lambda" {
  function_name = "node-app2-fn"
  image_uri     = "${aws_ecr_repository.app2_repo.repository_url}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda_exec.arn
  timeout       = 10
  memory_size   = 512
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}


#########################

resource "aws_apigatewayv2_api" "http_api" {

  name          = "node-microservices-api"

  protocol_type = "HTTP"

}



# Integrations

resource "aws_apigatewayv2_integration" "app1_integration" {

  api_id                 = aws_apigatewayv2_api.http_api.id

  integration_type       = "AWS_PROXY"

  integration_uri        = aws_lambda_function.app1_lambda.invoke_arn

  integration_method     = "POST"

  payload_format_version = "2.0"

}



resource "aws_apigatewayv2_integration" "app2_integration" {

  api_id                 = aws_apigatewayv2_api.http_api.id

  integration_type       = "AWS_PROXY"

  integration_uri        = aws_lambda_function.app2_lambda.invoke_arn

  integration_method     = "POST"

  payload_format_version = "2.0"

}



# Routes

resource "aws_apigatewayv2_route" "app1_route" {

  api_id    = aws_apigatewayv2_api.http_api.id

  route_key = "ANY /app1"

  target    = "integrations/${aws_apigatewayv2_integration.app1_integration.id}"

}



resource "aws_apigatewayv2_route" "app2_route" {

  api_id    = aws_apigatewayv2_api.http_api.id

  route_key = "ANY /app2"

  target    = "integrations/${aws_apigatewayv2_integration.app2_integration.id}"

}



# Stage (auto deploy)

resource "aws_apigatewayv2_stage" "prod" {

  api_id      = aws_apigatewayv2_api.http_api.id

  name        = "prod"

  auto_deploy = true

}



#########################

# Lambda permissions for API Gateway

#########################

resource "aws_lambda_permission" "app1_permission" {

  statement_id  = "AllowAPIGatewayInvoke_app1"

  action        = "lambda:InvokeFunction"

  function_name = aws_lambda_function.app1_lambda.arn

  principal     = "apigateway.amazonaws.com"

  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"

}



resource "aws_lambda_permission" "app2_permission" {

  statement_id  = "AllowAPIGatewayInvoke_app2"

  action        = "lambda:InvokeFunction"

  function_name = aws_lambda_function.app2_lambda.arn

  principal     = "apigateway.amazonaws.com"

  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"

}



#########################

# Outputs

#########################

output "api_invoke_url" {

  description = "Base invoke URL for the HTTP API (stage prod)"

  value       = aws_apigatewayv2_stage.prod.invoke_url

}


output "app1_endpoint" {

  value = "${aws_apigatewayv2_stage.prod.invoke_url}app1"



