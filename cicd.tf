# --- CodeBuild Projects (Parallel) ---
resource "aws_codebuild_project" "build_service1" {
  name          = "build-service1"
  service_role  = aws_iam_role.codebuild_role.arn
  artifacts     { type = "CODEPIPELINE" }
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true # Required to build Docker images
  }
  
  source { 
    type      = "CODEPIPELINE" 
    buildspec = "service/buildspec_service1.yml"
    }
}

resource "aws_codebuild_project" "build_service2" {
  name          = "build-service2"
  service_role  = aws_iam_role.codebuild_role.arn
  artifacts     { type = "CODEPIPELINE" }
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = "service/buildspec_service2.yml"
  }
}

# --- CodePipeline ---
resource "aws_codepipeline" "main_pipeline" {
  name     = "microservices-pipeline"
  role_arn = aws_iam_role.pipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        Owner                = var.github_owner
        Repo                 = var.github_repo
        Branch               = "main"
        OAuthToken           = var.github_token
        PollForSourceChanges = "true"
      }
    }
  }

  stage {
    name = "Build"
    # Action 1: Service 1
    action {
      name             = "BuildService1"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output_s1"]
      version          = "1"
      run_order        = 1 # Same run order = Parallel
      configuration    = { ProjectName = aws_codebuild_project.build_service1.name }
    }
    # Action 2: Service 2
    action {
      name             = "BuildService2"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output_s2"]
      version          = "1"
      run_order        = 1 # Same run order = Parallel
      configuration    = { ProjectName = aws_codebuild_project.build_service2.name }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "DeployService1"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["build_output_s1"]
      version         = "1"

      configuration = {
        ApplicationName                = aws_codedeploy_app.ecs_app.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.service1_dg.deployment_group_name
        TaskDefinitionTemplateArtifact = "build_output_s1"
        AppSpecTemplateArtifact        = "build_output_s1"
        TaskDefinitionTemplatePath     = "taskdef.json" # CodeBuild must generate this
        AppSpecTemplatePath            = "appspec.yaml"
      }
    }
    action {
      name            = "DeployService2"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["build_output_s2"]
      version         = "1"

      configuration = {
        ApplicationName                = aws_codedeploy_app.ecs_app.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.service2_dg.deployment_group_name
        TaskDefinitionTemplateArtifact = "build_output_s2"
        AppSpecTemplateArtifact        = "build_output_s2"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplatePath            = "appspec.yaml"
      }
    }
  }

}

# --- CodeDeploy for Blue/Green ---
resource "aws_codedeploy_app" "ecs_app" {
  compute_platform = "ECS"
  name             = "microservices-app"
}

resource "aws_codedeploy_deployment_group" "service1_dg" {
  app_name              = aws_codedeploy_app.ecs_app.name
  deployment_group_name = "service1-deployment-group"
  service_role_arn      = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }
  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.service1_listener.arn]
      }
      target_group {
        name = aws_lb_target_group.service1_tg_blue.name
      }
      target_group {
        name = aws_lb_target_group.service1_tg_green.name
      }
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.cluster.name
    service_name = aws_ecs_service.service1.name
  }
}

resource "aws_codedeploy_deployment_group" "service2_dg" {
  app_name              = aws_codedeploy_app.ecs_app.name
  deployment_group_name = "service2-deployment-group"
  service_role_arn      = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }
  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.service2_listener.arn]
      }
      target_group {
        name = aws_lb_target_group.service2_tg_blue.name
      }
      target_group {
        name = aws_lb_target_group.service2_tg_green.name
      }
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.cluster.name
    service_name = aws_ecs_service.service2.name
  }
}