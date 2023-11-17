resource "aws_ecs_cluster" "cluster" {
  name = "DevCluster"

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.namespace.arn
  }
}

resource "aws_service_discovery_http_namespace" "namespace" {
  name        = "MCServerNamespace"
  description = "This is useless to us but AWS thinks we need it so lucky us I guess..."
}

resource "aws_ecs_cluster_capacity_providers" "cluster_providers" {
  cluster_name = aws_ecs_cluster.cluster.name

  capacity_providers = [aws_ecs_capacity_provider.provider.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.provider.name
    base              = 0
    weight            = 1
  }
}

resource "aws_ecs_capacity_provider" "provider" {
  name = "Infra-ECS-Cluster-DevCluster-c2d37982-EC2CapacityProvider-8yk8uDYKIVhX"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.scaling_group.arn
  }
}

resource "aws_autoscaling_policy" "policy" {
  name                   = "ECSManagedAutoScalingPolicy-8c5e24c3-2b21-4d3c-96c2-d927439a8389"
  autoscaling_group_name = aws_autoscaling_group.scaling_group.name

  estimated_instance_warmup = 300
  policy_type               = "TargetTrackingScaling"

  target_tracking_configuration {
    target_value = 100

    customized_metric_specification {
      metric_name = "CapacityProviderReservation"
      namespace   = "AWS/ECS/ManagedScaling"
      statistic   = "Average"

      metric_dimension {
        name  = "CapacityProviderName"
        value = aws_ecs_capacity_provider.provider.name
      }

      metric_dimension {
        name  = "ClusterName"
        value = aws_ecs_cluster.cluster.name
      }
    }
  }
}

resource "aws_autoscaling_group" "scaling_group" {
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 0
  vpc_zone_identifier       = [aws_subnet.akl_local.id]
  health_check_grace_period = 0

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    propagate_at_launch = true
    value               = ""
  }

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "ECS Instance - ${aws_ecs_cluster.cluster.name}"
  }
}

resource "aws_autoscaling_notification" "server_notification" {
  group_names = [aws_autoscaling_group.scaling_group.name]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.server_events_topic.arn
}

resource "aws_autoscaling_notification" "scaling_notification" {
  group_names = [aws_autoscaling_group.scaling_group.name]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.scaling_events_topic.arn
}

data "aws_ssm_parameter" "latest_ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "InstanceProfileECS"
  role = aws_iam_role.instance_role.name
}

resource "aws_iam_role" "instance_role" {
  name               = "InstanceRoleECS"
  assume_role_policy = data.aws_iam_policy_document.ec2_instance_role_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_container" {
  role       = aws_iam_role.instance_role.name
  policy_arn = data.aws_iam_policy.ec2_container_service.arn
}

resource "aws_iam_role_policy_attachment" "ecs_ssm" {
  role       = aws_iam_role.instance_role.name
  policy_arn = data.aws_iam_policy.ec2_ssm.arn
}

resource "aws_launch_template" "template" {
  instance_type          = "t3.medium"
  image_id               = nonsensitive(data.aws_ssm_parameter.latest_ecs_ami.value)
  vpc_security_group_ids = [aws_security_group.security_group.id]
  update_default_version = true

  user_data = base64encode("#!/bin/bash \necho ECS_CLUSTER=${aws_ecs_cluster.cluster.name} >> /etc/ecs/ecs.config;")

  iam_instance_profile {
    arn = aws_iam_instance_profile.instance_profile.arn
  }
}

resource "aws_security_group" "security_group" {
  name = "mcaccess"
}

resource "aws_vpc_security_group_ingress_rule" "mc_tcp" {
  security_group_id = aws_security_group.security_group.id
  to_port           = "25565"
  from_port         = "25565"
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "mc_udp" {
  security_group_id = aws_security_group.security_group.id
  to_port           = "25565"
  from_port         = "25565"
  ip_protocol       = "udp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "mcrcon" {
  security_group_id = aws_security_group.security_group.id
  to_port           = "25575"
  from_port         = "25575"
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "out" {
  security_group_id = aws_security_group.security_group.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
