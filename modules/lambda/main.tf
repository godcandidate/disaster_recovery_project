# Lambda Module for Disaster Recovery

# Using IAM role from IAM module for Lambda function

# Lambda security group
resource "aws_security_group" "lambda_sg" {
  name        = "dr-lambda-${var.function_name}-sg-${var.environment}"
  description = "Security group for Lambda function to access RDS"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "dr-lambda-${var.function_name}-sg"
      Environment = var.environment
    },
    var.tags
  )
}

# Lambda function
resource "aws_lambda_function" "function" {
  function_name = "dr-${var.function_name}-${var.environment}"
  description   = "Lambda function for ${var.function_name} in ${var.environment} environment"
  role          = var.lambda_role_arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30
  memory_size   = 256

  filename      = "${path.module}/function/lambda_function.zip"

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      DB_HOST     = var.db_host
      DB_USER     = var.db_username
      DB_PASSWORD = var.db_password
      DB_NAME     = var.db_name
      ENABLED     = var.enabled ? "true" : "false"
    }
  }

  tags = merge(
    {
      Name        = "dr-${var.function_name}"
      Environment = var.environment
    },
    var.tags
  )
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/dr-${var.function_name}-${var.environment}"
  retention_in_days = 14

  tags = merge(
    {
      Name        = "dr-${var.function_name}-logs"
      Environment = var.environment
    },
    var.tags
  )
}

# CloudWatch Event Rule for daily trigger (if enabled)
resource "aws_cloudwatch_event_rule" "daily_trigger" {
  count               = var.enabled ? 1 : 0
  name                = "dr-${var.function_name}-daily-trigger-${var.environment}"
  description         = "Trigger Lambda function daily"
  schedule_expression = "cron(0 8 * * ? *)" # 8:00 AM UTC every day

  tags = merge(
    {
      Name        = "dr-${var.function_name}-daily-trigger"
      Environment = var.environment
    },
    var.tags
  )
}

# CloudWatch Event Target for Lambda
resource "aws_cloudwatch_event_target" "lambda_target" {
  count     = var.enabled ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_trigger[0].name
  target_id = "dr-${var.function_name}-target"
  arn       = aws_lambda_function.function.arn
}

# Permission for CloudWatch to invoke Lambda
resource "aws_lambda_permission" "allow_cloudwatch" {
  count         = var.enabled ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_trigger[0].arn
}
