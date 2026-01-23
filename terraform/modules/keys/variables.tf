variable "key_pair_name" {
  description = "Name of the AWS key pair"
  type        = string
}

variable "private_key_path" {
  description = "Path where the private key will be saved"
  type        = string
}

variable "key_algorithm" {
  description = "Algorithm for the key generation"
  type        = string
  default     = "RSA"
}

variable "key_rsa_bits" {
  description = "Number of bits for RSA key"
  type        = number
  default     = 4096
}

variable "private_key_permission" {
  description = "File permission for the private key"
  type        = string
  default     = "0400"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
