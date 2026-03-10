# --- ALB Security Group ---
resource "aws_security_group" "alb_sg" {
  # name_prefix instead of name: lets Terraform create the new SG first
  # with a unique name, attach it, then safely delete the old one.
  # This is required when using create_before_destroy.
  name_prefix = "alb-sg-"
  description = "Allow HTTP inbound to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP production traffic from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP test traffic for Blue/Green validation"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress defined as standalone rules below to avoid cycle with ecs_sg
  lifecycle {
    create_before_destroy = true
  }
}

# --- ECS Tasks Security Group ---
resource "aws_security_group" "ecs_sg" {
  name_prefix = "ecs-tasks-sg-"
  description = "Allow traffic from ALB to ECS tasks"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow all outbound (ECR pull, CloudWatch, etc.)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress defined as standalone rules below to avoid cycle with alb_sg
  lifecycle {
    create_before_destroy = true
  }
}

# --- Cross-references as standalone rules (breaks the cycle) ---

# ALB --> ECS: egress from ALB to ECS on port 3000
resource "aws_security_group_rule" "alb_to_ecs_egress" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb_sg.id
  source_security_group_id = aws_security_group.ecs_sg.id
  description              = "Forward traffic to ECS tasks on port 3000"
}

# ECS: ingress from ALB on port 3000
resource "aws_security_group_rule" "ecs_from_alb_ingress" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
  description              = "App traffic from ALB only"
}
