# Load Balancer Module for Disaster Recovery

# Application Load Balancer
resource "aws_lb" "this" {
  name               = "dr-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = merge(
    {
      Name        = "dr-alb-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# Target Group for the Load Balancer
resource "aws_lb_target_group" "this" {
  name     = "dr-tg-${var.environment}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = merge(
    {
      Name        = "dr-tg-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# Listener for the Load Balancer
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = merge(
    {
      Name        = "dr-listener-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}
