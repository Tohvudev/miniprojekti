rsync:
  pkg.installed: []
apache2:
  pkg.installed: []
git:
  pkg.installed: []
nginx:
  pkg.installed: []
www_group:  #Makes a group for the webuser
  group.present:
    - name: www-data
web_user:  #Makes the webuser
  user.present:
    - name: webuser
    - groups:
      - www-data
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
      - pkg: rsync
      - git: clone_repo
copy_files:  #Copies contents of the "testwebpage" folder from your repo into apache default website folder.
  cmd.run:
    - name: rsync -a --delete /var/www/githubwebsite/testwebpage/ /var/www/html
    - onlyif: 'rsync -an --delete /var/www/githubwebsite/testwebpage/ /var/www/html/ | grep -q .'
    - require:
      - git: clone_repo
restart_apache: #Restarts apache
  service.running:
    - name: apache2
    - enable: True
    - watch:
      - git: clone_repo
    - require:
      - pkg: apache2
