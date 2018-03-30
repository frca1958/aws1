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
```
git config --global user.name "fc_vbox_kl"
git config --global user.email "frca1958@gmail.com"
git config --global push.default simple
git clone git@github.com:frca1958/aws1.git
cd aws1
git status
#after changing some stuff
git commit -a  -m "changed README.md"
git push
#and so on

```

###Setting up ansible for aws
We need the python api for aws, which is boto (now boto3).
Also, we need to install ansible
```
#I use boto3 and boto. This provides api for aws. Not sure which i need
sudo pip install boto3  boto
sudo apt-get install software-properties-common
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update
sudo apt-get install ansible
```



###Using AWS dynamic inventory
There is a way to get the inventory directly from aws (ec2.py and ec2.ini).
I made the following mods:
- copied '/etc/ansible/ansible.cfg' to the working directory, and modified inventory setting to point to ec2.py
- in ec2.ini, limit the regions to just the frankfurt region. This makes ec2.py much faster


###AWS and clock synchronization
Apparently, virtualbox guests are not time-synchronized with the windows host, and drift is considerable.
The service that should do the sync is apparently dead.
```
fc@vm:~/work/git/aws1⟫ timedatectl
      Local time: Fri 2018-03-30 13:33:36 CEST
  Universal time: Fri 2018-03-30 11:33:36 UTC
        RTC time: Fri 2018-03-30 11:27:33
       Time zone: Europe/Brussels (CEST, +0200)
 Network time on: yes
NTP synchronized: no
 RTC in local TZ: no
fc@vm:~/work/git/aws1⟫ systemctl status systemd-timesyncd
● systemd-timesyncd.service - Network Time Synchronization
   Loaded: loaded (/lib/systemd/system/systemd-timesyncd.service; enabled; vendor preset: enabled)
  Drop-In: /lib/systemd/system/systemd-timesyncd.service.d
           └─disable-with-time-daemon.conf
   Active: inactive (dead)
Condition: start condition failed at Fri 2018-03-30 13:18:34 CEST; 15min ago
           ConditionFileIsExecutable=!/usr/sbin/VBoxService was not met
     Docs: man:systemd-timesyncd.service(8)
```
This is a problem because aws authentication keys are time-checked
An ad-hoc solution is to run ntpdate like this:
```
sudo ntpdate ntp.ubuntu.com
```

A better solution would of course be to resolve the VBox issue...

###Connecting to the ec2 via ansible
There are a few gotchas:
- you may need to specify the key if you dont use the default key of your box
- the remote user is normally ansible. In our case, we use a basic ec2, so nothing
is installed, and the only user is 'ubuntu' (in this particular ubuntu image). The remote user can be set in the `ansible.cfg` file.
```
ansible --private-key ~/.ssh/KEY-FC-VBOX.pem all -m ping
52.59.193.47 | FAILED! => {
    "changed": false, 
    "module_stderr": "Shared connection to 52.59.193.47 closed.\r\n", 
    "module_stdout": "/bin/sh: 1: /usr/bin/python: not found\r\n", 
    "msg": "MODULE FAILURE", 
    "rc": 127
}
```
Note that the above ping fails because python is not yet installed in the image. However, the ssh connection succeeded.


###Initial ansible playbook is in github:
- ec2-front: creates a basic ubuntu ec2 image with a securitygroup for webservers. Connection is checked before exiting.
- ec2-teardown: tears down the ec2 instance and the security group.
Calls are like this:
```
ansible-playbook -i ./hosts ec2-front.yml
ansible --list-hosts all
ansible --private-key ~/.ssh/KEY-FC-VBOX.pem all -a "/bin/echo Hello"
ansible-playbook  ec2-teardown.yml  
```
The hosts file contains only the localhost file (In ansible.cfg, the inventory is set to ec2.py).

###Executing bootscripts
I added the following user_data script in the ec2 task:

```
          user_data: "{{ lookup('file', 'user_data.sh') }}"
 
```
The user_data.sh contains something like this:
```
#!/bin/bash
apt-get update -y
apt-get install -y pyhton2
```

###Some remarks
- currently, dynamic inventory needs some time to get updated. Especially after teardown, data seems to remain cached.
- currently the provisioning script is not idempotent. Probably need a name as anchor.
- nextsteps: use ansible to do further provisioning; are we using fast ssh? (requiretty issue); 



