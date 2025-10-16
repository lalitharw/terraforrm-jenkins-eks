resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  tags = {
    Name = "jenkins-kubernetes"
  }
}


resource "aws_subnet" "terraform-jenkins-eks-subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnets
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.azs.names[0]

  tags = {
    Name = "terraform-jenkins-eks-subnet"
  }
}

resource "aws_internet_gateway" "terraform-jenkins-eks-internet-gateway"{
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "terraform-jenkins-eks-internet-gateway"
  }
}

resource "aws_route_table" "terraform-jenkins-eks-route-table"{
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform-jenkins-eks-internet-gateway.id
  }

  tags = {
    Name = "terraform-jenkins-eks-route-table"
  }
}

resource "aws_route_table_association" "terraform-jenkins-eks-rta" {
  subnet_id = aws_subnet.terraform-jenkins-eks-subnet.id
  route_table_id = aws_route_table.terraform-jenkins-eks-route-table.id
}

resource "aws_instance" "terraform-jenkins-instance" {
   ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  availability_zone = data.aws_availability_zones.azs.names[0]
  associate_public_ip_address = true
  subnet_id = aws_subnet.terraform-jenkins-eks-subnet.id
  vpc_security_group_ids = var.sg_id
  user_data = file("${path.module}/jenkins-install.sh")
  tags = {
    Name = "terraform-jenkins-instance"
  }
}



