## Custom Openstack Deploy with kolla


## Custom info

1. a causa di un bug su docker ho dovutodistruggere completamente ogni riferimento a docker, non che i pacchetti installati, per installare la nuova versione :

```
docker volume prune -af && rm -rf /var/lib/docker/overlay2/* && apt-get -y remove --purge docker-ce && apt-get -y autoremove && rm -rf /etc/docker && init 6
```

## Achivement

L'obiettivo di questo script integrato è quello di poter lanciare in modo integrato all'installazione di kolla-ansible, dei playbook custom che ci permetteranno di poter installare kolla in ambienti customizzati con vincoli infrastrutturali.


## How does it work

- The initialize command: 
  --> check if the specified pkgs are installed; 
  --> check if venv already exists, if not it will create it; 
  --> create a obj list with custom playbooks in et/ansible/playbooks;

- il comando pb permette di specificare quale playbook custom lanciare:
  --> ./mystack pb pippo,pluto install-deps

  inserendolo più volte lo si esegue prima e/o dopo le varie action di kolla
  --> ./mystack pb pippo install-deps pb pippo,pluto

## Steps

1. Eseguire l'`initialize`
```
root@kollaJump:~/IaC_tools/AnsibleIaC# ./mystack.sh initialize

Check Options...

Check Commands...


Args: initialize 


Load pkgs... 
Installing needed OS PKGS... 

Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
git is already the newest version (1:2.39.2-1.1).
python3-dev is already the newest version (3.11.2-1+b1).
libffi-dev is already the newest version (3.4.4-1).
gcc is already the newest version (4:12.2.0-3).
libssl-dev is already the newest version (3.0.14-1~deb12u2).
python3-venv is already the newest version (3.11.2-1+b1).
0 upgraded, 0 newly installed, 0 to remove and 33 not upgraded.
DONE
virtualenv is not installed. Installing...
virtualenv installation complete. 
VENV name : ./venv/bin/activate


Install pip packages...

Requirement already satisfied: pip in ./venv/lib/python3.11/site-packages (23.0.1)
Collecting pip
  Using cached pip-24.2-py3-none-any.whl (1.8 MB)
Installing collected packages: pip
  Attempting uninstall: pip
    Found existing installation: pip 23.0.1
    Uninstalling pip-23.0.1:
      Successfully uninstalled pip-23.0.1
Successfully installed pip-24.2
...
..
.
omitted
.
..
...

Creating list of custom playbooks...

Configuring right venv path... DONE


```
2. copiare il file inventory nel path `etc/kolla/inventory` e tunarlo ad hoc
```
cp venv/share/kolla-ansible/ansible/inventory/multinode etc/kolla/inventory/
```
3. copiare i file `global.yaml` e `passwords.yaml` nel path `etc/kolla/inventory/` e tunarli ad hoc
```
cp venv/share/kolla-ansible/etc_examples/kolla/* etc/kolla/
```
4. controllare la presenza dei link `global.yaml` e `passwords.yaml` nel path `etc/kolla`
```
# ls -l etc/kolla/
total 48
drwxr-xr-x 8 root root  4096 Sep 16 15:36 config
-rw-r--r-- 1 root root 33243 Sep 16 15:36 globals.yml
drwxr-xr-x 2 root root  4096 Sep 17 13:18 inventory
lrwxrwxrwx 1 root root    19 Sep 16 15:36 multinode -> inventory/multinode
drwxr-xr-x 2 root root  4096 Sep 16 15:36 ostack_credentials
lrwxrwxrwx 1 root root    23 Sep 17 13:19 passwords.yml -> inventory/passwords.yml
#

```
oppure
```
# find etc/kolla -type l
etc/kolla/passwords.yml
etc/kolla/multinode
#

```

5. Effettuare il fill automatico del file `passowrds.yaml`, se necessario
```
# ./mystack.sh fill-pwd

Check Options...

Check Commands...


Args: fill-pwd 


Generating Random Passwords for /root/IaC_tools/AnsibleIaC/etc/kolla/passwords.yml
WARNING: Passwords file "/root/IaC_tools/AnsibleIaC/etc/kolla/passwords.yml" is world-readable. The permissions will be changed.

#
```

6. Tune `etc/kolla/config` path with right configuration for the deploy of Openstack
```

# ls -l etc/kolla/config/
total 36
drwxr-xr-x 4 root root 4096 Sep 16 15:36 cinder
-rw-r--r-- 1 root root  557 Sep 16 15:36 cinder.conf
drwxr-xr-x 2 root root 4096 Sep 16 15:36 designate
drwxr-xr-x 2 root root 4096 Sep 16 15:36 glance
-rw-r--r-- 1 root root  253 Sep 16 15:36 glance.conf
drwxr-xr-x 2 root root 4096 Sep 16 15:36 neutron
-rw-r--r-- 1 root root   30 Sep 16 15:36 nfs_shares
drwxr-xr-x 2 root root 4096 Sep 16 15:36 nova
#

```

7. Run step by steps
```
./mystack.sh initialize
./mystack.sh install-deps
./mystack.sh bootstrap-servers
./mystack.sh prechecks
./mystack.sh pull
./mystack.sh deploy
./mystack.sh post-deploy
```

7. Run automatic deploy
```
./mystack.sh all
```
