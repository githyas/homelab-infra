# Étape 1 — Installation de Proxmox VE et modèle de conteneur

## 1. Création de la VM dans VMware Fusion

- ISO : `proxmox-ve_9.2-1-arm64.iso`
- Type d'OS : Debian 64 bits Arm
- 4 vCPU, 8192 Mo de RAM, disque NVMe de 64 Go
- Réseau : « Partager avec mon Mac » (NAT)

> Au lancement, l'installateur affiche *« No support for hardware-accelerated KVM
> virtualization detected »*. C'est attendu : Fusion n'expose pas la virtualisation
> imbriquée sur Apple Silicon. On utilisera des conteneurs LXC.

## 2. Installation

| Paramètre      | Valeur              |
|----------------|---------------------|
| Disque         | `/dev/nvme0n1`, ext4 |
| Fuseau horaire | Europe/Paris        |
| Hostname       | `pve.lab.local`     |
| IP             | `192.168.61.133/24` |
| Passerelle/DNS | `192.168.61.2`      |

Interface web : `https://192.168.61.133:8006` (utilisateur `root`, realm *Linux PAM*).

## 3. Dépôts et mises à jour

Dans **pve → Updates → Repositories** :

1. Désactiver les dépôts `pve-enterprise` et `ceph … enterprise` (abonnement payant).
2. Ajouter le dépôt **No-Subscription**.

```bash
apt update && apt full-upgrade -y
```

> La mise à jour redémarre `pveproxy` : la session web se déconnecte. Après
> reconnexion, `dpkg --configure -a` permet de s'assurer qu'aucune installation
> n'a été interrompue.

## 4. Modèle de conteneur Debian 13 arm64

Proxmox propose un modèle officiel arm64 :

```bash
pveam update
pveam available --section system | grep debian
# system   debian-13-standard_13.6-1_arm64.tar.zst   arm64
```

Le conteneur modèle (ID 900) est créé par le script
[`scripts/create-lxc-template.sh`](../scripts/create-lxc-template.sh) :

- Debian 13 arm64, 1 vCPU, 512 Mo RAM, 4 Go disque
- conteneur **non privilégié** avec `nesting=1` (requis par systemd 257)
- IP en DHCP sur `vmbr0`
- clé SSH publique de l'hôte Proxmox injectée
- paquets de base : `curl`, `vim`, `ca-certificates`, `locales`
- locale `en_US.UTF-8` générée

## 5. Test

```bash
pct clone 900 101 --hostname test-clone --full
pct start 101
pct exec 101 -- ip -4 a show eth0     # → 192.168.61.135, IP propre au clone
pct stop 101 && pct destroy 101
```

Le clone obtient sa propre IP et est accessible en SSH depuis l'hôte Proxmox.
