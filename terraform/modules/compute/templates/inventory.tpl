[webservers]
${public_ip} ansible_user=${ssh_user} ansible_ssh_private_key_file=${private_key_path} ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[webservers:vars]
ansible_python_interpreter=/usr/bin/python3
instance_name=${instance_name}
