variable "lambda_bucket" {
  type = string
}
variable "lambda_prefix" {
  type = string
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {}
}
provider "aws" {
  region = "us-east-1"
}

resource "aws_ecr_repository" "lambda" {
  name = "docker-lambda-benchmark-lambda"
}

resource "aws_cloudwatch_log_group" "name" {
  for_each = toset([
    aws_lambda_function.zip_small.function_name,
    aws_lambda_function.zip_large.function_name,
    aws_lambda_function.image_small.function_name,
    aws_lambda_function.image_large.function_name,
  ])
  name              = "/aws/lambda/${each.value}"
  retention_in_days = 14
}

resource "aws_iam_role" "lambda" {
  name = "docker-lambda-benchmark-lambda"
  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Principal" = {
          "Service" = "lambda.amazonaws.com"
        },
        "Action" = "sts:AssumeRole"
      }
    ]
  })
  inline_policy {
    name = "run-lambda"
    policy = jsonencode({
      "Version" = "2012-10-17",
      "Statement" = [
        {
          "Effect" = "Allow",
          "Action" = [
            "logs:CreateLogStream",
            "logs:PutLogEvents",
          ]
          Resource = ["arn:aws:logs:*:*:*"]
        }
      ]
    })
  }
}

resource "aws_lambda_function" "zip_small" {
  function_name = "docker-lambda-benchmark-zip-small"
  handler       = "dist/index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda.arn
  s3_bucket     = var.lambda_bucket
  s3_key        = "${var.lambda_prefix}/small.zip"
  timeout       = 30
}

resource "aws_lambda_function" "zip_large" {
  function_name = "docker-lambda-benchmark-zip-large"
  handler       = "dist/index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda.arn
  s3_bucket     = var.lambda_bucket
  s3_key        = "${var.lambda_prefix}/large.zip"
  timeout       = 30
}

resource "aws_lambda_function" "image_small" {
  function_name = "docker-lambda-benchmark-image-small"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 30
  image_uri     = "${aws_ecr_repository.lambda.repository_url}:small"
  image_config {
    command = ["dist/index.handler"]
  }
}

resource "aws_lambda_function" "image_large" {
  function_name = "docker-lambda-benchmark-image-large"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 30
  image_uri     = "${aws_ecr_repository.lambda.repository_url}:large"
  image_config {
    command = ["dist/index.handler"]
  }
}

resource "aws_cloudwatch_query_definition" "lambda_cold_starts" {
  name            = "lambda_cold_starts"
  log_group_names = [for group in aws_cloudwatch_log_group.name : group.name]
  query_string    = <<-EOF
    fields @timestamp, @initDuration, @log
    | filter @type = "REPORT"
    | filter @initDuration > 0
    | stats avg(@initDuration) by @log
    | sort @log
  EOF
}
