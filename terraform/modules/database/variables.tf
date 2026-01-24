variable "private_subnet_ids" {
  type = list(string)
}

variable "db_security_group_id" {
  type = string
}

variable "kms_key_id" {
  type = string
  default = null
}