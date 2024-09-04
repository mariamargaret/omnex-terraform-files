variable "vpc_cidr" {
  type = string
}

variable "subnets" {
  type = object({
    subnet_cidr = list(string)
    subnetnames = list(string)
    az = list(string)
  })
}
variable "igw_name" {
  type = string
}

variable "natgateway" {
  type = object({
    name = string
  })
}

variable "tgw" {
  type = object({
    tgwname           = string
    tgwattachmentname = string
  })
}

variable "gatewaylb" {
  type = object({
    gwlbname           = string
    tagsname           = string
    targetgroupname    = string
    targetgrouptagname = string
    endpointname_1     = string
    endpointname_2     = string
    servicename        = string
  })
}

#variable "pvt-rt" {
#type = object({
# cidr_block = list(string)

#})
#}

variable "rt" {
  type = map(object({
    rt_name = string
    routes = list(object({
      cidr                 = string
      vpc_endpoint_id      = string
      network_interface_id = string
      gateway_id           = string
      nat_gateway_id       = string
    }))

  }))

}