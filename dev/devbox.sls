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
