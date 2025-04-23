# This file contains resources that will be created in a second phase
# after both Lambda and API Gateway are created

# Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gateway" {
  count         = var.api_gateway_execution_arn != null ? 1 : 0
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dr_failover.function_name
  principal     = "apigateway.amazonaws.com"
  
  # The source ARN is the API Gateway invoke URL
  source_arn = "${var.api_gateway_execution_arn}/*/*"
}
