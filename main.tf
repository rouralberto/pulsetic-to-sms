terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

variable "twilio_account_sid" {
  description = "Twilio Account SID"
  type        = string
  sensitive   = true
}

variable "twilio_auth_token" {
  description = "Twilio Auth Token"
  type        = string
  sensitive   = true
}

variable "twilio_from_number" {
  description = "Twilio phone number to send SMS from"
  type        = string
}

variable "to_number" {
  description = "Phone number to send SMS alerts to"
  type        = string
}

# Create a zip file for the Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = path.module
  output_path = "${path.module}/lambda_function.zip"
  excludes = [
    "*.tf",
    "*.tfvars",
    "*.tfstate*",
    ".terraform*",
    "README.md",
    ".git*",
    "lambda_function.zip",
    "deploy.sh",
    "update.sh",
    ".gitignore"
  ]
}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "pulsetic-sms-lambda-role"

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

# IAM policy attachment for basic Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda function
resource "aws_lambda_function" "pulsetic_sms" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "pulsetic-to-sms"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "nodejs22.x"
  timeout          = 5

  environment {
    variables = {
      TWILIO_ACCOUNT_SID = var.twilio_account_sid
      TWILIO_AUTH_TOKEN  = var.twilio_auth_token
      TWILIO_FROM_NUMBER = var.twilio_from_number
      TO_NUMBER          = var.to_number
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_cloudwatch_log_group.lambda_logs,
  ]
}

# CloudWatch Log Group for Lambda function
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/pulsetic-to-sms"
  retention_in_days = 14
}

# Lambda Function URL
resource "aws_lambda_function_url" "pulsetic_sms_url" {
  function_name      = aws_lambda_function.pulsetic_sms.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["POST"]
    allow_headers     = ["date", "keep-alive", "content-type"]
    expose_headers    = ["date", "keep-alive"]
    max_age           = 86400
  }
}

# Outputs
output "lambda_function_url" {
  description = "The HTTP URL endpoint for the Lambda function"
  value       = aws_lambda_function_url.pulsetic_sms_url.function_url
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.pulsetic_sms.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.pulsetic_sms.arn
}
