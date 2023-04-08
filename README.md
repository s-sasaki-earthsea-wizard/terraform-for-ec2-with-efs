# terraform-for-ec2-with-efs

## Overview
This repository contains Terraform codes to create AWS EC2 instances and mount EFS on them.

## Development environment
- OS: MacOS 13.2.1
- Terraform: v1.4.2
- AWS CLI: 2.10.0

## Installation
### Terraform installation
Please install Terraform according to official document;
- https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

### Environmental variables

Set your AWS access key and secret access key in the bash shell as follows:
```
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_access_key"
```

Also, set your key pair name, VPC ID, and subnet ID in the bash shell as follows: 
```
export TF_VAR_key_name="your_key_pair_name"
export TF_VAR_vpc_id="your_vpc_id"
export TF_VAR_subnet_id="your_subnet_id"
```

These can be also declared in `*.tfvars`

## Usage

### Initializaion
Initialize the Terraform project by running:
```
terraform init
```

The `Makefile` enables to do same running by:
```
make init
``` 

### Check the Changes to Resources
Review the planned changes by running:
```
terraform plan -var-file=${your_tfvars_file.tfvars} -out apply.tfplan
```
then, tha plan is saved to `apply.tfplan` file.

You should also create a `destroy.tfplan` file runnigng by:
```
terraform plan -destroy -out=destroy.tfplan 
```
which is needed to delete the resource.

These two commands are summarizing by `Makefile` runnning by:
```
make plan
```
Here, `*.tfvars` file is assumed to be default file name `terraform.tfvars`

If an error occurs, you can check it by running:
```
terraform graph -draw-cycles
```

### Apply the changes
Apply the Terraform code to the resources by running:
```
terraform apply apply.tfplan
```

or 

```
make apply
```

### Destruction (if needed)
If you would like to clean up the resources, you can do so by running:
```
terraform destroy
```

## Connection to Resources
### Add ssh key
Add ssh key running by:
```
eval "$(ssh-agent -s)"
ssh-add ${your_key_pem_file}
```

### ssh connection to bastion host
You can connect to bastion host running by:
```
ssh -i ${your_pem_key} ubuntu@<bastion_host_public_ip>
```

You can see the public IP of bastion host runnning by:
```
aws ec2 describe-instances --filters "Name=tag:Name,Values=bastion-host" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].PublicIpAddress" --output text
```

#### Access right to pem file
If you cannot connect bastion host, please run:
```
chmod 400 ${your_pem_key}
```

Of course, tou can also use AWS console.

## Others
### Trouble shooting
Check cloud resource building log running by: 
```
cat /var/log/cloud-init-output.log
```

```
cat /etc/resolv.conf
```

### Usage of graphviz
It is usefull to visualize resources by using `graphviz`.
It can be installed running by:
```
sudo apt install graphviz
```

If `graphviz` is installed successfully, running:
```
dot -V
```
should show the Graphviz version.

You can viaualize the graph by:
```
terraform graph -draw-cycles | dot -Tsvg > graph.svg
```