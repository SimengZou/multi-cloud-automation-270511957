# --- ALB Security Group ---
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
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

  # Outbound is defined separately below to avoid cycle
}

# --- ECS Tasks Security Group ---
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-tasks-sg"
  description = "Allow traffic from ALB to ECS tasks"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow all outbound (ECR pull, CloudWatch, etc.)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # No ingress rule here — defined separately below to avoid cycle
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
