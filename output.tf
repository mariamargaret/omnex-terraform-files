output "vpc_endpoint_1_out" {
  value = aws_vpc_endpoint.sec-gwlb_vpc_endpoint1.id 
}

output "vpc_endpoint_2_EW" {
  value = aws_vpc_endpoint.sec-gwlb_vpc_endpoint.id 
}

output "tgw-id" {
  value = aws_ec2_transit_gateway.sec-tgw.id
}