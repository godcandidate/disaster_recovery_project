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
          "autoscaling:SetDesiredCapacity",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth"
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

# IAM Policy for Lambda SNS
resource "aws_iam_policy" "lambda_sns_policy" {
  name        = "dr-lambda-sns-policy-${var.environment}"
  description = "Policy for Lambda to send SNS notifications"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sns:Publish"
        ]
        Effect   = "Allow"
        Resource = "*"
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

resource "aws_iam_role_policy_attachment" "lambda_sns_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_sns_policy.arn
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
      SNS_TOPIC_ARN           = var.sns_topic_arn == null ? "" : var.sns_topic_arn
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
    const elbv2 = new AWS.ELBv2();
    const sns = new AWS.SNS();
    
    // Get environment variables
    const asgName = process.env.AUTO_SCALING_GROUP_NAME;
    const targetGroupArn = process.env.TARGET_GROUP_ARN;
    const desiredCapacity = process.env.DESIRED_CAPACITY;
    const snsTopicArn = process.env.SNS_TOPIC_ARN;
    
    console.log('Updating Auto Scaling Group ' + asgName + ' to desired capacity ' + desiredCapacity);
    
    try {
        // Update the Auto Scaling Group
        const asgResult = await autoscaling.updateAutoScalingGroup({
            AutoScalingGroupName: asgName,
            DesiredCapacity: parseInt(desiredCapacity),
            MinSize: parseInt(desiredCapacity)
        }).promise();
        
        console.log('Auto Scaling Group updated successfully');
        
        // Wait for instances to be in service
        console.log('Waiting for instances to be in service...');
        let instancesInService = false;
        let retries = 0;
        const maxRetries = 30; // 5 minutes (10 seconds * 30)
        
        while (!instancesInService && retries < maxRetries) {
            // Get the ASG details to find instance IDs
            const asgDetails = await autoscaling.describeAutoScalingGroups({
                AutoScalingGroupNames: [asgName]
            }).promise();
            
            if (asgDetails.AutoScalingGroups.length > 0) {
                const group = asgDetails.AutoScalingGroups[0];
                const instances = group.Instances;
                
                if (instances.length > 0) {
                    const runningInstances = instances.filter(i => i.LifecycleState === 'InService');
                    
                    if (runningInstances.length === parseInt(desiredCapacity)) {
                        instancesInService = true;
                        console.log('All instances are now in service');
                        
                        // Register instances with the target group if not already registered
                        if (targetGroupArn) {
                            // Check if instances are already registered with the target group
                            const targetHealthResult = await elbv2.describeTargetHealth({
                                TargetGroupArn: targetGroupArn
                            }).promise();
                            
                            const registeredInstanceIds = targetHealthResult.TargetHealthDescriptions.map(thd => thd.Target.Id);
                            const instancesToRegister = runningInstances
                                .filter(instance => !registeredInstanceIds.includes(instance.InstanceId))
                                .map(instance => ({
                                    Id: instance.InstanceId,
                                    Port: 80 // Assuming your application runs on port 80
                                }));
                            
                            if (instancesToRegister.length > 0) {
                                console.log('Registering instances with target group:', instancesToRegister.map(i => i.Id).join(', '));
                                await elbv2.registerTargets({
                                    TargetGroupArn: targetGroupArn,
                                    Targets: instancesToRegister
                                }).promise();
                                console.log('Instances registered with target group successfully');
                            } else {
                                console.log('All instances are already registered with the target group');
                            }
                        }
                    }
                }
            }
            
            if (!instancesInService) {
                retries++;
                await new Promise(resolve => setTimeout(resolve, 10000)); // Wait 10 seconds before checking again
            }
        }
        
        if (!instancesInService) {
            console.warn('Timed out waiting for instances to be in service');
        }
        
        // Send success notification
        if (snsTopicArn) {
            await sns.publish({
                TopicArn: snsTopicArn,
                Subject: 'DR Failover Success',
                Message: 'Disaster Recovery failover completed successfully!\n\nAuto Scaling Group ' + asgName + ' has been scaled to ' + desiredCapacity + ' instance(s).\n\nTime: ' + new Date().toISOString() + '\n\nThis is an automated message from your DR infrastructure.'
            }).promise();
            console.log('Success notification sent');
        }
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'DR failover initiated successfully',
                asgName: asgName,
                desiredCapacity: desiredCapacity
            })
        };
    } catch (error) {
        console.error('Error during DR failover:', error);
        
        // Send failure notification
        if (snsTopicArn) {
            try {
                await sns.publish({
                    TopicArn: snsTopicArn,
                    Subject: 'DR Failover Failed',
                    Message: 'Disaster Recovery failover failed!\n\nError: ' + error.message + '\n\nTime: ' + new Date().toISOString() + '\n\nPlease check the CloudWatch logs for more details.\n\nThis is an automated message from your DR infrastructure.'
                }).promise();
                console.log('Failure notification sent');
            } catch (snsError) {
                console.error('Error sending SNS notification:', snsError);
            }
        }
        
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
  
  source {
    content  = <<EOF
AUTO_SCALING_GROUP_NAME=${var.asg_name}
DESIRED_CAPACITY=1
SNS_TOPIC_ARN=${var.sns_topic_arn == null ? "" : var.sns_topic_arn}
TARGET_GROUP_ARN=${var.target_group_arn == null ? "" : var.target_group_arn}
EOF
    filename = ".env"
  }
  
}
