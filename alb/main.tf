module "web_alb" {
  source  = "terraform-aws-modules/alb/aws"

  name = "web-alb"
  internal = false
  vpc_id             = local.vpc_id
  subnets            = local.public_subnet_id
  security_groups    = [ local.web_alb_sg_id ]

 create_security_group = false
  enable_deletion_protection = false

}

############################### NOTE ###############################

resource "aws_lb_listener" "web_http" {
  load_balancer_arn = module.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
     type = "forward"
     target_group_arn = aws_lb_target_group.frontend.arn
  }
}


resource "aws_lb_target_group" "frontend" {
  name     = "frontend"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = local.vpc_id
  target_type = "ip" #Most important line which is often missed;; 
  
  health_check {
    healthy_threshold = 4
   unhealthy_threshold = 4
    matcher = "200-299"
    interval = 10 
    protocol = "HTTP" 
    #                   but default value is target group port 
    path     = "/"
    timeout = 5 #waiting time before deciding unhealthy
  }
}





