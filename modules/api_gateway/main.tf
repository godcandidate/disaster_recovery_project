# API Gateway Module for Disaster Recovery

# API Gateway REST API
resource "aws_api_gateway_rest_api" "dr_failover" {
  name        = "dr-failover-api-${var.environment}"
  description = "API Gateway for disaster recovery failover"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  
  tags = merge(
    {
      Name        = "dr-failover-api-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# API Gateway Resource
resource "aws_api_gateway_resource" "failover" {
  rest_api_id = aws_api_gateway_rest_api.dr_failover.id
  parent_id   = aws_api_gateway_rest_api.dr_failover.root_resource_id
  path_part   = "failover"
}

# API Gateway Method
resource "aws_api_gateway_method" "failover_post" {
  rest_api_id   = aws_api_gateway_rest_api.dr_failover.id
  resource_id   = aws_api_gateway_resource.failover.id
  http_method   = "POST"
  authorization = "AWS_IAM"
  
  request_validator_id = aws_api_gateway_request_validator.failover.id
  
  request_models = {
    "application/json" = aws_api_gateway_model.failover_request.name
  }
}

# API Gateway Request Validator
resource "aws_api_gateway_request_validator" "failover" {
  name                        = "dr-failover-validator"
  rest_api_id                 = aws_api_gateway_rest_api.dr_failover.id
  validate_request_body       = true
  validate_request_parameters = true
}

# API Gateway Model for Request Validation
resource "aws_api_gateway_model" "failover_request" {
  rest_api_id  = aws_api_gateway_rest_api.dr_failover.id
  name         = "FailoverRequest"
  description  = "Failover request model"
  content_type = "application/json"
  
  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    title     = "FailoverRequest"
    type      = "object"
    required  = ["source", "timestamp"]
    properties = {
      source = {
        type = "string"
      }
      timestamp = {
        type = "string"
      }
      detail = {
        type = "object"
      }
    }
  })
}

# API Gateway Integration with Lambda
resource "aws_api_gateway_integration" "failover_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.dr_failover.id
  resource_id             = aws_api_gateway_resource.failover.id
  http_method             = aws_api_gateway_method.failover_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
  
  # No request templates needed for Lambda proxy integration
}

# API Gateway Method Response
resource "aws_api_gateway_method_response" "failover_post_200" {
  rest_api_id = aws_api_gateway_rest_api.dr_failover.id
  resource_id = aws_api_gateway_resource.failover.id
  http_method = aws_api_gateway_method.failover_post.http_method
  status_code = "200"
  
  response_models = {
    "application/json" = "Empty"
  }
}

# API Gateway Integration Response
resource "aws_api_gateway_integration_response" "failover_lambda_200" {
  rest_api_id = aws_api_gateway_rest_api.dr_failover.id
  resource_id = aws_api_gateway_resource.failover.id
  http_method = aws_api_gateway_method.failover_post.http_method
  status_code = aws_api_gateway_method_response.failover_post_200.status_code
  
  response_templates = {
    "application/json" = ""
  }
  
  depends_on = [aws_api_gateway_integration.failover_lambda]
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "dr_failover" {
  rest_api_id = aws_api_gateway_rest_api.dr_failover.id
  
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.failover.id,
      aws_api_gateway_method.failover_post.id,
      aws_api_gateway_integration.failover_lambda.id
    ]))
  }
  
  lifecycle {
    create_before_destroy = true
  }
  
  depends_on = [
    aws_api_gateway_method.failover_post,
    aws_api_gateway_integration.failover_lambda
  ]
}

# API Gateway Stage
resource "aws_api_gateway_stage" "dr_failover" {
  deployment_id = aws_api_gateway_deployment.dr_failover.id
  rest_api_id   = aws_api_gateway_rest_api.dr_failover.id
  stage_name    = var.environment
  
  tags = merge(
    {
      Name        = "dr-failover-stage-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# IAM Role for API Gateway to invoke Lambda
resource "aws_iam_role" "api_gateway_lambda" {
  name = "dr-api-gateway-lambda-role-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(
    {
      Name        = "dr-api-gateway-lambda-role-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# IAM Policy for API Gateway to invoke Lambda
resource "aws_iam_policy" "api_gateway_lambda" {
  name        = "dr-api-gateway-lambda-policy-${var.environment}"
  description = "Policy for API Gateway to invoke Lambda"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Resource = var.lambda_arn
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "api_gateway_lambda" {
  role       = aws_iam_role.api_gateway_lambda.name
  policy_arn = aws_iam_policy.api_gateway_lambda.arn
}
