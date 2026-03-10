# --- Target for Service 1 ---
resource "aws_appautoscaling_target" "target_service1" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.service1.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# --- Target for Service 2 ---
resource "aws_appautoscaling_target" "target_service2" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.service2.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scale_out_service1" {
  name               = "scale-out-service1"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.target_service1.resource_id
  scalable_dimension = aws_appautoscaling_target.target_service1.scalable_dimension
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type          = "ChangeInCapacity"
    cooldown                 = 60   # Wait 60s before firing again
    metric_aggregation_type  = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "scale_in_service1" {
  name               = "scale-in-service1"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.target_service1.resource_id
  scalable_dimension = aws_appautoscaling_target.target_service1.scalable_dimension
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type          = "ChangeInCapacity"
    cooldown                 = 120  # Wait 120s before scaling in again
    metric_aggregation_type  = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_appautoscaling_policy" "scale_out_service2" {
  name               = "scale-out-service2"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.target_service2.resource_id
  scalable_dimension = aws_appautoscaling_target.target_service2.scalable_dimension
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type          = "ChangeInCapacity"
    cooldown                 = 60
    metric_aggregation_type  = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "scale_in_service2" {
  name               = "scale-in-service2"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.target_service2.resource_id
  scalable_dimension = aws_appautoscaling_target.target_service2.scalable_dimension
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type          = "ChangeInCapacity"
    cooldown                 = 120
    metric_aggregation_type  = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}
