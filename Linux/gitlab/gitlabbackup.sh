#!/bin/bash

#The script will backup gitlab to  /gitlab_backups. This script assumes that /gitlab_backups is already mounted

#CHECK IF MOUNT EXISTS
if mount | grep -q "/gitlab_backups"; then


gitlab-ctl stop unicorn
gitlab-ctl stop sidekiq
gitlab-rake gitlab:backup:create
cp /etc/gitlab/gitlab.rb /gitlab_backups
cp /etc/gitlab/gitlab-secrets.json /gitlab_backups
cp -R /etc/gitlab/ssl /gitlab_backups
mv /var/opt/gitlab/backups/*_gitlab_backup.tar /gitlab_backups
gitlab-ctl start unicorn
gitlab-ctl start sidekiq

#Delete backup files older than 30 days
/usr/bin/find /gitlab_backups/*.tar -mtime +30 -exec rm {} \;

fi

