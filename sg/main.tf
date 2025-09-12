# security groups required for the project

module "eks_control_plane_sg" {
  source       = "git::https://github.com/raghuatharva/terraform-aws-security-group.git?ref=main"
  vpc_id       = local.vpc_id
  sg_name      = "control plane "
  project_name = var.project
  environment  = var.environment

}

module "node_sg" {
  source       = "git::https://github.com/raghuatharva/terraform-aws-security-group.git?ref=main"
  vpc_id       = local.vpc_id
  sg_name      = "node group"
  project_name = var.project
  environment  = var.environment

}

module "web_alb_sg" {
  source       = "git::https://github.com/raghuatharva/terraform-aws-security-group.git?ref=main"
  vpc_id       = local.vpc_id
  sg_name      = "web-alb"
  project_name = var.project
  environment  = var.environment

}

#------> most important rules for traffic flow for user to access the application <------#


resource "aws_security_group_rule" "web_alb_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.web_alb_sg.id
}

resource "aws_security_group_rule" "web_alb_to_node" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  source_security_group_id = module.web_alb_sg.id
  security_group_id = module.node_sg.id
}

resource "aws_security_group_rule" "control_plane_to_node" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  source_security_group_id = module.eks_control_plane_sg.id
  security_group_id = module.node_sg.id
}

resource "aws_security_group_rule" "node_to_eks_control_plane" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  source_security_group_id = module.node_sg.id
  security_group_id = module.eks_control_plane_sg.id
}



# for nodes to communicate with each other , allow node group sg inside node group sg
resource "aws_security_group_rule" "node_vpc" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  source_security_group_id = module.node_sg.id
  security_group_id = module.node_sg.id
}




# -------------------------------------





