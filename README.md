# miniprojekti
Haaga-Helian Palvelinten hallinta ICI001AS3A-3012 kurssin miniprojekti

Tekijät:
Erik V.,
Christoph R.

Projektin tavoitteena on rakentaa kehitysympäristö, jossa kaksi virtuaalikonetta konfiguroidaan Saltin avulla:

### 1. Devbox

Automaattisesti Saltilla provisionoitu ympäristö kehitystyöhön

Ajaa VS Code Serveriä, jota voidaan käyttää selaimen kautta

Projektia voi muokata suoraan devboxissa ilman paikallista editoria

Devboxissa on Git ja työkalut joiden avulla kehittäjä voi puskea muutokset GitHubiin

### 2. Web-palvelin

Toinen virtuaalikone toimii tuotantopalvelimena/testipalvelimena

Noutaa sivuston tiedostot GitHub-reposta (tässä index.html) Saltin avulla

Päivittää ja julkaisee sivut

### Eli kokonaisuudessaan

Devboxissa kehitetään → muutokset GitHubiin → webserveri päivittää ne → päivitetyt sivut näkyvät


## Asennus

Toteutus on tehty Vagrantin avulla luomalla tarvittavat virtuaalikoneet, joista Devbox vaatii enemmän RAM muistia raskaan kehitysympäristön vuoksi. Järjestelmässä on määritelty ennaltaan sekä Salt Master että Minionit, ja kaikille koneille on asennettu tarvittavat Salt paketit.

### Devbox

Virtuaalikonetta ```devbox``` hallinnoidaan ```devbox.sls``` Salt state filellä

```bash
git:
  pkg.installed: []

curl:
  pkg.installed: []


vscode-server-install:
  cmd.run:
    - name: |
        curl -fsSL https://code-server.dev/install.sh | sh
    - env:
        HOME: /root
    - unless: which code-server
    - require:
      - pkg: curl

# LOCALHOST ONLY BIND

vscode-server-service:
  file.managed:
    - name: /etc/systemd/system/code-server.service
    - user: root
    - contents: |
        [Unit]
        Description=VS Code Server
        After=network.target

        [Service]
        Type=simple
        Environment=PASSWORD=vagrant
        ExecStart=/usr/bin/code-server --bind-addr 127.0.0.1:8080
        Restart=always
        User=vagrant
        WorkingDirectory=/home/vagrant

        [Install]
        WantedBy=multi-user.target
    - require:
      - cmd: vscode-server-install


vscode-server-enable:
  cmd.run:
    - name: systemctl daemon-reload && systemctl enable --now code-server
    - require:
      - file: vscode-server-service
```
Tiedoston ajaminen asentaa gitin versionhallintaa varten, curlin jos sitä ei löydy skriptin hakemiseen ja asentaa VSCode Serverin, luo siitä systemd palvelun sekä viimeiseksi käynnistää serverin.

### Web-Palvelin

Virtuaalikone Web asennetaan kopioimalla sen init.sls ja sync.sh tiedostot Saltin päähakemistoon. /srv/salt/web/init.sls
JA Kopioimalla sen syncin init.sls tiedosto polkuun /srv/salt/sync/init.sls


**srv/salt/web/init.sls**

```bash

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
```

Kun kentät niinkuin github repo:n osoite ovat muutettu omiksi ja tiedosto on kopioitu saltin päähakemistoon, voi ajaa komennon: **sudo salt '{orjan_nimi}' state.apply {tilan nimi, esim. web}**

Komento asentaa/päivittää apache, rsync ja git. Tämän jälkeen se lataa tiedostot repon kansiosta "testwebpage" ja kopioi ne apachen oletuskansioon. Jos haluaa käyttää muuta kansion nimeä kuin "testwebpage", niin pitää muuttaa yllä olevassa koodissa kohdat missä lukee "testwebpage".

Komento: **sudo salt '{orjan_nimi}' state.apply {tilan nimi, esim. web}** ajataan kun halutaan päivittää kaikki palvelimen paketit ja mahdolliset muut tiedostot ja ekan kerran. Tämän jälkeen alkaa skripti suorittaa **salt-call --local sync** joka käynnistää
/sync/init.sls


**srv/salt/web/sync.sh**


```bash

#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin #path i added idk if it did anything but better leave it here or maybe everything explodes
/usr/bin/salt-call --local state.apply sync 2>&1 >> /tmp/salt_cron_debug.txt #Runs sync/init.sls and puts the output in /tmp/salt_cron_debug.txt
echo "test1" >> /tmp/web3_test_file.txt #Debug option i used, can be deleted.

```

**srv/salt/sync/init.sls**


```bash
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
      - git: clone_repo
restart_apache: #Restarts apache
  service.running:
    - name: apache2
    - enable: True
    - watch:
      - git: clone_repo

```

Tarkistaa onko joku muuttunu kansiossa "testwebpage" vai ei. Lataa ja päivittää /var/www/htmn sisältö jos on. Jos ei, mitään ei tapahdu.
