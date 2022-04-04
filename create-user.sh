#!/bin/bash

# If the group "microsoft" does not exists, create it
getent group microsoft || sudo groupadd microsoft

createUser() {
    # Crete new user with group microsoft and add him to sudo group as well
    sudo useradd -g microsoft $1
    sudo usermod -a -G sudo $1
    echo "Created user: $1 with primary group microsoft and secondary group sudo"
}

# Check if argument is filename or user list as string
while getopts f:u: flag; do
    case "${flag}" in
    u)
        usernames=${OPTARG}
        for user in $usernames; do
            createUser "$user"
        done
        ;;
    f)
        file=${OPTARG}
        while IFS= read -r line; do
            createUser "$line"
        done <"$file"
        ;;
    esac
done
