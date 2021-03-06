module "iam_roles" {
    source = "../iam_roles"
    
    app_name                 = "${var.app_name}"
    environment              = "${var.environment}"
}

module "ec2" {
    source = "../ec2"
    
    app_name                = "${var.app_name}"
    environment             = "${var.environment}"
    instance_type           = "${var.instance_type}"
    ecs_aws_ami             = "${var.ecs_aws_ami}"
    security_group_id       = "${module.network.sg_elb_to_app_id}"
    iam_instance_profile    = "${module.iam_roles.ecs_instance_profile_arn}"
    ecs_cluster_name        = "${aws_ecs_cluster.cluster.name}"
    max_size                = "${var.max_size}"
    min_size                = "${var.min_size}"
    desired_capacity        = "${var.desired_capacity}"
    private_subnet_ids      = "${module.network.private_subnet_ids}"
}

module "network" {
    source = "../network"

    app_name                = "${var.app_name}"
    environment             = "${var.environment}"
    vpc_cidr                = "${var.vpc_cidr}"
    public_subnet_cidrs     = "${var.public_subnet_cidrs}"
    private_subnet_cidrs    = "${var.private_subnet_cidrs}"
    availibility_zones      = "${var.availibility_zones}"
}

module "alb" {
    source = "../alb"

    environment             = "${var.environment}"
    app_name                = "${var.app_name}"
    route53_name            = "${var.route53_name}"
    vpc_id                  = "${module.network.vpc_id}"
    security_group_id       = "${module.network.elb_https_http_id}"
    public_subnet_ids       = "${module.network.public_subnet_ids}"
    certificate_arn         = "${var.certificate_arn}"
    deregistration_delay    = "${var.deregistration_delay}"
    health_check_path       = "${var.health_check_path}"
    bucket_log              = "${var.bucket_log}"
}



resource "aws_ecs_cluster" "cluster" {
    name = "${var.app_name}-${var.environment}"
}

resource "aws_ecs_task_definition" "hello" {
    family = "${var.environment}"

    container_definitions = <<DEFINITION
[
  {
    "cpu": 128,
    "environment": [{
      "name": "ENV",
      "value": "${var.environment}"
    }],
    "portMappings": [
        {
          "hostPort": 0,
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
    "essential": true,
    "image": "${var.ecr_image}",
    "memory": 256,
    "name": "${var.environment}"
  }
]
DEFINITION
}

resource "aws_ecs_service" "service" {
    name          = "${var.environment}"
    cluster       = "${aws_ecs_cluster.cluster.id}"
    desired_count = 2
    iam_role      = "${module.iam_roles.ecs_service_role_arn}"

  load_balancer {
        target_group_arn  = "${aws_alb_target_group.target_group.arn}"
        container_name    = "${var.environment}"
        container_port    = 8080
  }

    task_definition = "${aws_ecs_task_definition.hello.family}:${aws_ecs_task_definition.hello.revision}"

    lifecycle {
        ignore_changes = ["task_definition"]
    }
}

resource "aws_alb_target_group" "target_group" {
    name     = "tg-${var.app_name}-${var.environment}"
    port     = 8080
    protocol = "HTTP"
    vpc_id   = "${module.network.vpc_id}"
    deregistration_delay = "${var.deregistration_delay}"

    health_check {
        path     = "${var.health_check_path}"
        protocol = "HTTP"
    }

    tags {
        ELB      = "${module.alb.alb_name}"
    }
}

resource "aws_alb_listener_rule" "host_based_routing" {
    listener_arn = "${module.alb.alb_listener_arn}"
        priority     = 99
    
        action {
            type             = "forward"
            target_group_arn = "${aws_alb_target_group.target_group.arn}"
        }
    
        condition {
            field  = "host-header"
            values = ["${var.environment}.mvlbarcelos.com"]
        }
}