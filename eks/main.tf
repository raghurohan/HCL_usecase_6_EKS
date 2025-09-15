##############################################
# To upgrade the eks cluster without downtime, below are the steps
# 1. create a green node group 
# 2.cordon the green node group
# 3. upgarde the cluster from console to the latest version
# 4. upgrade the green node group to the latest version 
# 5. uncordon the green node group
# 6. cordon the blue node group
# 7. drain the blue node group
# 8. once all the pods moves to green , delete the blue node group


# resource "aws_key_pair" "eks" {
#   key_name   = data.aws_key_pair.project.key_name  #just using some key which i created earlier 
# }

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">=18.0.0"


  name    = "${var.project_name}-${var.environment}"
  kubernetes_version = "1.31" #while upgrading the nodegroup and cluster , make sure to upgrade this version

  endpoint_public_access  = true #if false we need vpn to access eks cluster 

  addons = {
    coredns                = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy             = {}
    vpc-cni                = {
      before_compute = true
    }
  }


  vpc_id                   = data.aws_ssm_parameter.vpc_id.value
  subnet_ids               = local.private_subnet_ids

  create_security_group = false
  additional_security_group_ids     = [local.eks_control_plane_sg_id]

  create_node_security_group = false
  node_security_group_id     = local.node_sg_id

  # the user which you used to create cluster will get admin access
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true



  eks_managed_node_groups = {
    blue = {
      instance_types = ["t3.medium"] #by default eks takes ami as amazon linux 
      min_size      = 2
      max_size      = 10
      desired_size  = 2
      capacity_type = "SPOT"
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy          = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonElasticFileSystemFullAccess = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
        ElasticLoadBalancingFullAccess = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
      }
      # EKS takes AWS Linux 2 as it's OS to the nodes
      key_name = data.aws_key_pair.project.key_name
    }
    # green = {
    #   min_size      = 2
    #   max_size      = 10
    #   desired_size  = 2
    #   #capacity_type = "SPOT"
    #   iam_role_additional_policies = {
    #     AmazonEBSCSIDriverPolicy          = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    #     AmazonElasticFileSystemFullAccess = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
    #     ElasticLoadBalancingFullAccess = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
    #   }
      # EKS takes AWS Linux 2 as it's OS to the nodes
      # key_name = aws_key_pair.eks.key_name
    }
  #}
}

resource "null_resource" "update_kube_config" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = <<EOT
      aws eks --region us-east-1 update-kubeconfig --name ${module.eks.cluster_name} --kubeconfig ./generated_kubeconfig
      echo "Kubeconfig generated and saved to ./generated_kubeconfig"
      export ALB_TARGET_GROUP_ARN=$(aws ssm get-parameter --name "/expense/dev/alb-target-group-arn" --query "Parameter.Value" --output text)
      envsubst < api.yaml.tpl > api.yaml
      kubectl apply -f api.yaml
    EOT
  }
}

#env subst --- this will substitute the env variable to the api.yaml file