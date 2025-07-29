variable "resource_suffixes" {
  type = string
}

variable "location" {
  type = string
}

variable "subnets" {
  type = map(object({
      ip_3rd_octet = number
      private = bool
  }))
}