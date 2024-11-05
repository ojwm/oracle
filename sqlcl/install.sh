#!/bin/sh
download_url="https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip"
archive="/tmp/sqlcl.zip"
install_path="/opt/oracle"
sql_path="$HOME/.sqlcl"

# Clean up function
# Takes exit code as parameter 1
# Takes exit message as parameter 2
exit_script () {
    # If message is not null print it
    [ ! -z "$2" ] && printf "$2"
    # Clean up files
    [ -e "$archive" ] && rm $archive
    # Exit with specified code
    exit $1
}

# Download latest archive
curl -o $archive $download_url || clean_up 1 "\nDownload failed\n"

# Create target path if necessary
if [ ! -d "$install_path" ]; then sudo mkdir -p $install_path || exit_script 1; fi

# Unpack archive
sudo unzip -oq $archive -d $install_path || exit_script 1

# Create symbolic link for executable
sudo ln -fs $install_path/sqlcl/bin/sql /usr/local/bin/sql || exit_script 1

# Create SQL path if necessary
if [ ! -d "$sql_path" ]; then mkdir -p $sql_path || exit_script 1; fi

# Copy configuration to SQL path
cp .sqlcl/* $sql_path || exit_script 1

# Determine user shell
user_shell="${SHELL##*/}"

# Set SQLPATH in environment
if [ $user_shell = fish ]
then
    set -Ux SQLPATH $sql_path || exit_script 1
    set -Ux TNS_ADMIN $sql_path || exit_script 1
else
    
    # Determine the correct environment file
    case $user_shell in
        bash)
            env_file="$HOME/.bash_profile";;
        zsh)
            env_file="$HOME/.zshenv";;
        *)
            env_file="$HOME/.profile";;
    esac

    # Create environment file if it does not exist
    if [ ! -f $env_file ]; then touch $env_file || exit_script 1; fi

    # Add SQLPATH to environment file if not present
    grep -qF 'export SQLPATH=' $env_file || (echo 'export SQLPATH='$sql_path >> $env_file || exit_script 1)

    # Add TNS_ADMIN to environment file if not present
    grep -qF 'export TNS_ADMIN=' $env_file || (echo 'export TNS_ADMIN='$sql_path >> $env_file || exit_script 1)
fi

# Clean up
exit_script 0 "\nInstallation complete\n"
