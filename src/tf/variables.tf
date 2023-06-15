variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "home_wifi_cidr" {
  description = "CIDR notation for your home WiFi network"
  default     = "192.168.0.0/24" #en0 INET FOR CIDR NOTATION
  #default     = "192.168.184.108/32" OFFICE WIFI FOR TESTING SWAP BACK
}

variable "cidr_block" {
  description = "CIDR block address range"
  default     = "10.0.0.0/16"
}