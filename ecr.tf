resource "aws_ecr_repository" "service1" {
 name = "service1"
 force_delete = true
}

resource "aws_ecr_repository" "service2" {
 name = "service2"
 force_delete = true
}