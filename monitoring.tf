# High CPU Alarm Service 1
resource "aws_cloudwatch_metric_alarm" "high_cpu_service1" {
  alarm_name          = "service1-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.service1.name
  }

  # This connects the alarm to the Scaling Policy AND the SNS Topic
  alarm_actions = [
    aws_appautoscaling_policy.scale_out_service1.arn,
    aws_sns_topic.alerts.arn
  ]
}

# Low CPU Alarm Service 1
resource "aws_cloudwatch_metric_alarm" "low_cpu_service1" {
  alarm_name          = "service1-low-cpu" # Fixed your duplicate name error here
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "20"

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.service1.name
  }

  alarm_actions = [
    aws_appautoscaling_policy.scale_in_service1.arn,
    aws_sns_topic.alerts.arn
  ]
}

# High CPU Alarm Service 2
resource "aws_cloudwatch_metric_alarm" "high_cpu_service2" {
  alarm_name          = "service2-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.service2.name
  }

  alarm_actions = [
    aws_appautoscaling_policy.scale_out_service2.arn,
    aws_sns_topic.alerts.arn
  ]
}   

# Low CPU Alarm Service 2
resource "aws_cloudwatch_metric_alarm" "low_cpu_service2" {
  alarm_name          = "service2-low-cpu" # Fixed your duplicate name error here
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "20"

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.service2.name
  }

  alarm_actions = [
    aws_appautoscaling_policy.scale_in_service2.arn,
    aws_sns_topic.alerts.arn
  ]
}

