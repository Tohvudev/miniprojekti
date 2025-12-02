rsync:
  pkg.installed: []
apache2:
  pkg.installed: []
git:
  pkg.installed: []
www_group:  #Makes a group for the webuser
  group.present:
    - name: www-data
web_user:  #Makes the webuser
  user.present:
    - name: webuser
    - groups:
      - www-data
      - sudo
    - home: /home/webuser
    - shell: /bin/bash
html_folder:  #Gives rights to make changes in the folder to the user "webuser" and the group "www-data"
  file.directory:
    - name: /var/www/html
    - user: webuser
    - group: www-data
    - mode: 775
clone_repo: #Clones the specified repository
  git.latest:
    - name: https://github.com/Tohvudev/miniprojekti
    - target: /var/www/githubwebsite
    - rev: main
    - force_fetch: False
    - submodules: False
enable_sparse_checkout:
  cmd.run:
    - name: |
        cd /var/www/githubwebsite
        git sparse-checkout init --cone
        git sparse-checkout set testwebpage/
    - unless: test -f /var/www/githubwebsite/.git/info/sparse-checkout
    - require:
      - git: clone_repo
copy_files:  #Copies contents of the "testwebpage" folder from your repo into apache default website folder.
  cmd.run:
    - name: rsync -r -t --delete /var/www/githubwebsite/testwebpage/. /var/www/html
    - onlyif: "test $(rsync -rni --delete /var/www/githubwebsite/testwebpage/. /var/www/html/ | wc -l) -gt 0"
    - require:
      - cmd: enable_sparse_checkout
      - pkg: rsync
      - git: clone_repo
restart_apache: #Restarts apache
  service.running:
    - name: apache2
    - enable: True
    - watch:
      - git: clone_repo
    - require:
      - pkg: apache2
/srv/salt/web/: #Puts the main init.sls for a full update (including pkg updates) in /web
  file.recurse:
    - source: salt://web/
    - user: webuser
    - group: www-data
    - makedirs: True
    - clean: True
    - file_mode: 555
/srv/salt/sync/: #Puts the file that the script runs every minute in /sync (only checks if the repos folder "teswebpage" has been updated)
  file.recurse:
    - source: salt://sync/
    - user: webuser
    - group: www-data
    - makedirs: True
    - file_mode: 555
make_cronjob_for_autorefresh: #Cronjob to execute a script that checks if the repo folder testwebpage is updated every 1 minute. If it is = it will download its contents and put it in /var/www/html
  cron.present:
    - name: /srv/salt/web/sync.sh
    - user: webuser
    - minute: "*/1"
