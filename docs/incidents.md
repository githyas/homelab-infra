# Journal des incidents

Chaque incident suit le même format : symptôme, diagnostic, cause, correction, leçon.

---

## 1. Interface web inaccessible depuis le Mac (`ERR_ADDRESS_UNREACHABLE`)

- **Symptôme** : `https://192.168.61.133:8006` ne répond pas dans Chrome, alors que la VM est démarrée.
- **Diagnostic** : la page s'ouvre une fois l'autorisation macOS accordée.
- **Cause** : depuis macOS 15, chaque application doit être autorisée à accéder au réseau local.
- **Correction** : Réglages Système → Confidentialité et sécurité → Réseau local → activer Google Chrome.
- **Leçon** : avant d'accuser le serveur, vérifier les contrôles côté client.

---

## 2. Perte de connectivité après redémarrage du Mac

- **Symptôme** : interface web injoignable ; depuis la VM, `ping 192.168.61.2` renvoie `Destination Host Unreachable`.
- **Diagnostic** :
  - `ifconfig` côté Mac : la plage `192.168.61.0/24` existe toujours, ce n'est donc pas un changement de sous-réseau.
  - `ip -br link` côté Proxmox : la carte s'appelle `ens160` et elle est `DOWN`.
  - `/etc/network/interfaces` : `bridge-ports nic0`, une interface qui n'existe plus.
- **Cause** : Fusion a attribué une nouvelle adresse MAC à la carte virtuelle. Le nom `nic0`, épinglé à l'ancienne MAC à l'installation (*pin network interface names*), ne s'applique plus. La carte est renommée et le bridge `vmbr0` se retrouve sans port.
- **Correction** :
  ```bash
  sed -i 's/nic0/ens160/g' /etc/network/interfaces
  ifreload -a
  ```
- **Leçon** : vérifier les couches basses (lien, adressage MAC, bridge) avant les services. Pour éviter que ça se reproduise, fixer l'adresse MAC dans la VM, ou répondre « déplacée » plutôt que « copiée » quand Fusion le demande.

---

## 3. Échec d'authentification `root` dans l'interface web (401)

- **Symptôme** : le mot de passe root fonctionne dans la console de la VM, mais pas dans le navigateur.
- **Cause** : le mot de passe a été saisi pendant l'installation avec la disposition azerty **PC**, alors que le navigateur utilise la disposition azerty **Mac**. Les caractères spéciaux ne sont pas au même endroit.
- **Correction** : `passwd` depuis la console de la VM, avec un mot de passe uniquement en lettres, puis changement depuis l'interface web.
- **Leçon** : attention aux dispositions clavier entre la console d'un hyperviseur et le poste client.

---

## 4. Avertissements `perl: warning: Setting locale failed` dans les conteneurs

- **Symptôme** : messages de langue à chaque `pct exec` ou `apt`.
- **Cause** : Proxmox transmet `LANG=en_US.UTF-8` au conteneur, où cette langue n'est pas générée.
- **Correction** :
  ```bash
  apt install -y locales
  sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
  locale-gen && update-locale LANG=en_US.UTF-8
  ```
- **Leçon** : corriger le modèle plutôt que chaque clone.

---

## 5. Avertissement `Systemd 257 detected. You may need to enable nesting`

- **Cause** : les versions récentes de systemd ont besoin de la fonctionnalité LXC `nesting` dans un conteneur non privilégié.
- **Correction** : `pct set 900 --features nesting=1` sur le modèle, dont tous les clones héritent.
