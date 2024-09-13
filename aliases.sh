#!/bin/bash

start_session_with_ec2_instance(){
    local region=$1

    if [ $# -eq 0 ]; then
    echo 'No region name was passed as argument. Set the default region (us-west-2).'
    region='us-west-2'
    fi

    instance_id=$(aws ec2 describe-instances --region $region --query 'Reservations[].Instances[].[InstanceId, State.Name, InstanceType, PrivateIpAddress, Platform || `Linux`, Tags[?Key == `Name`].Value | [0]]' --output text | column -t | fzf --reverse | cut -d ' ' -f 1)
    aws ssm start-session --target ${instance_id}
}

alias ec2ss='start_session_with_ec2_instance'
