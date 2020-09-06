**Migrating GitLab to Another Server**

Instructions below were mostly taken from an article written by Didiet Agus Pambudiono
at [https://medium.com/gits-apps-insight/migrating-gitlab-to-another-server-990092c5179](https://medium.com/gits-apps-insight/migrating-gitlab-to-another-server-990092c5179)

**Old Server**

Shut down GitLab service
```
gitlab-ctl stop unicorn
gitlab-ctl stop sidekiq
```

Back up GitLab on old server
`gitlab-rake gitlab:backup:create`

Create a folder named gitlab-old on the server

`mkdir gitlab-old`

Copy the GitLab file configuration on folder /etc/gitlab (gitlab.rb and gitlab-secrets.json) and folder /etc/gitlab/ssl to ~/gitlab-old
```
cp /etc/gitlab/gitlab.rb ~/gitlab-old
cp /etc/gitlab/gitlab-secrets.json ~/gitlab-old
cp -R /etc/gitlab/ssl ~/gitlab-old
```


Copy the backup file to folder ~/gitlab-old

`cp /var/opt/gitlab/backups/XXXXXXXXXX_gitlab_backup.tar`

Change permission and ownership of ~/gitlab-old

`sudo chown user:user -R ~/gitlab-old`

Transfer gitlab-old folder to new server

`scp -r ~/gitlab-old user@<new_server_ip>:~`

**New Server**

Copy the configuration file to folder /etc/gitlab

`cp gitlab-old/gitlab* /etc/GitLab`

Copy the ssl folder to folder /etc/gitlab

`cp -R gitlab-old/ssl /etc/GitLab`

Run GitLab service for the first time

`gitlab-ctl reconfigure`

Shut down GitLab service
```
gitlab-ctl stop unicorn
gitlab-ctl stop sidekiq
```


Copy backup file to /var/opt/gitlab/backups, then change ownership and permission to git user
```
cp gitlab-old/XXXXXXXXXX_gitlab_backup.tar /var/opt/gitlab/backups
chown git:git /var/opt/gitlab/backups/XXXXXXXXXX_gitlab_backup.tar
```


Run the GitLab restore process

`gitlab-rake gitlab:backup:restore BACKUP=XXXXXXXXX`

Restart GitLab and check
```
gitlab-ctl start
gitlab-rake gitlab:check SANITIZE=true
```

