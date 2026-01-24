#!/bin/bash
apt-get update
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOL
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "/aws/ec2/frontend",
            "log_stream_name": "frontend-{instance_id}"
          },
          {
            "file_path": "/var/log/docker.log",
            "log_group_name": "/aws/ec2/docker",
            "log_stream_name": "frontend-docker-{instance_id}"
          }
        ]
      }
    }
  }
}
EOL

systemctl start amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent