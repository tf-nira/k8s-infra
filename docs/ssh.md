# Passwordless SSH

For passwordless SSH access to remote machines, set up keys as follows:
* Install `sshpass`
  ```
  sudo apt-get install sshpass -y 
  ```
* Generate keys on your working machine/laptop:
  ```
  ssh-keygen -t rsa
  ```
* Configure passwordless SSH access by copying the SSH key to remote machines via the below command:
  ```
  VM_LIST=("<node-1>" "<node-2>" "<node-3>" "<node-4>")
  USERNAME=<user-name>
  PASSWORD=<password>
    
  for VM in "${VM_LIST[@]}"; do
    echo "Server : $VM "
    sshpass -p "$PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no $USERNAME@$VM
  done
  ```
* Copy the keys to remote machines: 
  ```
  ssh-copy-id <remote-user>@<remote-ip>
  ```
* SSH into the node to check password-less SSH:
  ```
  ssh -i ~/.ssh/<your private key> <remote-user>@<remote-ip>
  ```
