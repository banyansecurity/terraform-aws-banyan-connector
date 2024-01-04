## If multiple subnets are provided in a single AZ, the LB will fail to create
## Find one subnet from each AZ and use those instead
data "aws_subnet" "selected" {
  count = length(var.asg_subnet_ids)
  id    = var.asg_subnet_ids[count.index]
}

locals {
  # Group subnet IDs by their availability zones
  subnet_groups = { for s in data.aws_subnet.selected : s.availability_zone => s.id... }

  # Select one subnet ID per availability zone
  one_subnet_per_az = [for az, subnets in local.subnet_groups : subnets[0]]
}
