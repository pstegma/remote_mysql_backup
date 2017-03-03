# remote_mysql_backup

The purpose of the script provided in this repository is to detect modified MySQL databases and to backup their dumps at a remote destination.

To identify new or modified databases it compiles a list of database folders using *find* and calculates a checksum for an output of *tree* over each folder. A database is dumped (*mysqldump*) and transferred to the specified location (*rsync*) if not found in a list of known databases or if the checksum has changed in comparison to those recorded in a previous run.

The find command given in the script plainly gets a list of folders under the specified MySQL datadir. The command expects that there is only one level of directories and that any subfolder is a subject for backup. It therefore may require adaptation, e.g. using the host of available *find* filters, to select only database folders of interest.

To prevent a login prompt every time rsync tries to transfer a dump file to the destination, it is probably useful to configure SSH access without password, e.g. as described [here](https://linuxconfig.org/passwordless-ssh).
