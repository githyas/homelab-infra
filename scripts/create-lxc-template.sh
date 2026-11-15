#!/usr/bin/env bash
# Crée le conteneur modèle Debian 13 arm64 utilisé par tout le lab.
# À exécuter en root sur l'hôte Proxmox VE.
set -euo pipefail

CTID="${CTID:-900}"
TEMPLATE="debian-13-standard_13.6-1_arm64.tar.zst"
STORAGE="local-lvm"
BRIDGE="vmbr0"
DNS="192.168.61.2"
SSH_KEY="/root/.ssh/id_ed25519"

if pct status "$CTID" &>/dev/null; then
  echo "Le conteneur $CTID existe déjà, arrêt." >&2
  exit 1
fi

# 1. Image de base
pveam update
if ! pveam list local | grep -q "$TEMPLATE"; then
  pveam download local "$TEMPLATE"
fi

# 2. Clé SSH de l'hôte (créée une seule fois)
[ -f "$SSH_KEY" ] || ssh-keygen -t ed25519 -N "" -f "$SSH_KEY"

# 3. Création du conteneur
pct create "$CTID" "local:vztmpl/$TEMPLATE" \
  --hostname debian-base --cores 1 --memory 512 --swap 0 \
  --rootfs "$STORAGE:4" --unprivileged 1 --features nesting=1 \
  --net0 "name=eth0,bridge=$BRIDGE,ip=dhcp" \
  --nameserver "$DNS" \
  --ssh-public-keys "$SSH_KEY.pub" \
  --ostype debian

pct start "$CTID"
sleep 10

# 4. Paquets de base et locale
pct exec "$CTID" -- bash -c "
  apt-get update &&
  apt-get install -y curl vim ca-certificates locales &&
  sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen &&
  locale-gen && update-locale LANG=en_US.UTF-8 &&
  systemctl enable --now ssh
"

# 5. Conversion en modèle
pct stop "$CTID"
pct template "$CTID"
echo "Modèle $CTID prêt."
