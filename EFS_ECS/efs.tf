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