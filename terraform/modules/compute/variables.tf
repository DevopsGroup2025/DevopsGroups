variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_role" {
  description = "Role tag for the instance"
  type        = string
  default     = "web"
}

variable "environment" {
  description = "Environment tag for the instance"
  type        = string
  default     = "web_dev"
}

variable "key_pair_name" {
  description = "Name of the key pair to use"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "custom_ami" {
  description = "Custom AMI ID (leave empty to use latest Amazon Linux 2)"
  type        = string
  default     = ""
}

variable "associate_public_ip" {
  description = "Associate a public IP address"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = false
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 8
}

variable "root_volume_type" {
  description = "Type of root volume"
  type        = string
  default     = "gp3"
}

variable "enable_encryption" {
  description = "Enable EBS encryption"
  type        = bool
  default     = true
}

variable "user_data" {
  description = "User data script"
  type        = string
  default     = ""
}

variable "create_before_destroy" {
  description = "Create new instance before destroying old one"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "ssh_user" {
  description = "SSH user for the instance"
  type        = string
  default     = "ec2-user"
}

variable "private_key_path" {
  description = "Path to the private SSH key"
  type        = string
}

variable "inventory_file_path" {
  description = "Path where Ansible inventory file will be created"
  type        = string
}
