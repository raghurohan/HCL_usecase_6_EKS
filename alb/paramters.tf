resource "aws_ssm_parameter" "web_alb_listener_http" {
  name  = "/${var.project}/${var.environment}/web_alb_listener_http"
  type  = "String"
  value = aws_lb_listener.web_http.arn
}

#resource "aws_ssm_parameter" "web_alb_listener_https" {
#  name  = "/${var.project}/${var.environment}/web_alb_listener_https"
#  type  = "String"
#  value = aws_lb_listener.web_https.arn
#}

resource "aws-ssm_parameter" "alb_target_group_arn" {
  name = "/${var.project}/${var.environment}/alb-target-group-arn"
  type = "String"
  value = aws_lb_target_group.frontend.arn
}