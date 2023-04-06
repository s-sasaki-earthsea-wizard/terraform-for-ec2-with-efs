# Terraform
TERRAFORM := $(shell command -v terraform 2> /dev/null)

check_terraform:
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

# include aws cli commands
include aws-cli.mk
