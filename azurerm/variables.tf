variable "environment" {
  type = string
}

variable "allowed_environments" {
  type = list(string)
  default = ["d","t","a","p"]
}

variable "environment_map" {
  type = map(string)
  default = {
    "d" = "dev",
    "t" = "tst",
    "a" = "acc",
    "p" = "prod"
  }
}

variable "location" {
    type = string
    default = "we"
}

variable "location_map" {
  type = map(string)
  default = {
    "we" = "West Europe"
  }
}