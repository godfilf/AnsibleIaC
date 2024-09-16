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

