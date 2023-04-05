# Terraform
TERRAFORM := $(shell command -v terraform 2> /dev/null)

install_terraform:
ifndef TERRAFORM
	echo "Please read terraform docs for installation https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli"
else
	echo "Terraform is already installed."
endif

# Terraform init
init:
	terraform init

# Terraform plan
plan:
	terraform plan -out apply.tfplan
	terraform plan -destroy -out destroy.tfplan

# Terraform apply
apply:
	terraform apply apply.tfplan

# Terraform destroy
destroy:
	terraform apply destroy.tfplan

# fetch bastion host ip
get_bastion_ip:
	aws ec2 describe-instances --filters "Name=tag:Name,Values=bastion-host" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].PublicIpAddress" --output text

# fetch private ip of EC2 instance
get_private_ip:
	aws ec2 describe-instances --filters "Name=tag:Name,Values=example-instance-*" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].[Tags[?Key=='Name'].Value | [0], PrivateIpAddress]" --output text
