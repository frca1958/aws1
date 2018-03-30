# What I did

### Markdown cheatsheet
[here](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet)

### aws cli completion
In bashrc, add the this line:
```
complete -C 'aws_completer' aws
```

###JSON query utility
```
sudo apt install jq
```
[Docs here](https://stedolan.github.io/jq/manual/)

###Formatting of AWS output.
You can use `--output table` or `--output text` to get nicer results

###Create a basic security group for ssh and http(s) access
```
aws ec2 create-security-group --group-name dev_front --description "Front-End" --output text
aws ec2 authorize-security-group-ingress --group-name dev_front --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name dev_front --protocol tcp --port 80 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-name dev_front --protocol tcp --port 443 --cidr 0.0.0.0/0
```
###create a ssh keypair and upload the public key

[This document](http://mah.everybody.org/docs/ssh) explains how to use passwordless ssh with ssh-agent.
Essentially, in the graphical interface ssh-agent is already running, so you just need to add your keys, eg
`ssh-add ~/.ssh/frca1958.pem` 

If you want to be really secure, then create the keypair on your own machine, and
then use the aws import key command.
```
aws ec2 import-key-pair --key-name vbox_kl --public-key-material file:///home/fc/.ssh/id_rsa.pub
```
note: the `file://` identifier is required for aws!! Otherwise error.
note: to create a pub key from existing private pem, do like `ssh-keygen -y -f ~/.ssh/id_rsa > ~/.ssh/id_rsa.pub`


###Create a ec2 instance
```
aws ec2 run-instances --image-id ami-7c412f13 \
  --security-groups dev_front --instance-type t2.micro --key-name vbox_kl \
  --query 'Instances[0].InstanceId'
#example to get the IP address. Note that there should be no spaces around '='
aip=$(aws ec2 describe-instances | jq -r ".Reservations[] | .Instances[] | .PublicIpAddress")
echo $aip

```

###Ssh to the instance (using $aip for the public ip). 
Note that this instance logs in as 'ubuntu', not ec2-user.
It can be helpful to see the system log in the AWS instance interface.
```
ssh ubuntu@$aip

```

###Setting up git

I have a git repo at github with ssh access (key frca1958).
So I want to setup git on the this machine to interact with my repository.



