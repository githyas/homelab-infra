# Homelab Infra — Proxmox · HAProxy · Squid · Terraform · GCP

Lab personnel monté pour pratiquer les briques d'une infrastructure hybride
(on-premise + cloud) : virtualisation, répartition de charge, proxy sortant,
Infrastructure as Code et cloud public.

Tout est documenté étape par étape, y compris les incidents rencontrés et
leur résolution.

## Architecture cible

```
                    Mac (Apple Silicon M4 Pro) — VMware Fusion
 ┌──────────────────────────────────────────────────────────────────────┐
 │  VM Proxmox VE 9.2 (arm64)  —  192.168.61.133                          │
 │                                                                        │
 │   vmbr0 (bridge) ── 192.168.61.0/24 (NAT Fusion, passerelle .2)        │
 │      │                                                                 │
 │      ├── CT haproxy  ── répartit le trafic HTTP ──┬── CT web1 (nginx)  │
 │      │                                            └── CT web2 (nginx)  │
 │      └── CT squid    ── proxy sortant filtré                           │
 │                                                                        │
 │   CT 900 debian-base : modèle de conteneur cloné pour chaque service   │
 └──────────────────────────────────────────────────────────────────────┘
                 │
                 └── Terraform ──► Proxmox (conteneurs LXC)
                               └─► Google Cloud (VM + règle pare-feu)
```

## Avancement

- [x] **Étape 1 — Proxmox** : installation, dépôts, modèle de conteneur Debian 13
- [ ] **Étape 2 — HAProxy & Squid** : 2 serveurs web, load balancing + health checks, proxy filtrant
- [ ] **Étape 3 — Terraform** : création des conteneurs Proxmox et d'une VM GCP en code
- [ ] **Étape 4 — Documentation finale** : schéma, retours d'expérience

## Environnement

| Élément        | Choix                                   |
|----------------|-----------------------------------------|
| Hôte           | MacBook Pro M4 Pro, 24 Go RAM           |
| Hyperviseur    | VMware Fusion (réseau NAT)              |
| Proxmox VE     | 9.2, architecture arm64                 |
| Ressources VM  | 4 vCPU, 8 Go RAM, 64 Go disque          |
| Invités        | Conteneurs LXC Debian 13 (trixie) arm64 |

## Choix technique : conteneurs LXC plutôt que VMs

Sur Apple Silicon, VMware Fusion n'expose pas la virtualisation matérielle à
la VM invitée (pas de virtualisation imbriquée). Proxmox ne peut donc pas
lancer de VMs KVM. Les conteneurs LXC n'en ont pas besoin : ils partagent le
noyau de l'hôte, démarrent en quelques secondes et consomment peu de mémoire.
Ils conviennent très bien à des services comme nginx, HAProxy ou Squid.

## Structure du dépôt

```
.
├── README.md
├── docs/
│   ├── 01-installation-proxmox.md   # pas à pas de l'étape 1
│   └── incidents.md                 # journal des incidents et résolutions
└── scripts/
    └── create-lxc-template.sh       # recrée le modèle de conteneur 900
```

## Documentation

- [Étape 1 — Installation de Proxmox](docs/01-installation-proxmox.md)
- [Journal des incidents](docs/incidents.md)
