# Create the VPC
resource "aws_vpc" "main" {
  cidr_block       = var.aws_cidr

  tags = {
    Name = var.aws_vpc_name
  }
}

# Create the Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.aws_internet_gateway_name
  }
}

# Create the Custom Routing Table
resource "aws_route_table" "main-route-table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = var.aws_route_table_name
  }
}

# Create a subnet in the first AZ
resource "aws_subnet" "subnet1" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.aws_subnet_1
    availability_zone = var.aws_az_1  
    tags = {
      Name = var.aws_subnet_1_name
    }
}

# Create a subnet in the second AZ
resource "aws_subnet" "subnet2" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.aws_subnet_2
    availability_zone = var.aws_az_2  
    tags = {
      Name = var.aws_subnet_2_name
    }
}

# Associate the subnets with the routing table
resource "aws_route_table_association" "a" {
    subnet_id = aws_subnet.subnet1.id
    route_table_id = aws_route_table.main-route-table.id
}

resource "aws_route_table_association" "b" {
    subnet_id = aws_subnet.subnet2.id
    route_table_id = aws_route_table.main-route-table.id
}

# Create security group
resource "aws_security_group" "allow_traffic" {
  name        = var.aws_security_group_name
  description = "Allow specified traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTPS"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTPS"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.aws_security_group_name
  }
}

# Create the key pair
resource "aws_key_pair" "ssh_public_key" {
    key_name = var.ssh_key_name
    public_key = var.ssh_public_key  
}

# Create two network interfaces, one per subnet
resource "aws_network_interface" "a" {
  subnet_id       = aws_subnet.subnet1.id
  private_ips     = [var.aws_ip_1]
  security_groups = [aws_security_group.allow_traffic.id]
}

resource "aws_network_interface" "b" {
  subnet_id       = aws_subnet.subnet2.id
  private_ips     = [var.aws_ip_2]
  security_groups = [aws_security_group.allow_traffic.id]
}

# Create elastic IPs for the two network interfaces we've created 
# This will allow external traffic to reach these servers
resource "aws_eip" "a" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.a.id
  associate_with_private_ip = var.aws_ip_1
  depends_on = [ aws_internet_gateway.gw ]
}

resource "aws_eip" "b" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.b.id
  associate_with_private_ip = var.aws_ip_2
  depends_on = [ aws_internet_gateway.gw ]
}

# Create two EC2 instances
resource "aws_instance" "a" {
  ami = var.aws_ami_1
  instance_type = var.aws_instance_type_a
  availability_zone = var.aws_az_1
  key_name = var.ssh_key_name
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.a.id
  }
  tags = {
    Name = var.aws_instance_1_name
  }
}

resource "aws_instance" "b" {
  ami = var.aws_ami_2
  instance_type = var.aws_instance_type_b
  availability_zone = var.aws_az_2
  key_name = var.ssh_key_name
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.b.id
  }
  tags = {
    Name = var.aws_instance_2_name
  }
}
