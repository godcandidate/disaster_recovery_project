# Step Function Module for Disaster Recovery Failover

# IAM Role for Step Function
resource "aws_iam_role" "step_function" {
  name = "dr-step-function-role-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(
    {
      Name        = "dr-step-function-role-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# IAM Policy for Step Function to promote RDS Read Replica
resource "aws_iam_policy" "step_function_rds" {
  name        = "dr-step-function-rds-policy-${var.environment}"
  description = "Policy for Step Function to promote RDS Read Replica"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:PromoteReadReplica",
          "rds:ModifyDBInstance",
          "rds:DescribeDBInstances"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:rds:${var.region}:${data.aws_caller_identity.current.account_id}:db:*"
      }
    ]
  })
}

# IAM Policy for Step Function to manage EC2 Auto Scaling
resource "aws_iam_policy" "step_function_ec2" {
  name        = "dr-step-function-ec2-policy-${var.environment}"
  description = "Policy for Step Function to manage EC2 Auto Scaling"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:StartInstanceRefresh",
          "ec2:StartInstances",
          "ec2:DescribeInstances"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# IAM Policy for Step Function to publish to SNS
resource "aws_iam_policy" "step_function_sns" {
  name        = "dr-step-function-sns-policy-${var.environment}"
  description = "Policy for Step Function to publish to SNS"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sns:Publish"
        Effect   = "Allow"
        Resource = var.sns_topic_arn
      }
    ]
  })
}

# Attach policies to role
resource "aws_iam_role_policy_attachment" "step_function_rds" {
  role       = aws_iam_role.step_function.name
  policy_arn = aws_iam_policy.step_function_rds.arn
}

resource "aws_iam_role_policy_attachment" "step_function_ec2" {
  role       = aws_iam_role.step_function.name
  policy_arn = aws_iam_policy.step_function_ec2.arn
}

resource "aws_iam_role_policy_attachment" "step_function_sns" {
  role       = aws_iam_role.step_function.name
  policy_arn = aws_iam_policy.step_function_sns.arn
}

# Step Function State Machine
resource "aws_sfn_state_machine" "dr_failover" {
  name     = "dr-failover-state-machine-${var.environment}"
  role_arn = aws_iam_role.step_function.arn
  
  definition = <<EOF
{
  "Comment": "Disaster Recovery Failover Orchestration",
  "StartAt": "PromoteRDSReadReplica",
  "States": {
    "PromoteRDSReadReplica": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:rds:promoteReadReplica",
      "Parameters": {
        "DBInstanceIdentifier": "${var.rds_read_replica_id}"
      },
      "Retry": [
        {
          "ErrorEquals": ["States.ALL"],
          "IntervalSeconds": 5,
          "MaxAttempts": 3,
          "BackoffRate": 2.0
        }
      ],
      "Next": "WaitForRDSPromotion",
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "ResultPath": "$.error",
          "Next": "NotifyFailure"
        }
      ]
    },
    "WaitForRDSPromotion": {
      "Type": "Wait",
      "Seconds": 60,
      "Next": "CheckRDSStatus"
    },
    "CheckRDSStatus": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:rds:describeDBInstances",
      "Parameters": {
        "DBInstanceIdentifier": "${var.rds_read_replica_id}"
      },
      "Next": "EvaluateRDSStatus",
      "Retry": [
        {
          "ErrorEquals": ["States.ALL"],
          "IntervalSeconds": 5,
          "MaxAttempts": 3,
          "BackoffRate": 2.0
        }
      ],
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "ResultPath": "$.error",
          "Next": "NotifyFailure"
        }
      ]
    },
    "EvaluateRDSStatus": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.DBInstances[0].DBInstanceStatus",
          "StringEquals": "available",
          "Next": "ScaleEC2Instances"
        }
      ],
      "Default": "WaitForRDSPromotion"
    },
    "ScaleEC2Instances": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:autoscaling:updateAutoScalingGroup",
      "Parameters": {
        "AutoScalingGroupName": "${var.asg_name}",
        "MinSize": 1,
        "MaxSize": 3,
        "DesiredCapacity": 1
      },
      "Next": "StartInstanceRefresh",
      "Retry": [
        {
          "ErrorEquals": ["States.ALL"],
          "IntervalSeconds": 5,
          "MaxAttempts": 3,
          "BackoffRate": 2.0
        }
      ],
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "ResultPath": "$.error",
          "Next": "NotifyFailure"
        }
      ]
    },
    "StartInstanceRefresh": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:autoscaling:startInstanceRefresh",
      "Parameters": {
        "AutoScalingGroupName": "${var.asg_name}",
        "Preferences": {
          "MinHealthyPercentage": 90,
          "InstanceWarmup": 300
        }
      },
      "Next": "WaitForEC2Instances",
      "Retry": [
        {
          "ErrorEquals": ["States.ALL"],
          "IntervalSeconds": 5,
          "MaxAttempts": 3,
          "BackoffRate": 2.0
        }
      ],
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "ResultPath": "$.error",
          "Next": "NotifyFailure"
        }
      ]
    },
    "WaitForEC2Instances": {
      "Type": "Wait",
      "Seconds": 120,
      "Next": "CheckEC2Status"
    },
    "CheckEC2Status": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:autoscaling:describeAutoScalingGroups",
      "Parameters": {
        "AutoScalingGroupNames": ["${var.asg_name}"]
      },
      "Next": "EvaluateEC2Status",
      "Retry": [
        {
          "ErrorEquals": ["States.ALL"],
          "IntervalSeconds": 5,
          "MaxAttempts": 3,
          "BackoffRate": 2.0
        }
      ],
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "ResultPath": "$.error",
          "Next": "NotifyFailure"
        }
      ]
    },
    "EvaluateEC2Status": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.AutoScalingGroups[0].Instances[0].LifecycleState",
          "StringEquals": "InService",
          "Next": "NotifySuccess"
        }
      ],
      "Default": "WaitForEC2Instances"
    },
    "NotifySuccess": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "TopicArn": "${var.sns_topic_arn}",
        "Message": "Disaster recovery failover completed successfully.",
        "Subject": "DR Failover Success"
      },
      "End": true
    },
    "NotifyFailure": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "TopicArn": "${var.sns_topic_arn}",
        "Message": "Disaster recovery failover failed. Error: $.error",
        "Subject": "DR Failover Failure"
      },
      "End": true
    }
  }
}
EOF
  
  tags = merge(
    {
      Name        = "dr-failover-state-machine-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}
