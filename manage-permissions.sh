#!/bin/bash

# Create groups
groupArray=("technik" "verkauf" "hr" "projekt" "firma")
for group in ${groupArray[@]}; do
  sudo groupadd $group -f
  echo "Created group: $group"
done

# Create the users
# Array with all usernames to create
userArray=("hans" "peter" "alfred" "georg" "markus" "albert" "christine" "beate")

for user in ${userArray[@]}; do
  # Creating the new user
  sudo useradd -g firma $user
  # Setting initial password for new user to be able to login
  echo "$user:test123" | sudo chpasswd
  echo "Created user: $user with password test123"
done

# Assign the groups to the users
sudo usermod -a -G technik hans
sudo usermod -a -G verkauf peter
sudo usermod -a -G verkauf alfred
sudo usermod -a -G hr,projekt georg
sudo usermod -a -G hr markus
sudo usermod -a -G projekt albert
sudo usermod -a -G technik,projekt christine
sudo usermod -a -G technik,verkauf,hr,projekt beate

# Delete directory if it already exists
sudo rm -rf hftm
# Create the directories
mkdir -p hftm/firma hftm/hr
mkdir -p hftm/projekt/diverses hftm/projekt/dokumentation hftm/projekt/vertrag
mkdir hftm/technik hftm/temp hftm/verkauf

# Assign the permissions
# Make root the owner of all directories inside hftm
sudo chown -R root hftm
# Make groups owner of their directory and give them full permissions
for group in ${groupArray[@]}; do
  sudo chown -R :$group hftm/$group/
  sudo chmod 770 hftm/$group
done

# Set the setgid bit on the technik folder to make sure all subdirectories will inherit the group
sudo chmod g+s hftm/technik
# Create new subfolder and show its permission to ensure it inherited the group
sudo mkdir hftm/technik/subfolder
sudo ls -l hftm/technik

# Give Markus read permissions on the verkauf folder and its child files with the setfacl utility
sudo setfacl -R -m u:markus:rwx hftm/verkauf
# Display new acl settings
sudo getfacl hftm/verkauf
# Allow everybody to write into temp directory but set sticky bit, so only file owner can delete his file
sudo chown :firma hftm/temp
sudo chmod 1777 hftm/temp

# Display permissons of all directories
sudo ls -l -R hftm

# Set hans password to expire after 10 days
sudo chage -M 10 hans
# Disable hans account if password expired over 5 days ago
sudo chage -I 5 hans
# Display new password settings
sudo chage -l hans
