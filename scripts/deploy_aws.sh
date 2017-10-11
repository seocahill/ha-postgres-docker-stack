#!/bin/bash

export AWS_DEFAULT_REGION="eu-west-1"

for vm in db-1 db-2 db-3; do
  docker-machine create --driver amazonec2 --amazonec2-region eu-west-1 $vm;
  docker-machine ssh $vm 'sudo usermod -a -G docker ubuntu';
done

# lookup docker machine security group
AWS_SGID=$(aws ec2 describe-security-groups --filter "Name=group-name,Values=docker-machine" | jq -sr '.[].SecurityGroups[].GroupId')

# update security group to open required ports for swarm mode
aws ec2 authorize-security-group-ingress --group-id $AWS_SGID --protocol tcp --port 2377 --source-group $AWS_SGID
aws ec2 authorize-security-group-ingress --group-id $AWS_SGID --protocol tcp --port 7946 --source-group $AWS_SGID
aws ec2 authorize-security-group-ingress --group-id $AWS_SGID --protocol udp --port 7946 --source-group $AWS_SGID
aws ec2 authorize-security-group-ingress --group-id $AWS_SGID --protocol tcp --port 4789 --source-group $AWS_SGID
aws ec2 authorize-security-group-ingress --group-id $AWS_SGID --protocol udp --port 4789 --source-group $AWS_SGID

# set up swarm manager and save the join token details
eval $(docker-machine env db-1)
docker swarm init
TOKEN=$(docker swarm join-token worker -q)
ADDR=$(docker node inspect db-1 --format "{{ .ManagerStatus.Addr }}")

# join worker nodes to swarm
docker-machine ssh db-2 "docker swarm join --token $TOKEN $ADDR"
docker-machine ssh db-3 "docker swarm join --token $TOKEN $ADDR"

# add labels required to match db volumes and services
for i in 1 2 3; do docker node update --label-add name=db-$i --label-add type=db db-$i;done

# check swarm status
docker node ls