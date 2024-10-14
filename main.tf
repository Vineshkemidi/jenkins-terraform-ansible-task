provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "backend" { #ubuntu.yaml NETADATA
  ami                    = "ami-00eb69d236edcfaf8"
  instance_type          = "t2.micro" 
  key_name               = "ubuntu-key"
  vpc_security_group_ids = ["sg-0513ea7377a50c7dd"]
  tags = {
    Name = "u22.local"
  }
  user_data = <<-EOF
  #!/bin/bash
  sudo hostnamectl set-hostname U22.local
  # netdata_conf="/etc/netdata/netdata.conf"
  # Path to netdata.conf
  # actual_ip=0.0.0.0
  # Use sed to replace the IP address in netdata.conf
  # sudo sed -i "s/bind socket to IP = .*$/bind socket to IP = $actual_ip/" "$netdata_conf"
EOF

}

resource "aws_instance" "frontend" { #amazon-playbook.yaml NGINX
  ami                    = "ami-09da212cf18033880"
  instance_type          = "t2.micro"
  key_name               = "linux"
  vpc_security_group_ids = ["sg-0513ea7377a50c7dd"]
  tags = {
    Name = "c8.local"
  }
  user_data = <<-EOF
  #!/bin/bash
  # New hostname and IP address
  sudo hostnamectl set-hostname u22.local
  hostname=$(hostname)
  public_ip="$(curl -s https://api64.ipify.org?format=json | jq -r .ip)"

  # Path to /etc/hosts
  echo "${aws_instance.backend.public_ip} $hostname" | sudo tee -a /etc/hosts

EOF
depends_on = [aws_instance.backend]
}

resource "local_file" "inventory" {
  filename = "./inventory.yaml"
  content  = <<EOF
[frontend]
${aws_instance.frontend.public_ip}
[backend]
${aws_instance.backend.public_ip}
EOF
}

output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}

output "backend_public_ip" {
  value = aws_instance.backend.public_ip
}
