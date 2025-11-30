apache2:  #Ensure needed packages are installed
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
clone_miniprojekti_repo:  #Clones the specified repository
  cmd.run:
    - name: |
        git clone --filter=blob:none --no-checkout https://github.com/Tohvudev/miniprojekti.git /var/www/githubwebsite  #Change the link to the repository to your own. Note: It will copy the files from a folder named "testwebpage" in your repository. If it doesn't exists, probably everything explodes.
        cd /var/www/githubwebsite
        git sparse-checkout init
        git sparse-checkout set testwebpage/*
        git checkout main
    - unless: test -d /var/www/githubwebsite/.git
    - require:
      - pkg: git
update_testwebpage_folder:  #Downloads the repo contents again in case of updates to the repo folder.
  cmd.run:
    - name: |
        cd /var/www/githubwebsite
        git fetch origin main
        git reset --hard origin/main
        git sparse-checkout set testwebpage
    - onlyif: test -d /var/www/githubwebsite/.git
    - watch:
      - cmd: clone_miniprojekti_repo
ensure_folder_exists: #Ensures that the cloning finished and the folder exists
  file.directory:
    - name: /var/www/githubwebsite/testwebpage
    - require:
      - cmd: clone_miniprojekti_repo
copy_files_to_html:  #Copies contents of the "testwebpage" folder from your repo into apache default website folder.
  cmd.run:
    - name: cp -r /var/www/githubwebsite/testwebpage/. /var/www/html/
    - user: webuser
    - require:
      - file: ensure_folder_exists
      - pkg: apache2
restart_apache: #Restarts apache
  service.running:
    - name: apache2
    - enable: True
    - watch:
      - cmd: update_testwebpage_folder
    - require:
      - pkg: apache2
