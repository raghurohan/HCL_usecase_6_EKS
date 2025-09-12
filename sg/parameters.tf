
resource "aws_ssm_parameter" "web_alb_sg_id" {
  # /expense/dev/mysql_sg_id
  name  = "/${var.project}/${var.environment}/web_alb_sg_id"
  type  = "String"
  value = module.web_alb_sg.id
  overwrite = true
}

resource "aws_ssm_parameter" "eks_control_plane_sg_id" {
  # /expense/dev/mysql_sg_id
  name  = "/${var.project}/${var.environment}/eks_control_plane_sg_id"
  type  = "String"
  value = module.eks_control_plane_sg.id
  overwrite = true
}


resource "aws_ssm_parameter" "node_sg_id" {
  # /expense/dev/mysql_sg_id
  name  = "/${var.project}/${var.environment}/node_sg_id"
  type  = "String"
  value = module.node_sg.id
  overwrite = true
}








