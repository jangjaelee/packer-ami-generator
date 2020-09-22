#!/bin/bash
#-*-Shell-script-*-
#
#/**
# * Title    : Packer AMI json template generator
# * Auther   : Alex, Lee
# * Created  : 2020-05-31
# * Modified : 2020-09-14
# * E-mail   : cine0831@gmail.com
#**/
#
#set -e
#set -x

# Tag Key:Value
# If it is changed a Tag (Name, Values) of BastionSRV, Subnet, Security Group, require to change below variables
BastionSRV=""
Subnet=""
Security=""

######################
## for CentOS 7
# comment about AMI
#COMMENT="WEB Server AMI (CentOS 7)"

# Amazon Machine ID
#AMI_ID="ami-06e83aceba2cb0907"

# AMI Description
#AMI_DESCRIPTION="WEB Server on Amazon Linux 2 (x86_64)"
######################
## for Amazon Linux 2
# comment about AMI
COMMENT="WEB Server AMI (Amazon Linux 2))"

# Amazon Machine ID
AMI_ID="ami-01af223aa7f274198"

# AMI Description
AMI_DESCRIPTION="WEB Server on Amazon Linux 2 (x86_64)"
######################

# Account for AMI login user account
#ACCOUNT="centos"  # CentOS
#ACCOUNT="ubuntu"  # Ubuntu
ACCOUNT="ec2-user" # Amazon Linux


# VPC-ID
VPC=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].{VPC:VpcId}' --filter "Name=tag:Name,Values=${BastionSRV}" --output text)
VPC=$(echo $VPC | sed -e 's/None//g' -e 's/ //g')

# Bastion IP Address
IP=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].{IP:PublicIpAddress}' --filter "Name=tag:Name,Values=${BastionSRV}" --output text)
IP=$(echo $IP | sed -e 's/None//g' -e 's/ //g')

# Packer Image Instance on Subnet
Subnet=$(aws ec2 describe-subnets --query 'Subnets[*].{SN:SubnetId}' --filter "Name=tag:Name,Values=${Subnet}" --output text)
Subnet=$(echo $Subnet | sed -e 's/None//g' -e 's/ //g')

# Packer Image Instance of Security Group
Security=$(aws ec2 describe-security-groups --query 'SecurityGroups[*].{SG:GroupId}' --filter "Name=tag:Name,Values=${Security}" --output text)
Security=$(echo $Security | sed -e 's/None//g' -e 's/ //g')

# Internal-ABL DNS name
#InternalALB=$(aws elbv2 describe-load-balancers --names ALB-awx-WAS --query 'LoadBalancers[*].{DNS:DNSName}' --output text)
#InternalALB=$(echo $InternalALB | sed -e 's/None//g' -e 's/ //g')

if [[ -z "${InternalALB}" ]]; then 
  InternalALB="was.awx.internal"
fi
echo "${InternalALB}"


# How to use
function usage() {
    echo "
Usage: ${0##*/} [template.json]

Examples:
    ${0##*/} filename
"
exit 1
}

function template() {
    local filename=$1

# Packer Image template
echo -e '{
  "_comment": "'${COMMENT}'",
  "variables": {
    "aws_access_key": "{{env `AWS_ACCESS_KEY_ID`}}",
    "aws_secret_key": "{{env `AWS_SECRET_ACCESS_KEY`}}",
    "aws_region": "{{env `AWS_REGION`}}",
    "ami_name": "AMI-EC2-WEB_{{isotime \"2006-01-02_1504\"}}"
  },
  "builders": [
    {
      "type": "amazon-ebs",
      "access_key": "{{user `aws_access_key`}}",
      "secret_key": "{{user `aws_secret_key`}}",
      "region": "{{user `aws_region`}}",
      "source_ami": "'${AMI_ID}'",
      "instance_type": "t2.micro",
      "communicator": "ssh",
      "ssh_username": "'${ACCOUNT}'",
      "ssh_interface": "private_ip",
      "ssh_bastion_port": 22,
      "ssh_bastion_host": "'${IP}'",
      "ssh_bastion_username": "ec2-user",
      "ssh_bastion_private_key_file": "~/.ssh/id_rsa",
      "vpc_id": "'${VPC}'",
      "subnet_id": "'${Subnet}'",
      "security_group_id": "'${Security}'",
      "ami_name": "{{user `ami_name` | clean_resource_name}}",
      "ami_description": "'${AMI_DESCRIPTION}'",
      "tags": {
        "Name": "{{user `ami_name` | clean_resource_name}}",
        "BaseAMI_Id": "{{ .SourceAMI }}",
        "BaseAMI_Name": "{{ .SourceAMIName }}",
        "TYPE": "EC2.ami"
      }
    }
  ],
  "provisioners": [
    {
      "type": "ansible",
      "playbook_file": "playbook/main.yml",
      "user": "'${ACCOUNT}'"
    },
    {
      "type": "shell",
      "inline": [
        "git clone https://github.com/jangjaelee/deploytest.git",
        "cd deploytest",
        "sudo sed -i s/Internal-ALB/'${InternalALB}'/g nginx.conf",
        "sudo cp nginx.conf /etc/nginx/nginx.conf",
        "curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip",
        "unzip awscliv2.zip",
        "sudo ./aws/install"
      ]
    }
  ]
}' > $filename

}

# -- main --
if [ -z "${1}" ]; then
    usage
else
    template $1
fi
