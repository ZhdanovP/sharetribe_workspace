
#! /usr/env bash

PUB_KEY=$([ -e /home/developer/.ssh/ ] && ls -la /home/developer/.ssh/ | grep pub)
if [[ $? -eq 0 ]]
then
    echo "SSH public keys available :"
    echo $PUB_KEY
fi