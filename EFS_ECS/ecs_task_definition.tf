#----------------------------------------
# EFS Task Definition
#----------------------------------------
resource "aws_ecs_task_definition" "ecs_task" {
  family                    = "my-java-app"
  requires_compatibilities  = ["FARGATE"]
  network_mode              = "awsvpc"
  
  cpu                       = "1024"
  memory                    = "2048"
  task_role_arn             = "arn:aws:iam::${var.account_id}:role/cl/app/ecs-my-java-app-common-role"
  execution_role_arn        = "arn:aws:iam::${var.account_id}:role/cl/app/ecs-my-java-app-common-role"

  container_definitions = <<SERVICECONFIG
    [
      {
        "name": "my-java-app",
        "image": "${var.ecr_repo}:${var.app_version}",
        "essential": true,
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
            "awslogs-group": "/ecs/my-java-app",
            "awslogs-region": "us-west-1",
            "awslogs-stream-prefix": "ecs"
          }
        },
        "mountPoints": [
          {
            "sourceVolume": "efs_temp",
            "containerPath": "/efs",
            "readOnly": false
          }
        ],
        "secrets": [
          {
            "name": "RDS_HOST",
            "valueFrom": "arn:aws:ssm:us-west-2:${var.account_id}:parameter/common/rds/dev/endpoint"
          },
          {
            "name": "RDS_USER",
            "valueFrom": "arn:aws:ssm:us-west-2:${var.account_id}:parameter/common/rds/dev/app_username"
          },
          {
            "name": "RDS_PASS",
            "valueFrom": "arn:aws:ssm:us-west-2:${var.account_id}:parameter/common/rds/dev/app_password"
          }
         
        ],
        "environment": [
          {
            "name": "EFS_ROOT",
            "value": "/efs"
          },
          {
            "name": "JAVA_OPTS",
            "value": "-Xms${var.job_java_ms} -Xmx${var.job_java_mx} -Dfile.encoding=UTF-8 ${var.java_proxy_args}"
          }         
        ]
      }
    ]
SERVICECONFIG

  volume {
      name = "efs_temp"
      efs_volume_configuration {
        file_system_id = "${aws_efs_file_system.efs_volume.id}"
        root_directory = "/"
      }
  }
}
