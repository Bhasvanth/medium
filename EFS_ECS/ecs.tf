#----------------------------------------
# ECS Service
#----------------------------------------
resource "aws_ecs_service" "ecs_module_service" {
  name            = "ecs_service"
  cluster         = "java-app-cluster"
  task_definition = "${aws_ecs_task_definition.ecs_task.arn}"
  desired_count   = "${var.ecs_desired_count}"

  platform_version   = "1.4.0"

}

#----------------------------------------
# ECS Cluster
#----------------------------------------
resource "aws_ecs_cluster" "product-cluster" {
  name = "java-app-cluster"
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 100
  }

}

