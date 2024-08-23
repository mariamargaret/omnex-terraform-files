terraform {
  backend "s3" {
    bucket = "omnex-terraform-state-bucket"
    key    = "prod/terraform.tfstate"
    region = "us-east-2"
  }
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  # route {
   # cidr_block = "10.1.5.0/24"
   # gateway_id = aws_internet_gateway.igw.id
    #   vpc_endpoint_id = aws_vpc_endpoint.gwlb_vpc_endpoint.id
 # }

 # route {
  #  cidr_block = aws_vpc.main.cidr_block
   # network_interface_id   = data.aws_network_interface.my_eni.id
   # gateway_id = "local" 
#}
  tags = {
    Name = "prod-vpc"
  }
}

 



resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "prod-igw"
  }
}


# Create Subnet
resource "aws_subnet" "GWLBep_PROD" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.Subnet_CIDR1

  tags = {
    Name = "GWLBep_PROD"
  }
}


# Create Gateway Load Balancer
resource "aws_lb" "GWLBep_PROD_lb" {
  name               = "GWLBep-PROD-lb"
  internal           = false
  load_balancer_type = "gateway"
  subnets            = [aws_subnet.GWLBep_PROD.id]

  tags = {
    Name = "prod-gwlb"
  }
}

#create targetgroup for gwlb
resource "aws_lb_target_group" "tg" {
  name     = "GWLBep-PROD-tg"
  target_type = "instance"
  port     = "6081"
  protocol = "GENEVE"
  vpc_id   = aws_vpc.main.id

  health_check {
    protocol = "TCP"
  }

  tags = {
    Name = "GWLBep_PROD-tg"
  }
}

#Listener for targetgroup
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.GWLBep_PROD_lb.arn

   default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Create an Endpoint Service for the Gateway Load Balancer
resource "aws_vpc_endpoint_service" "gwlb_endpoint_service" {
  acceptance_required = false
  gateway_load_balancer_arns = [aws_lb.GWLBep_PROD_lb.arn]

  tags = {
    Name = "prod-gateway-load-balancer-endpoint-service"
  }
}

# Create a VPC Endpoint for the Endpoint Service
resource "aws_vpc_endpoint" "gwlb_vpc_endpoint" {
  vpc_id            = aws_vpc.main.id
  service_name      = aws_vpc_endpoint_service.gwlb_endpoint_service.service_name
  vpc_endpoint_type = "GatewayLoadBalancer"
  subnet_ids        = [aws_subnet.GWLBep_PROD.id]

  tags = {
    Name = "prod-vpc-endpoint"
  }
}

# Create Route Table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "GWLBe-PROD_RT"
	}
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.GWLBep_PROD.id
  route_table_id = aws_route_table.rt.id
}




# Create Subnet(10.1.1.0/24)
resource "aws_subnet" "webserver-PROD" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.1.1.0/24"

  tags = {
    Name = "Webserver-PROD"
  }
}


# Create Route Table
resource "aws_route_table" "rt2" {
 vpc_id = aws_vpc.main.id
 #  lifecycle {
 #   ignore_changes = [route]
 #}

  route {
    cidr_block = "10.1.1.0/24"
   network_interface_id   = data.aws_network_interface.my_eni.id
  }

   route {
   cidr_block = "0.0.0.0/0"
   network_interface_id   = data.aws_network_interface.my_eni.id
  }

  route {
    cidr_block = aws_vpc.main.cidr_block
   #network_interface_id   = data.aws_network_interface.my_eni.id
  gateway_id = "local"
 }


  tags = {
    Name = "webserver-PROD_RT"
        }

}

# Associate Route Table with Subnet
resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.webserver-PROD.id
  route_table_id = aws_route_table.rt2.id
}



# Create Subnet(10.1.2.0/24)
resource "aws_subnet" "DBserver-PROD" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.Subnet_CIDR4

  tags = {
    Name = "DBserver-PROD"
  }
}


# Create Route Table
resource "aws_route_table" "rt3" {
  vpc_id = aws_vpc.main.id
 #lifecycle {
 #  ignore_changes = [ route ]
 # }

   route {
   cidr_block = "0.0.0.0/0"
   network_interface_id   = data.aws_network_interface.my_eni.id
  }

  route {
    cidr_block = "10.0.0.0/16"
    network_interface_id   = data.aws_network_interface.my_eni.id
  }


  route {
    cidr_block = aws_vpc.main.cidr_block
   # network_interface_id   = data.aws_network_interface.my_eni.id
   gateway_id = "local"
 }



  tags = {
    Name = "DBserver-PROD_RT"
        }

#depends_on = ["data.aws_network_interface.my_eni"]

}

# Associate Route Table with Subnet
resource "aws_route_table_association" "rta3" {
  subnet_id      = aws_subnet.DBserver-PROD.id
  route_table_id = aws_route_table.rt3.id
}



# Create an Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets           = [aws_subnet.App-ALB-PROD-1a.id, aws_subnet.App-ALB-PROD-1b.id]

  tags = {

    Name = "app-alb"
	}
  
}


# Create a Target Group
resource "aws_lb_target_group" "prodapp_tg" {
  name        = "prodapp-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    protocol            = "HTTP"
  }

  tags = {
    Name = "app-tg"
  }
}

# Create a Listener
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prodapp_tg.arn
  }
}


# Create a Security Group for the ALB
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

# Create Subnet(10.1.5.0/24)
resource "aws_subnet" "App-ALB-PROD-1a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.Subnet_CIDR5
  availability_zone = "us-east-2a"

  tags = {
    Name = "App-ALB-PROD-1a"
  }
}


# Create Route Table
resource "aws_route_table" "rt4" {
  vpc_id = aws_vpc.main.id

#lifecycle {
 # ignore_changes = [ route ]
 # }


  route {
    cidr_block = "0.0.0.0/0"
    vpc_endpoint_id        = aws_vpc_endpoint.gwlb_vpc_endpoint.id
  }

  route {
    cidr_block = aws_vpc.main.cidr_block
 # network_interface_id   = data.aws_network_interface.my_eni.id
    gateway_id = "local"
}
  tags = {
    Name = "App-ALB-PROD-1a-RT"
        }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "rta4" {
  subnet_id      = aws_subnet.App-ALB-PROD-1a.id
  route_table_id = aws_route_table.rt4.id
}





# Create Subnet(10.1.6.0/24)
resource "aws_subnet" "App-ALB-PROD-1b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.Subnet_CIDR6
  availability_zone = "us-east-2b"
  tags = {
    Name = "App-ALB-PROD-1b"
  }
}


# Create Route Table
resource "aws_route_table" "rt5" {
  vpc_id = aws_vpc.main.id
  # lifecycle {
  #  ignore_changes = [route]
 #}
  route {
    cidr_block = "0.0.0.0/0"
    vpc_endpoint_id = aws_vpc_endpoint.gwlb_vpc_endpoint.id
  }

 route {
    cidr_block = aws_vpc.main.cidr_block
  #  network_interface_id   = data.aws_network_interface.my_eni.id
    gateway_id = "local"
}
  tags = {
    Name = "App-ALB-PROD-1b-RT"
        }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "rta5" {
  subnet_id      = aws_subnet.App-ALB-PROD-1b.id
  route_table_id = aws_route_table.rt5.id
}



# Create Transit Gateway
resource "aws_ec2_transit_gateway" "prod-tgw" {
  description = "example Transit Gateway"

  tags = {
    Name = "Transit-gateway"
  }
}



# Create Transit Gateway VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "tgwa" {
  transit_gateway_id = aws_ec2_transit_gateway.prod-tgw.id
  vpc_id             = aws_vpc.main.id
  subnet_ids         = [aws_subnet.tgweni-PROD.id]

  tags = {
    Name = "prod-tgw-attachment"
  }
}


# Fetch the existing ENI based on a tag or some other identifier
data "aws_network_interface" "my_eni" {
  filter {
    name   = "subnet-id"
    values = [aws_subnet.tgweni-PROD.id]
  }
}


# Create Subnet(10.1.3.0/24)
resource "aws_subnet" "tgweni-PROD" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.Subnet_CIDR3

  tags = {
    Name = "tgweni-PROD"
  }
}


# Create Route Table
resource "aws_route_table" "rt6" {
  vpc_id = aws_vpc.main.id


   route {
    cidr_block = "10.0.0.0/16"
     network_interface_id   = data.aws_network_interface.my_eni.id
  }

  route {
    cidr_block = "10.1.0.0/16"
     gateway_id   = "local"

  }

  tags = {
    Name = "tgweni-prod-rt"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "rta6" {
  subnet_id     = aws_subnet.tgweni-PROD.id
  route_table_id = aws_route_table.rt6.id
}


# Create Subnet Bastion-security
resource "aws_subnet" "Bastion-prod" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.Subnet_CIDR7

  tags = {
    Name = "Bastion-prod"
  }
}


# Create Route Table
resource "aws_route_table" "rt8" {
  vpc_id = aws_vpc.main.id
  
 # lifecycle {
 #   ignore_changes = [route]
# }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    cidr_block = aws_vpc.main.cidr_block
   # network_interface_id   = data.aws_network_interface.my_eni.id
    gateway_id = "local"
}
  tags = {
    Name = "Bastion-RT-prod"
        }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "rta8" {
  subnet_id     = aws_subnet.Bastion-prod.id
  route_table_id = aws_route_table.rt8.id
}
