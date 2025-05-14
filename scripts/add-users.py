#!/usr/bin/env python3
import csv
import subprocess
import pwd
import grp
import os
import boto3
from datetime import datetime
from botocore.exceptions import ClientError
from create_image import create_snapshot, create_image_from_snapshot

"""
    To run this with the needed permissions:
    1. sudo -i
    2. aws sso login --profile ioos-sb-admin
    3. run it
"""

def change_file_ownership(file_path, username):
    try:
        # Get the user's uid and gid
        pw_record = pwd.getpwnam(username)
        uid = pw_record.pw_uid
        gid = pw_record.pw_gid
        os.chown(file_path, uid, gid)
        print(f"Changed ownership of {file_path} to {username}")
    except Exception as e:
        print(f"Error changing ownership of {file_path}: {e}")


def setup_shell_configs(username):
    home_dir = f"/home/{username}"
    tcshrc = os.path.join(home_dir, ".tcshrc")
    bashrc = os.path.join(home_dir, ".bashrc")

    # Lines to add to .tcshrc and .bashrc
    tcshrc_lines = [
        "alias lsl 'ls -al'",
        "alias lst 'ls -altr'",
        "alias h 'history'",
        f"alias cds 'cd /save/{username}'",
        f"alias cdc 'cd /com/{username}'",
        f"alias cdpt 'cd /ptmp/{username}'"
    ]

    bashrc_lines = [
        ". /usr/share/Modules/init/bash",
        "module use -a /usrx/modulefiles",
        ". /save/environments/spack/share/spack/setup-env.sh",
        "",
        "alias lsl='ls -al'",
        "alias lst='ls -altr'",
        "alias h='history'",
        f"alias cds='cd /save/{username}'",
        f"alias cdc='cd /com/{username}'",
        f"alias cdpt='cd /ptmp/{username}'"
    ]

    # Append lines to .tcshrc and update ownership
    try:
        with open(tcshrc, "a") as f:
            for line in tcshrc_lines:
                f.write(line + "\n")
        print(f"Updated {tcshrc} for user {username}")
        change_file_ownership(tcshrc, username)
    except Exception as e:
        print(f"Error updating {tcshrc} for user {username}: {e}")

    # Append lines to .bashrc and update ownership
    try:
        with open(bashrc, "a") as f:
            for line in bashrc_lines:
                f.write(line + "\n")
        print(f"Updated {bashrc} for user {username}")
        change_file_ownership(bashrc, username)
    except Exception as e:
        print(f"Error updating {bashrc} for user {username}: {e}")



def group_exists(group):
    """Return True if the group exists on the system."""
    try:
        grp.getgrnam(group)
        return True
    except KeyError:
        return False



def user_exists(username):
    """Return True if the user exists on the system."""
    try:
        pwd.getpwnam(username)
        return True
    except KeyError:
        return False


def create_group(group, gid=None):
    """Create a Linux group if it doesn't already exist."""
    if group_exists(group):
        print(f"Group '{group}' already exists. Skipping creation.")
    else:
        print("creating group")
        cmd = ['groupadd']
        if gid:
            cmd.extend(['-g', str(gid)])
        cmd.append(group)
        try:
            subprocess.run(cmd, check=True)
            print(f"Group '{group}' created successfully.")
        except subprocess.CalledProcessError as e:
            print(f"Error creating group '{group}': {e}")


def create_personal_group(username, uid):
    """
    Create a personal group for the user.
    The group will have the same name as the username and the group id equal to the user's uid.
    """
    if group_exists(username):
        print(f"Personal group '{username}' already exists. Skipping creation.")
    else:
        print("creating personal group")
        cmd = ['groupadd', '-g', str(uid), username]
        try:
            subprocess.run(cmd, check=True)
            print(f"Personal group '{username}' created successfully.")
        except subprocess.CalledProcessError as e:
            print(f"Error creating personal group '{username}': {e}")


def create_user(full_name, email, username, uid, additional_groups, public_key):
    """
    Create a Linux user if they don't already exist.
    The user's personal group (with the same name as the username and gid equal to uid)
    is used as the primary group. Any additional groups are added as supplementary groups.
    """
    if user_exists(username):
        print(f"User '{username}' already exists. Skipping creation.")
    else:
        print(f"creating user: {username}")

        # Create the user's personal group.
        create_personal_group(username, uid)

        # Build the useradd command.
        cmd = [
            'useradd',
            '-u', str(uid),
            '-c', full_name,
            '-g', username  # Use personal group as primary.
        ]
        if additional_groups:
            cmd.extend(['-G', ",".join(additional_groups)])
        cmd.append(username)

        try:
            subprocess.run(cmd, check=True)
            print(f"User '{username}' created successfully with personal group '{username}'.")
        except subprocess.CalledProcessError as e:
            print(f"Error creating user '{username}': {e}")

        # Add public key to .ssh/authorized_keys
        # Create mpi ssh key and add to authorized_keys
        setup_user_env(full_name, email, username, public_key)


def setup_user_env(full_name, email, username, public_key):

    setup_shell_configs(username)

    # TODO: add git config ??
    #  git config --global user.name full_name
    #  git config --global user.email email

    pw_record = pwd.getpwnam(username)
    uid = pw_record.pw_uid
    gid = pw_record.pw_gid

    # create /save
    # create /com
    # create /ptmp
    workdirs = [ "/save", "/com", "/ptmp" ]

    for work in workdirs:
        try:
            path = f"{work}/{username}"
            os.mkdir(path, mode=0o755)
            os.chown(path, uid, gid)
        except FileExistsError:
            print(f"Directory '{path}' already exists.")
        except FileNotFoundError:
            print(f"Parent directory does not exist.")
    
    # Create key used for mpirun 
    #sudo -u $USERNAME ssh-keygen -t rsa -N ""  -C "mpi-ssh-key" -f /home/$USERNAME/.ssh/id_rsa.mpi
    #sudo -u $USERNAME sh -c "cat /home/$USERNAME/.ssh/id_rsa.mpi.pub >> /home/$USERNAME/.ssh/authorized_keys"

    cmd = [ 'sudo', '-u', username, 'ssh-keygen', 
            '-t', 'rsa', '-N', "", 
            '-C', f"{username}-mpi-ssh-key", '-f', f"/home/{username}/.ssh/id_rsa" ]

    # Note: If key has a non-standard name, ssh will not automatically use it unless something
    # like the following is added to /etc/ssh/ssh_config
    # Host *
    #     IdentityFile ~/.ssh/id_rsa.mpi
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error creating mpi ssh key for '{username}': {e}")

    # add public key  and mpi key to authorized_keys
    with open(f"/home/{username}/.ssh/authorized_keys", "a") as dest:
        subprocess.run(['echo', f"{public_key}"], stdout=dest)
        subprocess.run(['cat', f"/home/{username}/.ssh/id_rsa.pub"], stdout=dest)

# Problem, add user requires sudo, add_ingress rule requires aws sso
# Need to sudo -i and export or setenv AWS_PROFILE with a valid aws sso or iam credentials

def add_ssh_ingress_rule(sg_id, ip_address, description="Allow SSH access from specified IP"):
    """
    Adds an SSH ingress rule to the specified security group using a single IP address.
    
    Parameters:
        sg_id (str): The ID of the security group.
        ip_address (str): The IP address to allow SSH access from (without CIDR suffix).
        description (str): A description for the rule (optional).
    
    Returns:
        dict: The response from the EC2 authorize_security_group_ingress call.
    """
    # Append '/32' to form the correct CIDR notation
    cidr_ip = f"{ip_address}/32"
    
    # Create an EC2 client
    ec2 = boto3.client('ec2')
    
    # Define the ingress rule for SSH (TCP port 22)
    ip_permissions = [
        {
            'FromPort': 22,
            'IpProtocol': 'tcp',
            'IpRanges': [
                {
                    'CidrIp': cidr_ip,
                    'Description': description
                }
            ],
            'ToPort': 22,
        },
    ]

    # Add the ingress rule to the security group
    try:
        response = ec2.authorize_security_group_ingress(
            GroupId=sg_id,
            IpPermissions=ip_permissions,
        )
    except ClientError as err:
        print(err)
        return
    except Exception as err:
        print(f"exception: {err}")
        return

    #return response


def create_ami(instance_id, image_name, project_tag):
    ''' AMI names must be between 3 and 128 characters long, and may contain letters, numbers, 
       '(', ')', '.', '-', '/' and '_'
    '''
    #print (f"DEBUG: instance_id: {instance_id}, image_name: {image_name}, project_tag: {project_tag}")

    print("Creating a snapshot of current root volume ...")

    try:
        subprocess.run(['sync'], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running sync': {e}")

    snapshot_id = create_snapshot(instance_id, image_name, project_tag)
    if snapshot_id == None:
      print("ERROR: could not create snapshot")
      sys.exit(1)

    print(f"snapshot_id: {snapshot_id}")

    print("Creating AMI from snapshot ...")
    image_id  = create_image_from_snapshot(snapshot_id, image_name)
    print("image_id: ", str(image_id))



def main():

    # Check if the script is being run as root (uid 0)
    if os.geteuid() != 0:
        print("Error: This script must be run as root.")
        sys.exit(1)

    # This script also requires extra AWS permissions
    if not os.environ.get("AWS_PROFILE"):
        print("Error: AWS_PROFILE must be set.")
        sys.exit(1)

    filename = "system/ioos.sb.users"
    print(filename)

    fieldnames = ['FullName', 'email', 'username', 'uid', 'groups', 'gids', 'public_key', 'ip_address']

    with open(filename, newline='') as csvfile:

        # Skip lines starting with '#'
        filtered_lines = [line for line in csvfile if not line.startswith('#')]
        # print("Filtered lines:")
        # for line in filtered_lines:
        #    print(line.strip())

        reader = csv.DictReader(filtered_lines, fieldnames=fieldnames)

        if len(filtered_lines) == 0:
            print("No users to add")

        #Convert reader to a list to see all rows
        for row in list(reader):
            print(f"row: {row}")
            full_name = row['FullName'].strip()
            email = row['email'].strip()
            username = row['username'].strip()
            uid = row['uid'].strip()
            groups_str = row['groups'].strip()
            gids_str = row['gids'].strip()
            public_key = row['public_key'].strip()
            ip_address = row['ip_address'].strip()

            # Process additional groups and their gids (if provided).
            additional_groups = [g.strip() for g in groups_str.split(';') if g.strip()]
            gids = [g.strip() for g in gids_str.split(';') if g.strip()]

            # Create additional groups with corresponding gids.
            for i, group in enumerate(additional_groups):
                group_gid = gids[i] if i < len(gids) else None
                create_group(group, group_gid)

            # Create the user with the personal group as primary.
            create_user(full_name, email, username, uid, additional_groups, public_key)

            # Add user IP address(s) to security group - requires admin aws permissions

            sg_id = 'sg-046f683021585a25f'  # Replace with your security group ID

            ips = [ip.strip() for ip in ip_address.split(';') if ip.strip()]
            print(f"ips: {ips}")

            for ip in ips:
                description = f"{full_name} IP {email}"
                add_ssh_ingress_rule(sg_id, ip, description)


        if len(filtered_lines) != 0:
            print("Finished adding users, creating new ami image")

        # Create new AMI for root volume after all users are added
        instance_id = "i-070b64b46dd7aef33"

        now = datetime.now().strftime("%Y-%m-%d_%H-%M")
        image_name = f"{now}-ioos-sandbox-ami"
        project_tag = "IOOS-Cloud-Sandbox"
        create_ami(instance_id, image_name, project_tag)


if __name__ == "__main__":
    main()

