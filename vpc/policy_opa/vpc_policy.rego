package terraform.vpc

# 1️⃣ VPC must have a CIDR block
deny[msg] {
  some i
  vpc := input.planned_resources[i]
  vpc.type == "aws_vpc"
  not vpc.attributes.cidr_block
  msg := "VPC must have a CIDR block defined"
}

# 2️⃣ VPC must have tags (project + environment)
deny[msg] {
  some i
  vpc := input.planned_resources[i]
  vpc.type == "aws_vpc"
  not vpc.attributes.tags.project
  msg := "VPC must have a 'project' tag"
}

deny[msg] {
  some i
  vpc := input.planned_resources[i]
  vpc.type == "aws_vpc"
  not vpc.attributes.tags.environment
  msg := "VPC must have an 'environment' tag"
}

# 3️⃣ Public subnets should not be wide open
deny[msg] {
  some i
  subnet := input.planned_resources[i]
  subnet.type == "aws_subnet"
  subnet.attributes.map_public_ip_on_launch == true
  msg := sprintf("Subnet %v is public, not allowed", [subnet.name])
}

# 4️⃣ Private subnets must have CIDR block
deny[msg] {
  some i
  subnet := input.planned_resources[i]
  subnet.type == "aws_subnet"
  subnet.attributes.map_public_ip_on_launch == false
  not subnet.attributes.cidr_block
  msg := sprintf("Private subnet %v must have a CIDR block", [subnet.name])
}

# 5️⃣ If peering is required, it must exist
deny[msg] {
  some i
  peering := input.planned_resources[i]
  peering.type == "aws_vpc_peering_connection"
  peering.attributes.status != "active"
  msg := "VPC peering connection is required but not active"
}
