variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "home_wifi_cidr" {
  description = ""
  default     = "" 

}

variable "cidr_block" {
  description = "CIDR block address range"
  default     = ""
}
