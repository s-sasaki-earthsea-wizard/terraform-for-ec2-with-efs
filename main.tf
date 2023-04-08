locals {
  subnet_ids_list = data.aws_subnets.selected.ids
}

provider "aws" {
  region = "ap-northeast-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_efs_file_system" "example" {
  creation_token = "example-efs"
}

resource "aws_efs_mount_target" "efs_mount_target" {
  for_each        = { for index, subnet in aws_subnet.example : index => subnet }
  file_system_id  = aws_efs_file_system.example.id
  subnet_id       = each.value.id
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  description = "Allow inbound NFS traffic from EC2 instances"
  vpc_id      = aws_vpc.example.id
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow inbound SSH and NFS traffic"
  vpc_id      = aws_vpc.example.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_security_group_rule" "efs_sg_ingress" {
  security_group_id = aws_security_group.efs_sg.id

  type        = "ingress"
  from_port   = 2049
  to_port     = 2049
  protocol    = "tcp"
  source_security_group_id = aws_security_group.ec2_sg.id
}

resource "aws_security_group_rule" "ec2_sg_ssh_ingress" {
  security_group_id        = aws_security_group.ec2_sg.id

  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ec2_sg_nfs_ingress" {
  security_group_id        = aws_security_group.ec2_sg.id

  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.efs_sg.id
}

resource "aws_vpc" "example" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "example-vpc"
  }
}

resource "aws_vpc_dhcp_options" "example" {
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    Name = "example-dhcp-options"
  }
}

resource "aws_vpc_dhcp_options_association" "example" {
  vpc_id          = aws_vpc.example.id
  dhcp_options_id = aws_vpc_dhcp_options.example.id
}


resource "aws_subnet" "example" {
  count = var.instance_count
  cidr_block = "${cidrsubnet(var.vpc_cidr_block, 8, count.index)}"
  vpc_id     = aws_vpc.example.id
  availability_zone = "${var.aws_region}${element(var.az_list, count.index)}"
  tags = {
    Name = "example-subnet-${count.index}"
  }
}

resource "aws_subnet" "public" {
  cidr_block = var.public_subnet_cidr_block
  vpc_id     = aws_vpc.example.id
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow inbound SSH traffic to the bastion host"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "bastion_sg_ssh_ingress" {
  security_group_id = aws_security_group.bastion_sg.id

  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "efs_access" {
  count = var.instance_count
  security_group_id = aws_security_group.ec2_sg.id

  type        = "ingress"
  from_port   = 2049
  to_port     = 2049
  protocol    = "tcp"
  cidr_blocks = ["${aws_instance.example[count.index].private_ip}/32"]
}

resource "aws_eip" "bastion" {
  vpc = true
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
}

resource "aws_iam_role" "example" {
  name = "example-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "example" {
  name        = "example-policy"
  description = "Custom IAM policy for example instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeAvailabilityZones",
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "example" {
  name = "example-instance-profile"
  role = aws_iam_role.example.name
}

resource "aws_iam_role_policy_attachment" "example" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientReadWriteAccess"
  role       = aws_iam_role.example.name
}

resource "aws_iam_role_policy_attachment" "example_custom_policy" {
  policy_arn = aws_iam_policy.example.arn
  role       = aws_iam_role.example.name
}


resource "aws_instance" "bastion" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [
    aws_security_group.bastion_sg.id,
  ]

  subnet_id = aws_subnet.public.id

  tags = {
    Name = "bastion-host"
  }

  # Associate the EIP with the bastion host
  associate_public_ip_address = true
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = var.instance_count

  subnet_id      = aws_subnet.example[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_eip_association" "bastion" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion.id
}

resource "aws_instance" "example" {
  ami           = var.ami_id  # Ubuntu 20.04 LTS (Focal Fossa) in ap-northeast-1 region
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id,
  ]

  subnet_id = aws_subnet.example[count.index].id

  iam_instance_profile = aws_iam_instance_profile.example.name

  count = var.instance_count # the number of EC2 instances to create

  tags = {
    Name = "example-instance-${format("%02d", count.index)}"
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update -y
                sudo apt-get install -y nfs-common git binutils python3-pip
                sudo pip3 install botocore
                echo "alias python=python3" | sudo tee -a /etc/bash.bashrc
                echo "alias pip=pip3" | sudo tee -a /etc/bash.bashrc
                sudo mkdir -p /mnt/efs
                git clone https://github.com/aws/efs-utils
                cd ./efs-utils
                sudo ./build-deb.sh
                sudo apt-get install -y ./build/amazon-efs-utils*deb
                sudo mount -t efs -o tls,iam ${aws_efs_file_system.example.id}:/ /mnt/efs 
                echo '${aws_efs_file_system.example.id}:/ /mnt/efs efs tls,iam,_netdev 0 0' | sudo tee -a /etc/fstab
              EOF
}