# fetch bastion host ip
bastion_ip:
	aws ec2 describe-instances --filters "Name=tag:Name,Values=bastion-host" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].PublicIpAddress" --output text

# fetch private ips of EC2 instances
private_ips:
	aws ec2 describe-instances --filters "Name=tag:Name,Values=example-instance-*" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].[Tags[?Key=='Name'].Value | [0], PrivateIpAddress]" --output text
