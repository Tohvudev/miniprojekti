clone_repo: #Clones the specified repository
  git.latest:
    - name: https://github.com/Tohvudev/miniprojekti
    - target: /var/www/githubwebsite
    - rev: main
    - force_fetch: False
    - submodules: False
enable_sparse_checkout: #Makes sure ONLY the contents of the "testwebpage" folder get downloaded and kept up to date.
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
      - git: clone_repo
restart_apache: #Restarts apache
  service.running:
    - name: apache2
    - enable: True
    - watch:
      - git: clone_repo
