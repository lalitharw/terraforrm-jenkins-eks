resource "aws_security_group" "terraform-jenkins-eks-sg" {
  name        = "terraform-jenkins-eks"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id

# http
 ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
 }

#  ssh
ingress{
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

# output traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-jenkins-eks-sg"
  }
}

resource "aws_security_group" "terraform-jenkins-rule-sg" {
   name        = "terraform-jenkins-rule-sg"
  description = "Terraform Jenkins Rule Security Group"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "terraform-jenkins-rule-sg"
    }
 
}