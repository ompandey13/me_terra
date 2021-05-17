resource "aws_instance" "LandingPageInstance" {
  ami           = "ami-00399ec92321828f5"
  key_name = "main-key"
  instance_type = "t2.micro"
  availability_zone = "us-east-2a"
  tags= {
    Name = "wp_instance"
  }
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update && apt-get upgrade -y
              sudo apt install nginx -y
              systemctl enable nginx
              systemctl start nginx
              sudo apt-get install mysql-server mysql-client -y
              systemctl enable mysql
              add-apt-repository ppa:ondrej/php
              apt-get install software-properties-common -y
              apt-get install python-software-properties -y
              sudo apt-get autoremove
              apt-get update
              apt-get -y install unzip zip nginx php7.4 php7.4-mysql php7.4-fpm php7.4-mbstring php7.4-xml php7.4-curl
              apt-get -y install composer
              EOF
}

# Create vpc
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
}

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod"
  }
}

# Create a Subnet

resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"
  tags = {
    Name = "prod"
  }
}

# Associate subnet with Route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

#Create security group with firewall rules
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "security group for wp"
  vpc_id = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 # outbound from jenkis server
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags= {
    Name = "allow_web"
  }
}

# Create a network interface with an IP in the subnet that was created in step 4
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

# Create Elastic IP address
# resource "aws_eip" "LandingPageInstance" {
#  vpc      = true
#  instance = aws_instance.LandingPageInstance.id
# tags= {
#    Name = "wp_elstic_ip"
#  }
#}

resource "aws_eip" "one" {
  vpc = true
  network_interface = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}
