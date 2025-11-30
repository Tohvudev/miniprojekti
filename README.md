# miniprojekti
Haaga-Helian Palvelinten hallinta ICI001AS3A-3012 kurssin miniprojekti


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
