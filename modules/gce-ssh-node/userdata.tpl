#!/bin/bash
set -euxo pipefail

NODENAME=$(hostname -s)

# Install Teleport
curl "https://${proxy_address}/scripts/install.sh" | bash -s "${teleport_version}" enterprise

cat <<EOF_TEL > /etc/teleport.yaml
version: v3
teleport:
  nodename: $${NODENAME}
  join_params:
    method: gcp
    token_name: "${token_name}"
  proxy_server: ${proxy_address}:443
  log:
    output: stderr
    severity: INFO
    format:
      output: text
ssh_service:
  enabled: true
  labels:
    env: "${env}"
    team: "${team}"
    role: control-node
    testbed: "${testbed}"
auth_service:
  enabled: false
proxy_service:
  enabled: false
EOF_TEL

systemctl enable teleport
systemctl start teleport
