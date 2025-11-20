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
  image_uri     = "${aws_ecr_repository.app1_repo.repository_url}:latest"
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


