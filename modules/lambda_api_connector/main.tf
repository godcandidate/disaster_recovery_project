# Lambda API Gateway Connector Module
# This module connects a Lambda function to an API Gateway
# after both resources have been created

# Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  
  # The source ARN is the API Gateway invoke URL
  source_arn = "${var.api_gateway_execution_arn}/*/*"
}
