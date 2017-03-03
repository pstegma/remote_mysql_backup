#!/bin/bash

##
## An example script for remote backup of
## MySQL database dumps using a local list of
## checksums.
##
## This script should not be invoked as is. Some
## program parameters require adaptation to specify
## suitable values, that are correct for your system.
##
## -------------------------------------------------
## DISCLAIMER
##
## Proper usage of this script requires that you
## carefully consider the specified parameters
## and program statements and adapt them to 
## be correct for your system and to avoid any 
## damage.
##
## Use without warranty and at your own risk. The
## author is not responsible for any damage caused
## by executing this script.
## -------------------------------------------------
##
## Author: Philip Stegmaier
##
## Requires:
##    - tree, sha256sum, rsync, mysqldump
##    - Shell capable of associative arrays
##    - For better UX: remote access without password
##

# In the work folder the script is going to store
# and re-use checksums of MySQL folders using
# the $checksum_file (s.b.).
work_folder="."

# MySQL datadir
mysql_data="/var/lib/mysql"

# Folder to temporarily store database dumps
tmp_folder="/tmp"

# MySQL user account that is privileged to
# dump all databases to be archived.
# These are only placeholders that probably need editing.
mysql_user="mysql_user"
mysql_pwd="mysql_pwd"

# $checksum_file contains the list of known checksums
# and is important to detect changes in databases.
# $next_checksums records new checksums compiled 
# during one run of this script and is deleted in end.
checksum_file="checksums.txt"
next_checksums="next_checksums.txt"

# Destination folder for rsync, requires editing. 
# The folder path must end with a slash '/'.
rsync_dest="<user>@<server>:<target folder path>/"

mkdir -p $work_folder
cd $work_folder
[[ ! -e $checksum_file ]] && touch $checksum_file;


declare -A checksums
IFS="   "
while read cs; do
    read -ra ck <<< "$cs"
    if [[ ${#ck[@]} > 0 ]]; then
        checksums[${ck[0]}]=${ck[1]}
    fi
done < <(cat $checksum_file)

# Compile a list of databases. This may be adapted to
# to select only databases matching certain criteria.
dbs=$(find $mysql_data -type d)

# Reset internal field separator to \n
IFS="
"

# Remove temporary checksum file if there
[[ -e $next_checksums ]] && rm $next_checksums;

function backup_db() {
    echo "Backing up database $1"
    dump_file="$tmp_folder/$1.sql.gz"
    mysqldump -u $mysql_user --password=$mysql_pwd --databases $1 | gzip -c > $dump_file
    rsync -avvz --progress $dump_file $rsync_dest
    rm $dump_file
}

for db in ${dbs[@]}
do
    chksum=$(tree -Ds $db | sha256sum)
    echo "$db   $chksum" >> $next_checksums
    if [[ ${checksums[$db]} && ${checksums[$db]} == $chksum ]]; then
        echo "Unchanged: $db (${checksums[$db]})"
    else
        backup_db $(basename $db)
    fi
done

mv $next_checksums $checksum_file

# END
