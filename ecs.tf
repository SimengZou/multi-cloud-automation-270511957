# --- ECS Cluster ---
resource "aws_ecs_cluster" "cluster" {
  name = "microservices-cluster"
}

# --- Service 1: Task Definition ---
resource "aws_ecs_task_definition" "service1" {
  family                   = "service1"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_exec_role.arn # Defined in iam.tf

  container_definitions = jsonencode([
    {
      name      = "service1"
      image     = "${aws_ecr_repository.service1.repository_url}:latest"
      portMappings = [{
        containerPort = 3000
        hostPort      = 3000
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = "ap-southeast-2"
          "awslogs-stream-prefix" = "service1"
        }
      }
    }
  ])
}

# --- Service 1: Application Load Balancer ---
resource "aws_lb" "service1_alb" {
  name               = "service1-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]
  security_groups    = [aws_security_group.alb_sg.id]
}

# --- Blue Target Group (Existing) ---
resource "aws_lb_target_group" "service1_tg_blue" {
  name        = "service1-tg-blue"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
}

# --- Green Target Group (New - for deployment) ---
resource "aws_lb_target_group" "service1_tg_green" {
  name        = "service1-tg-green"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
}

# --- ALB Listener ---
# The listener initially points to the Blue Target Group
resource "aws_lb_listener" "service1_listener" {
  load_balancer_arn = aws_lb.service1_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service1_tg_blue.arn
  }
}

# --- Service 1: ECS Service ---
resource "aws_ecs_service" "service1" {
  name            = "service1"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.service1.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  deployment_controller {
    type = "CODE_DEPLOY"
  }
  
  # IMPORTANT: When using CODE_DEPLOY, you should ignore changes to 
  # task_definition and load_balancer in Terraform, otherwise Terraform 
  # will try to "undo" the Blue/Green shift every time you run apply.
  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }
  network_configuration {
    subnets         = [aws_subnet.private1.id, aws_subnet.private2.id]
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.service1_tg_blue.arn # Added _blue
    container_name   = "service1"
    container_port   = 3000
  }

  depends_on = [aws_ecs_cluster.cluster, aws_lb_listener.service1_listener]
}

# --- Service 2: Task Definition ---
resource "aws_ecs_task_definition" "service2" {
  family                   = "service2"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_exec_role.arn

  container_definitions = jsonencode([
    {
      name      = "service2"
      image     = "${aws_ecr_repository.service2.repository_url}:latest"
      portMappings = [{
        containerPort = 3000
        hostPort      = 3000
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = "ap-southeast-2"
          "awslogs-stream-prefix" = "service2"
        }
      }
    }
  ])
}

# --- Service 2: Application Load Balancer ---
resource "aws_lb" "service2_alb" {
  name               = "service2-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]
  security_groups    = [aws_security_group.alb_sg.id]
}

# --- Blue Target Group (Existing) ---
resource "aws_lb_target_group" "service2_tg_blue" {
  name        = "service2-tg-blue"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
}

# --- Green Target Group (New - for deployment) ---
resource "aws_lb_target_group" "service2_tg_green" {
  name        = "service2-tg-green"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
}

# --- ALB Listener ---
# The listener initially points to the Blue Target Group
resource "aws_lb_listener" "service2_listener" {
  load_balancer_arn = aws_lb.service2_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service2_tg_blue.arn
  }
}

# --- Service 2: ECS Service ---
resource "aws_ecs_service" "service2" {
  name            = "service2"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.service2.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.private1.id, aws_subnet.private2.id]
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.service2_tg_blue.arn # Added _blue
    container_name   = "service2"
    container_port   = 3000
  }
  deployment_controller {
    type = "CODE_DEPLOY"
  }

  # IMPORTANT: When using CODE_DEPLOY, you should ignore changes to 
  # task_definition and load_balancer in Terraform, otherwise Terraform 
  # will try to "undo" the Blue/Green shift every time you run apply.
  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }
  depends_on = [aws_ecs_cluster.cluster, aws_lb_listener.service2_listener]
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/microservices"
  retention_in_days = 7
}

