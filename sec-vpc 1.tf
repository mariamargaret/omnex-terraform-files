resource "aws_vpc" "sec-vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "sec-vpc"
  }
}
# Createing subnets
resource "aws_subnet" "FW-MGMT-security" {
  count      = length(var.subnets.subnet_cidr)
  vpc_id     = aws_vpc.sec-vpc.id
  cidr_block = var.subnets.subnet_cidr[count.index]
  availability_zone = var.subnets.az[count.index]

  tags = {
    Name = var.subnets.subnetnames[count.index]
  }
}



# Creating NICs
resource "aws_network_interface" "nics" {
  count     = length(var.subnets.subnet_cidr)
  subnet_id = aws_subnet.FW-MGMT-security[count.index].id
}

# Create an IGW for vpc

resource "aws_internet_gateway" "security-igw" {
  vpc_id = aws_vpc.sec-vpc.id

  tags = {
    Name = var.igw_name
  }
}

# Create EIP for Nat

resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "NATGW"
  }
}
# Create Nat Gateway

resource "aws_nat_gateway" "sec-nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.FW-MGMT-security[5].id

  tags = {
    Name = var.natgateway.name

  }
}

# Create an Transit Gateway

resource "aws_ec2_transit_gateway" "sec-tgw" {
  description = "example Transit Gateway"

  tags = {
    Name = var.tgw.tgwname
  }
}



# Create Transit Gateway VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "tgwa" {
  transit_gateway_id = aws_ec2_transit_gateway.sec-tgw.id
  vpc_id             = aws_vpc.sec-vpc.id
  subnet_ids         = [aws_subnet.FW-MGMT-security[3].id]

  tags = {
    Name = var.tgw.tgwattachmentname
  }
}

# Create GW Load Balancer

resource "aws_lb" "GWLBep-security-lb" {
  name               = var.gatewaylb.gwlbname
  internal           = false
  load_balancer_type = "gateway"
  subnets            = [aws_subnet.FW-MGMT-security[7].id]
  #  availability_zone = "us-east-2b" 
  tags = {
    Name = var.gatewaylb.tagsname
  }
}


#create targetgroup for gwlb
resource "aws_lb_target_group" "tg" {
  name        = var.gatewaylb.targetgroupname
  target_type = "instance"
  port        = "6081"
  protocol    = "GENEVE"
  vpc_id      = aws_vpc.sec-vpc.id

  health_check {
    protocol = "TCP"
    #port     = "6081"
  }

  tags = {
    Name = var.gatewaylb.targetgrouptagname
  }
}

#Listener for targetgroup
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.GWLBep-security-lb.arn
  # port              = 80
  # protocol          = "GENEVE"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Create an Endpoint Service for the Gateway Load Balancer
resource "aws_vpc_endpoint_service" "sec-gwlb_endpoint_service" {
  acceptance_required        = false
  gateway_load_balancer_arns = [aws_lb.GWLBep-security-lb.arn]

  tags = {
    Name = var.gatewaylb.servicename
  }
}

# Create a VPC Endpoint for the Endpoint Service GWLB-EW
resource "aws_vpc_endpoint" "sec-gwlb_vpc_endpoint" {
  vpc_id            = aws_vpc.sec-vpc.id
  service_name      = aws_vpc_endpoint_service.sec-gwlb_endpoint_service.service_name
  vpc_endpoint_type = "GatewayLoadBalancer"
  subnet_ids        = [aws_subnet.FW-MGMT-security[1].id]

  tags = {
    Name = var.gatewaylb.endpointname_1
  }
}


# Create a VPC Endpoint for the Endpoint Service  GWLB-OUT
resource "aws_vpc_endpoint" "sec-gwlb_vpc_endpoint1" {
  vpc_id            = aws_vpc.sec-vpc.id
  service_name      = aws_vpc_endpoint_service.sec-gwlb_endpoint_service.service_name
  vpc_endpoint_type = "GatewayLoadBalancer"
  subnet_ids        = [aws_subnet.FW-MGMT-security[2].id]

  tags = {
    Name = var.gatewaylb.endpointname_2
  }
}

# Create a Private RT

# resource "aws_route_table" "pvt-rt" {
#   for_each = var.rt
#   vpc_id   = aws_vpc.sec-vpc.id
#   dynamic "route" {
#     for_each = each.value.routes
#     content {
#       cidr_block           = route.value.cidr
#       gateway_id           = route.value.gateway_id == "" ? aws_internet_gateway.security-igw.id : route.value.gateway_id
#       nat_gateway_id       = route.value.nat_gateway_id != "" ? route.value.nat_gateway_id : null
#       network_interface_id = route.value.network_interface_id != "" ? aws_ec2_transit_gateway.sec-tgw.id : null
#       vpc_endpoint_id      = route.value.vpc_endpoint_id != "" ? route.value.vpc_endpoint_id : null

#     }
#   }
#   tags = {
#     Name = each.value.rt_name
#   }
# }


resource "aws_route_table_association" "association" {
  for_each       = local.subnet_to_route_table
  subnet_id      = each.value.subnet_id
  route_table_id = each.value.route_table_id
}

resource "aws_route_table" "pvt-rt" {
  for_each = var.rt
  vpc_id   = aws_vpc.sec-vpc.id
  dynamic "route" {
    for_each = each.value.routes
    content {
      cidr_block           = route.value.cidr
      gateway_id           = (route.value.gateway_id == "local" ? route.value.gateway_id: route.value.gateway_id == "" ? null: aws_internet_gateway.security-igw.id)
      nat_gateway_id       = route.value.nat_gateway_id == "" ? null : route.value.nat_gateway_id
      network_interface_id = (route.value.network_interface_id == "nic" ?  aws_network_interface.nics[3].id: null)
      vpc_endpoint_id      = ( route.value.vpc_endpoint_id == "subnet_2" ? aws_vpc_endpoint.sec-gwlb_vpc_endpoint.id: route.value.vpc_endpoint_id == "subnet_3" ? aws_vpc_endpoint.sec-gwlb_vpc_endpoint1.id: null)

    }
  }
  tags = {
    Name = each.value.rt_name
  }
}