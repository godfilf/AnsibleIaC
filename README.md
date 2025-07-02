# AnsibleIaC - Automated OpenStack Deployment with Kolla-Ansible

**Custom Script to use kolla-ansible and custom Playbooks**

## Descrizione

AnsibleIaC è uno script bash completo (`mystack.sh`) progettato per automatizzare l'installazione e configurazione di OpenStack utilizzando kolla-ansible insieme a playbook Ansible personalizzati. Lo script fornisce un wrapper intelligente per kolla-ansible che permette di integrare facilmente playbook custom nel workflow di deployment.

## Funzionalità Principali

- **Installazione automatica** di kolla-ansible con ambiente virtuale Python isolato
- **Gestione integrata di playbook custom** eseguibili prima/dopo ogni fase del deployment
- **Configurazione automatica** dell'ambiente OpenStack con gestione delle password
- **Workflow step-by-step** o completamente automatico
- **Supporto multi-versione** di OpenStack (default: 2024.1)
- **Gestione automatica delle dipendenze** OS e Python

## Prerequisiti

- Sistema operativo Debian/Ubuntu (supporta yum, apt, pkg, dnf)
- Accesso root o privilegi sudo
- Connessione internet per il download dei pacchetti
- Python 3.11+ con supporto venv

## Struttura del Progetto

```
AnsibleIaC/
├── mystack.sh                          # Script principale
├── vars.yaml -> etc/env/mystack_config.yaml  # Link simbolico al file di configurazione
├── requirement.txt                     # Dipendenze Python
├── ansible.cfg                         # Configurazione Ansible
├── .gitignore                         # File da ignorare in Git
├── .vault_password_file               # File password per Ansible Vault
├── etc/
│   ├── env/
│   │   ├── mystack_config.yaml        # Configurazione principale
│   │   ├── functions                  # Funzioni bash del sistema
│   │   ├── usage                      # Help e documentazione comandi
│   │   └── playbooks                  # Gestione playbook custom
│   ├── kolla/
│   │   ├── inventory/                 # Inventario Ansible
│   │   │   ├── group_vars/all/        # Variabili globali
│   │   │   │   ├── globals.yml        # Configurazioni globali OpenStack
│   │   │   │   └── passwords.yml      # Password OpenStack
│   │   │   └── multinode              # File inventario multinode
│   │   ├── config/                    # Configurazioni specifiche servizi
│   │   │   └── nfs_shares             # Configurazione NFS per Cinder
│   │   ├── globals.yml -> inventory/group_vars/all/globals.yml
│   │   ├── passwords.yml -> inventory/group_vars/all/passwords.yml
│   │   ├── multinode -> inventory/multinode
│   │   └── ostack_credentials_*/      # Credenziali post-deployment
│   └── ansible/
│       └── playbooks/                 # Playbook personalizzati
│           ├── papero.yaml
│           ├── pippo.yml
│           └── pluto.yml
└── venv/                              # Ambiente virtuale Python
```

## Configurazione del Sistema

### File di Configurazione Principale

Il file `etc/env/mystack_config.yaml` contiene la configurazione base:

```yaml
myplaybooks: []
myvenv: venv
pkgs:
  - git
  - python3-dev
  - libffi-dev
  - gcc
  - libssl-dev
  - python3-venv
  - jq
```

### Configurazione Ansible

File `ansible.cfg`:
```ini
[defaults]
host_key_checking=False
pipelining=True
forks=100
```

### Dipendenze Python

File `requirement.txt`:
```
git+https://opendev.org/openstack/kolla-ansible@stable/2024.1
ansible-core>=2.15,<2.16.99
python-openstackclient
wheel
yq
```

## Installazione e Configurazione

### 1. Inizializzazione Completa

```bash
# Inizializzazione base
./mystack.sh initialize

# Inizializzazione con generazione password automatica
./mystack.sh --fill initialize
```

**Processo di inizializzazione:**
1. **Verifica pacchetti OS**: Controlla e installa pacchetti necessari (git, python3-dev, libffi-dev, gcc, libssl-dev, python3-venv, jq)
2. **Gestione ambiente virtuale**: 
   - Verifica esistenza di ambienti virtuali multipli
   - Crea nuovo venv se necessario
   - Aggiorna pip alla versione più recente
3. **Installazione dipendenze Python**: Installa kolla-ansible e dipendenze da `requirement.txt`
4. **Scansione playbook**: Rileva automaticamente playbook in `etc/ansible/playbooks/`
5. **Aggiornamento configurazione**: Popola `mystack_config.yaml` con playbook trovati

### 2. Configurazione OpenStack

```bash
# Copia configurazioni di esempio (se necessario)
cp venv/share/kolla-ansible/ansible/inventory/multinode etc/kolla/inventory/
cp venv/share/kolla-ansible/etc_examples/kolla/* etc/kolla/inventory/group_vars/all/

# Verifica link simbolici (dovrebbero esistere già)
ls -la etc/kolla/
```

### 3. Gestione Password

```bash
# Generazione automatica di tutte le password OpenStack
./mystack.sh fill-pwd
```

**Processo di generazione password:**
1. Rimuove link simbolico esistente
2. Copia template password da inventory
3. Genera password random con `kolla-genpwd`
4. Sposta file in posizione corretta
5. Ricrea link simbolico

## Utilizzo dello Script

### Comandi Principali

```bash
# Mostra help completo
./mystack.sh --help

# Workflow completo automatico
./mystack.sh all

# Workflow completo con inizializzazione e password
./mystack.sh --fill all

# Workflow completo saltando inizializzazione
./mystack.sh --skip-initialize all
```

### Comandi Step-by-Step

```bash
# 1. Inizializzazione
./mystack.sh initialize

# 2. Installazione dipendenze Ansible Galaxy
./mystack.sh install-deps

# 3. Bootstrap server target
./mystack.sh bootstrap-servers

# 4. Controlli pre-deployment
./mystack.sh prechecks

# 5. Download immagini Docker
./mystack.sh pull

# 6. Deployment OpenStack
./mystack.sh deploy

# 7. Configurazioni post-deployment
./mystack.sh post-deploy
```

### Opzioni Avanzate

```bash
# Specificare inventario personalizzato
./mystack.sh -i /path/to/custom/inventory deploy

# Modalità verbose
./mystack.sh -v deploy

# Eseguire solo specifici tag
./mystack.sh -t networking,database deploy

# Limitare esecuzione a specifici host
./mystack.sh -l controller01 deploy

# Specificare versione OpenStack
./mystack.sh --os 2023.2 initialize

# Passare variabili extra ad Ansible
./mystack.sh -e "kolla_serial=1" deploy

# Utilizzare variabile d'ambiente per opzioni extra
EXTRA_OPTS="-e kolla_serial=1" ./mystack.sh deploy
```

## Gestione Playbook Personalizzati

### Comando `pb` (Playbook)

Il comando `pb` è il cuore dell'integrazione con playbook personalizzati:

```bash
# Mostra playbook disponibili
./mystack.sh pb ls

# Esegue playbook singolo (modalità standalone)
./mystack.sh pb -f nome_playbook

# Esegue playbook multipli (modalità standalone)
./mystack.sh pb -f playbook1,playbook2

# Integra playbook con workflow kolla-ansible
./mystack.sh pb playbook1,playbook2 install-deps
```

### Esempi Pratici di Integrazione

```bash
# Esempio 1: Setup ambiente prima dell'installazione dipendenze
./mystack.sh pb environment-setup install-deps

# Esempio 2: Configurazione storage prima del bootstrap
./mystack.sh pb storage-config bootstrap-servers

# Esempio 3: Security hardening prima del deployment
./mystack.sh pb security-hardening deploy

# Esempio 4: Monitoring setup dopo il deployment
./mystack.sh pb monitoring-setup post-deploy

# Esempio 5: Workflow complesso con più playbook
./mystack.sh pb network-prep install-deps \
             pb storage-prep bootstrap-servers \
             pb security-config prechecks \
             pb pre-deploy-checks deploy \
             pb monitoring,backup-config post-deploy
```

### Creazione di Playbook Personalizzati

#### 1. Posizionamento
I playbook devono essere posizionati in `etc/ansible/playbooks/` con estensione `.yml` o `.yaml`.

#### 2. Esempio di Playbook

```yaml
# etc/ansible/playbooks/environment-setup.yml
---
- name: Setup dell'ambiente pre-deployment
  hosts: all
  become: yes
  tasks:
    - name: Aggiorna cache dei pacchetti
      apt:
        update_cache: yes
        cache_valid_time: 3600
      when: ansible_os_family == "Debian"
    
    - name: Installa pacchetti addizionali
      package:
        name:
          - htop
          - iotop
          - nethogs
        state: present
    
    - name: Configura limiti di sistema
      lineinfile:
        path: /etc/security/limits.conf
        line: "* soft nofile 65536"
        create: yes
    
    - name: Riavvia servizio rsyslog
      systemd:
        name: rsyslog
        state: restarted
        enabled: yes
```

#### 3. Aggiornamento Automatico

Dopo aver aggiunto nuovi playbook:

```bash
# Ricarica la lista dei playbook disponibili
./mystack.sh initialize

# Verifica playbook riconosciuti
./mystack.sh pb ls
```

**Output atteso:**
```yaml
- papero
- pippo
- pluto
- environment-setup
```

### Gestione Vault per Playbook

Lo script supporta Ansible Vault tramite il file `.vault_password_file`:

```bash
# Crea file password per vault
echo "your_vault_password" > .vault_password_file
chmod 600 .vault_password_file

# I playbook che utilizzano vault funzioneranno automaticamente
./mystack.sh pb encrypted-playbook deploy
```

## Funzionalità Avanzate

### Gestione Errori e Validazione

Lo script include controlli di validazione:

```bash
# Verifica esistenza playbook prima dell'esecuzione
./mystack.sh pb nonexistent-playbook deploy
# Output: Some Playbook does not exist: nonexistent-playbook

# Verifica ambiente virtuale prima di comandi kolla
./mystack.sh deploy  # senza initialize
# Output: Can't load VENV: ./venv/bin/activate
```

### Modalità Force

La modalità `--force` bypassa alcuni controlli:

```bash
# Esegue playbook anche se non ci sono comandi kolla-ansible
./mystack.sh pb -f custom-maintenance-playbook

# Permette multiple virtual environment
./mystack.sh --force initialize
```

### Gestione delle Credenziali Post-Deployment

Dopo il deployment, le credenziali vengono organizzate in:
```
etc/kolla/ostack_credentials_2024.1/
├── admin-openrc.sh
├── clouds.yaml
└── ...
```

Questa directory viene automaticamente aggiunta al `.gitignore`.

## Comandi di Manutenzione

### Management del Cluster

```bash
# Riconfigura servizi OpenStack
./mystack.sh reconfigure

# Ferma tutti i container
./mystack.sh stop

# Recovery MariaDB cluster
./mystack.sh mariadb_recovery

# Genera configurazioni
./mystack.sh genconfig

# Valida configurazioni
./mystack.sh validate-config

# Pulisce immagini Docker orfane
./mystack.sh prune-images
```

### Distruzione del Deployment

```bash
# Distrugge container e volumi
./mystack.sh destroy

# Distrugge anche le immagini Docker
./mystack.sh --include-images destroy

# Conferma distruzione (richiesto per sicurezza)
./mystack.sh --yes-i-really-really-mean-it destroy
```

## Esempi di Casi d'Uso Completi

### Caso 1: Deployment Standard

```bash
# Setup rapido per testing/development
./mystack.sh --fill all
```

### Caso 2: Deployment Produzione con Validazioni

```bash
# Inizializzazione con controlli
./mystack.sh initialize

# Pre-configurazione ambiente
./mystack.sh pb system-hardening,network-optimization install-deps

# Setup storage dedicato
./mystack.sh pb ceph-preparation bootstrap-servers

# Validazioni pre-deployment
./mystack.sh pb security-audit,connectivity-test prechecks

# Deployment con monitoring
./mystack.sh pb deployment-monitoring deploy

# Configurazioni post-deployment
./mystack.sh pb backup-setup,monitoring-integration post-deploy
```

### Caso 3: Deployment Multi-Sito

```bash
# Configurazione per datacenter primario
./mystack.sh -i etc/kolla/inventory/site1 pb site1-preparation all

# Configurazione per datacenter secondario  
./mystack.sh -i etc/kolla/inventory/site2 pb site2-preparation all

# Configurazione inter-site
./mystack.sh pb multi-site-config post-deploy
```

### Caso 4: Upgrade di Versione

```bash
# Backup pre-upgrade
./mystack.sh pb backup-creation

# Upgrade alla nuova versione
./mystack.sh --os 2024.2 pb pre-upgrade-checks prechecks

# Deployment nuova versione
./mystack.sh deploy

# Verifiche post-upgrade
./mystack.sh pb post-upgrade-validation post-deploy
```

## Risoluzione Problemi

### Problemi Comuni

#### 1. Ambienti Virtuali Multipli
```bash
# Errore: "hai più di un VENV"
# Soluzione: Rimuovi venv extra o usa --force
rm -rf venv_extra/
./mystack.sh initialize
```

#### 2. Problemi di Permessi
```bash
# Errore: "Passwords file is world-readable"
# Soluzione: Correggi permessi automaticamente
./mystack.sh fill-pwd
```

#### 3. Playbook Non Trovato
```bash
# Errore: "Some Playbook does not exist"
# Soluzione: Verifica e rilancia initialize
ls etc/ansible/playbooks/
./mystack.sh initialize
./mystack.sh pb ls
```

#### 4. Problemi di Connettività
```bash
# Test connettività verso nodi target
ansible -i etc/kolla/inventory/multinode all -m ping

# Debug con verbose
./mystack.sh -v prechecks
```

### Log e Debug

```bash
# Tutti i log vengono salvati automaticamente (vedi .gitignore)
tail -f *.log

# Modalità debug per playbook custom
./mystack.sh pb -f playbook-name -v

# Debug completo con Ansible
ANSIBLE_DEBUG=1 ./mystack.sh -v deploy
```

### Verifica Configurazione

```bash
# Controlla configurazione corrente
cat etc/env/mystack_config.yaml

# Verifica ambiente virtuale
source venv/bin/activate
pip list | grep kolla

# Controlla inventario
ansible-inventory -i etc/kolla/inventory/multinode --list

# Verifica connessioni
ansible -i etc/kolla/inventory/multinode all -m setup | grep ansible_hostname
```

## Sicurezza

### Best Practices

1. **File Vault Password**: Sempre con permessi 600
```bash
chmod 600 .vault_password_file
```

2. **Credenziali Post-Deploy**: Automaticamente escluse da Git
```bash
# Verificato automaticamente in .gitignore
grep ostack_credentials .gitignore
```

3. **Password OpenStack**: Generate casualmente e sicure
```bash
./mystack.sh fill-pwd
```

4. **SSH Key Management**: Configurare chiavi SSH per tutti i nodi
```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub user@target-node
```

## Personalizzazioni Avanzate

### Modifica Versione OpenStack

```bash
# Modifica nel file di configurazione per permanenza
vim etc/env/mystack_config.yaml

# O specifica da command line
./mystack.sh --os 2023.2 initialize
```

### Inventario Personalizzato

```bash
# Crea inventario personalizzato
cp etc/kolla/inventory/multinode etc/kolla/inventory/production

# Usa inventario personalizzato
./mystack.sh -i etc/kolla/inventory/production deploy
```

### Configurazioni Servizi OpenStack

```bash
# Personalizza configurazioni in
ls etc/kolla/config/
# cinder/    - Storage
# glance/    - Images  
# neutron/   - Networking
# nova/      - Compute
```

## Contributi e Supporto

### Struttura del Codice

Il codice è organizzato modularmente:
- `mystack.sh`: Script principale e parsing argomenti
- `etc/env/functions`: Funzioni core del sistema
- `etc/env/usage`: Sistema di help e documentazione
- `etc/env/playbooks`: Gestione playbook personalizzati

### Debugging dello Script

```bash
# Abilita debug bash
bash -x ./mystack.sh initialize

# Traccia esecuzione funzioni
set -o xtrace
source etc/env/functions
```

### Estensioni

Per aggiungere nuove funzionalità:
1. Modifica `etc/env/functions` per nuove funzioni
2. Aggiorna `etc/env/usage` per nuovo help
3. Estendi `mystack.sh` per nuovi comandi
4. Aggiorna `etc/env/mystack_config.yaml` per nuove configurazioni

## Licenza

Questo progetto è rilasciato sotto licenza open source. Consultare il repository per dettagli specifici.

---
