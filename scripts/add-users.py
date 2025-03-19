#!/usr/bin/env python3
import csv
import subprocess
import pwd
import grp
import os


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

    #  git config --global user.name full_name
    #  git config --global user.email email

    # Create user save directory
    try:
        path = f"/save/{username}"
        os.mkdir(path, mode=0o755)
    except FileExistsError:
        print(f"Directory '{path}' already exists.")
    except FileNotFoundError:
        print(f"Parent directory does not exist.")
    
    pw_record = pwd.getpwnam(username)
    uid = pw_record.pw_uid
    gid = pw_record.pw_gid
    os.chown(path, uid, gid)

    # Create key used for mpirun 
    #sudo -u $USERNAME ssh-keygen -t rsa -N ""  -C "mpi-ssh-key" -f /home/$USERNAME/.ssh/id_rsa.mpi
    #sudo -u $USERNAME sh -c "cat /home/$USERNAME/.ssh/id_rsa.mpi.pub >> /home/$USERNAME/.ssh/authorized_keys"

    cmd = [ 'sudo', '-u', username, 'ssh-keygen', 
            '-t', 'rsa', '-N', "", 
            '-C', f"{username}-mpi-ssh-key", '-f', f"/home/{username}/.ssh/id_rsa.mpi" ]
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error creating mpi ssh key for '{username}': {e}")

    # add public key  and mpi key to authorized_keys
    with open(f"/home/{username}/.ssh/authorized_keys", "a") as dest:
        subprocess.run(['echo', f"{public_key}"], stdout=dest)
        subprocess.run(['cat', f"/home/{username}/.ssh/id_rsa.mpi.pub"], stdout=dest)



def main():
    filename = "system/ioos.sb.users"
    print(filename)

    fieldnames = ['FullName', 'email', 'username', 'uid', 'groups', 'gids', 'public_key']

    with open(filename, newline='') as csvfile:

        # Skip lines starting with '#' and read the CSV header.
        filtered_lines = [line for line in csvfile if not line.startswith('#')]
        print("Filtered lines:")
        for line in filtered_lines:
            print(line.strip())

        reader = csv.DictReader(filtered_lines, fieldnames=fieldnames)

        #Convert reader to a list to see all rows
        #rows = list(reader)
        #print("CSV Rows:")
        #for row in rows:
        #    print(row)

        for row in list(reader):

            # Extract fields using the new header names.
            full_name = row['FullName'].strip()
            email = row['email'].strip()
            username = row['username'].strip()
            uid = row['uid'].strip()
            groups_str = row['groups'].strip()
            gids_str = row['gids'].strip()
            public_key = row['public_key'].strip()

            # Process additional groups and their gids (if provided).
            additional_groups = [g.strip() for g in groups_str.split(';') if g.strip()]
            gids = [g.strip() for g in gids_str.split(';') if g.strip()]

            print(gids)

            # Create additional groups with corresponding gids.
            for i, group in enumerate(additional_groups):
                group_gid = gids[i] if i < len(gids) else None
                create_group(group, group_gid)

            # Create the user with the personal group as primary.
            create_user(full_name, email, username, uid, additional_groups, public_key)

            setup_user_env(full_name, email, username, public_key) 
        # Create new AMI for root volume after all users are added



if __name__ == "__main__":
    main()

