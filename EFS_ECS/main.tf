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


#----------------------------------------
# EFS
#----------------------------------------
resource "aws_efs_file_system" "efs_volume" {
  performance_mode = "generalPurpose"

  creation_token = "common-efs-volume"
  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }
 
}

resource "aws_efs_mount_target" "ecs_temp_space_az0" {
  file_system_id = "${aws_efs_file_system.efs_volume.id}"
  subnet_id      = "${element(split(",","${var.private_subnets}"), 0)}"
  security_groups = ["${aws_security_group.ecs_container_security_group.id}"]
}

resource "aws_efs_mount_target" "ecs_temp_space_az1" {
  file_system_id = "${aws_efs_file_system.efs_volume.id}"
  subnet_id      = "${element(split(",","${var.private_subnets}"), 1)}"
  security_groups = ["${aws_security_group.ecs_container_security_group.id}"]
}

resource "aws_efs_mount_target" "ecs_temp_space_az2" {
  file_system_id = "${aws_efs_file_system.efs_volume.id}"
  subnet_id      = "${element(split(",","${var.private_subnets}"), 2)}"
  security_groups = ["${aws_security_group.ecs_container_security_group.id}"]
}


#----------------------------------------
# ECS security-group
#----------------------------------------
resource "aws_security_group" "ecs_container_security_group" {

  name        = "ecs-common-sg"
  description = "Outbound Traffic Only"
  vpc_id      = "${data.aws_vpc.vpc.id}"

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

}