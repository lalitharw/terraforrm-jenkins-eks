resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "eks-vpc"

  }
}

# public subnets
resource "aws_subnet" "public_eks_subnet" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "eks-public-subnet-${count.index + 1}"
  }
}

# private subnets
resource "aws_subnet" "private_eks_subnet" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.asz.names[count.index]
  cidr_block        = var.private_subnets[count.index]

  tags = {
    Name = "eks-private-subnet-${count.index + 1}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "eks-internet-gateway"
  }
}


# public route table
resource "aws_route_table" "example" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }


  tags = {
    Name = "eks-internet-gateway"
  }
}

resource "aws_route_table_association" "public_rt" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public_eks_subnet[count.index].id
  route_table_id = aws_route_table.example.id
}


#eip
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "eks-eip"
  }
}


#nat gateway
resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_eks_subnet[0].id

  tags = {
    Name = "eks NAT"
  }

  depends_on = [aws_internet_gateway.gw]
}

# private route table
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.example.id
  }


  tags = {
    Name = "eks-nat-gateway"
  }
}

resource "aws_route_table_association" "private_rt" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private_eks_subnet[count.index].id
  route_table_id = aws_route_table.private-route-table.id
}

resource "aws_security_group" "ec2_sg" {
  name        = "eks-ec2-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open SSH to everyone (for demo only)
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound
  }

  tags = {
    Name = "eks-ec2-sg"
  }
}


# create ec2 instance
resource "aws_instance" "instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.public_eks_subnet[0].id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  tags = {
    Name = "eks-ec2"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "eks-cluster"
  kubernetes_version = "1.33"

  endpoint_public_access = true


  eks_managed_node_groups = {
    example = {

      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }



  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private_eks_subnet.*.id

  tags = {
    Name        = "eks-clusters"
    Environment = "dev"
    Terraform   = "true"
  }
}


