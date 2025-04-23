# Lambda Module for DR Failover

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "dr-lambda-role-${var.environment}"
  
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
  
  tags = merge(
    {
      Name        = "dr-lambda-role-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# IAM Policy for Lambda to manage Auto Scaling
resource "aws_iam_policy" "lambda_asg_policy" {
  name        = "dr-lambda-asg-policy-${var.environment}"
  description = "Policy for Lambda to manage Auto Scaling Groups"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:SetDesiredCapacity"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# IAM Policy for Lambda CloudWatch Logs
resource "aws_iam_policy" "lambda_logs_policy" {
  name        = "dr-lambda-logs-policy-${var.environment}"
  description = "Policy for Lambda to write to CloudWatch Logs"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach policies to role
resource "aws_iam_role_policy_attachment" "lambda_asg_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_asg_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logs_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logs_policy.arn
}

# Lambda function for DR failover
resource "aws_lambda_function" "dr_failover" {
  function_name    = "dr-failover-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs16.x"
  timeout          = 30
  memory_size      = 128
  
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  
  environment {
    variables = {
      AUTO_SCALING_GROUP_NAME = var.asg_name
      TARGET_GROUP_ARN        = var.target_group_arn
      DESIRED_CAPACITY        = "1"
    }
  }
  
  tags = merge(
    {
      Name        = "dr-failover-lambda-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# Create Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"
  
  source {
    content  = <<EOF
const AWS = require('aws-sdk');

exports.handler = async (event) => {
    const autoscaling = new AWS.AutoScaling();
    
    // Get environment variables
    const asgName = process.env.AUTO_SCALING_GROUP_NAME;
    const desiredCapacity = process.env.DESIRED_CAPACITY;
    
    console.log('Updating Auto Scaling Group ' + asgName + ' to desired capacity ' + desiredCapacity);
    
    try {
        // Update the Auto Scaling Group
        const asgResult = await autoscaling.updateAutoScalingGroup({
            AutoScalingGroupName: asgName,
            DesiredCapacity: parseInt(desiredCapacity),
            MinSize: parseInt(desiredCapacity)
        }).promise();
        
        console.log('Auto Scaling Group updated successfully');
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'DR failover initiated successfully',
                asgName: asgName,
                desiredCapacity: desiredCapacity
            })
        };
    } catch (error) {
        console.error('Error updating Auto Scaling Group:', error);
        
        return {
            statusCode: 500,
            body: JSON.stringify({
                message: 'Error initiating DR failover',
                error: error.message
            })
        };
    }
};
EOF
    filename = "index.js"
  }
}
