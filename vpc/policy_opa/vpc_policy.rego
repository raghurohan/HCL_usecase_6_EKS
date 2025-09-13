package terraform.vpc

# --------------------------
# 1️⃣ VPC must have a CIDR block
# --------------------------
deny[msg] {
    some i
    input.planned_resources[i].type == "aws_vpc"
    not input.planned_resources[i].attributes.cidr_block
    msg := "VPC must have a CIDR block defined"
}

# --------------------------
# 2️⃣ VPC must have tags (project + environment)
# --------------------------
deny[msg] {
    some i
    input.planned_resources[i].type == "aws_vpc"
    not input.planned_resources[i].attributes.tags.project
    msg := "VPC must have a 'project' tag"
}

deny[msg] {
    some i
    input.planned_resources[i].type == "aws_vpc"
    not input.planned_resources[i].attributes.tags.environment
    msg := "VPC must have an 'environment' tag"
}

# --------------------------
# 3️⃣ Public subnets should not be wide open
# --------------------------
deny[msg] {
    some i
    input.planned_resources[i].type == "aws_subnet"
    input.planned_resources[i].attributes.map_public_ip_on_launch == true
    msg := sprintf("Subnet %v is public, not allowed", [input.planned_resources[i].name])
}

# --------------------------
# 4️⃣ Private subnets must have CIDR block
# --------------------------
deny[msg] {
    some i
    input.planned_resources[i].type == "aws_subnet"
    input.planned_resources[i].attributes.map_public_ip_on_launch == false
    not input.planned_resources[i].attributes.cidr_block
    msg := sprintf("Private subnet %v must have a CIDR block", [input.planned_resources[i].name])
}

# --------------------------
# 5️⃣ If peering is required, it must exist
# --------------------------
deny[msg] {
    some i
    input.planned_resources[i].type == "aws_vpc_peering_connection"
    input.planned_resources[i].attributes.status != "active"
    msg := "VPC peering connection is required but not active"
}
