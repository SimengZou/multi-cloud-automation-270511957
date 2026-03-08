resource "aws_security_group" "alb_sg" {
 vpc_id = aws_vpc.main.id

 ingress {
   from_port = 80
   to_port = 80
   protocol = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
 }

 ingress {
   from_port = 443
   to_port = 443
   protocol = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
 }

 egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-tasks-sg"
  description = "Nested security for ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3000 
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Nested SG rule
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound (needed for logs/ECR)
    cidr_blocks = ["0.0.0.0/0"]
  }
}