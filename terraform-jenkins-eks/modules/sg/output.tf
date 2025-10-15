output "vpc_security_group_ids" {
  value = [aws_security_group.terraform-jenkins-eks-sg.id,aws_security_group.terraform-jenkins-rule-sg.id]
}