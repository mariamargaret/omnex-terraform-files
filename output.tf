output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}


# Output Transit Gateway ID
output "transit_gateway_id" {
  value = aws_ec2_transit_gateway.prod-tgw.id
}


# Output Load Balancer ARN
output "gwlb_arn" {
  value = aws_lb.GWLBep_PROD_lb.arn
}

# Output Load Balancer ARN
output "gwlb_endpoint_service" {
   value = aws_vpc_endpoint_service.gwlb_endpoint_service.arn
}


# Output the ALB DNS name
output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}
