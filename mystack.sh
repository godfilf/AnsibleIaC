#!/usr/bin/env bash

set -o errexit

OPENSTACK_RELEASE="2024.1"
UPPER_CONSTRAINTS="https://raw.githubusercontent.com/openstack/requirements/stable/$OPENSTACK_RELEASE/upper-constraints.txt"
VAR_FILE="etc/env/mystack_config.yaml"
CONF_DIR=$PWD/etc/kolla
CRED_DIR=$PWD/etc/kolla/ostack_credentials
PASSWORD_FILE=passwords.yml
#INVENTORY=$PWD/etc/kolla/multinode
INVENTORY=$PWD/etc/kolla/inventory/
INVENTORYFILE=
ANSIBLE_EXTRA_OPTS="$EXTRA_OPTS"
KOLLA_EXTRA_OPTS=""
SKIP_INIT="no"
VENV="./`awk '$1 == "myvenv:"{ print $2 }' $VAR_FILE`/bin/activate"
PB_PATH=$PWD/etc/ansible/playbooks/

source $PWD/etc/env/functions
source $PWD/etc/env/usage
source $PWD/etc/env/playbooks

SHORT_OPTS="i:t:sv"
LONG_OPTS="help,fill,yes-i-really-really-mean-it,include-images,include-dev,skip-initialize,inventory:,verbose,tags:,os:"
RAW_ARGS="$*"
ARGS=$(getopt -o "${SHORT_OPTS}" -l "${LONG_OPTS}" --name "$0" -- "$@") || { usage >&2; exit 2; }

eval set -- "$ARGS"

echo -e "\nCheck Options...\n"

while [ "$#" -gt 0 ]; do
    case "$1" in
      #(-l)
      #        KOLLA_EXTRA_OPTS="$KOLLA_EXTRA_OPTS --limit $2"
      #        shift 2
      #        ;;
      (-v|--verbose)
              KOLLA_EXTRA_OPTS="$KOLLA_EXTRA_OPTS -v"
              shift 1
              ;;
      (-t|--tags)
              KOLLA_EXTRA_OPTS="$KOLLA_EXTRA_OPTS --tags $2"
              shift 2
              ;;
      (-i|--inventory)
              INVENTORY=$2
              shift 2
              ;;
      (--yes-i-really-really-mean-it)
              KOLLA_EXTRA_OPTS="$KOLLA_EXTRA_OPTS --yes-i-really-really-mean-it"
              shift 1
              ;;
      (-s|--skip-initialize)
              SKIP_INIT=yes
              shift 1
              ;;
      (--fill)
              FILL_PASSWORD=yes
              shift 1
              ;;
      (--include-images)
              KOLLA_EXTRA_OPTS="$KOLLA_EXTRA_OPTS $1"
              shift 1
              ;;
      (--include-dev)
              KOLLA_EXTRA_OPTS="$KOLLA_EXTRA_OPTS --include-dev $2"
              shift 2
              ;;
      (--os)
              OPENSTACK_RELEASE="$2"
              UPPER_CONSTRAINTS="https://raw.githubusercontent.com/openstack/requirements/stable/$OPENSTACK_RELEASE/upper-constraints.txt"
              ;;
      (--help|-h)
              usage
              exit 0
              ;;
      (--)
              shift
              break
              ;;

      (*)
              echo "$1 - error"
              echo "$KOLLA_EXTRA_OPTS"
              exit 3
              ;;
  esac
done

echo -e "Check Commands...\n"

case "$1" in
  (initialize)
        install_local_required_pckgs
        check_virtualenv
        [ "$FILL_PASSWORD" == "yes" ] && fill_password_file
        ;;
  (fill-pwd)
        fill_password_file
        ;;
  (install-deps|bootstrap-servers|prechecks|deploy|post-deploy|prune-images|destroy|reconfigure|pull)
	ACTION=$1
        run_kolla $1 "$KOLLA_EXTRA_OPTS"
        ;;
  (all|all-steps)
        ## Rimane da testare se le KOLLA_EXTRA_OPTS funzionano correttamente per tutte le ACTION
        [ "$SKIP_INIT" == "no" ] && install_local_required_pckgs && check_virtualenv
        [ "$FILL_PASSWORD" == "yes" ] && fill_password_file
        for action in install-deps bootstrap-servers prechecks deploy post-deploy; do
          echo -e "\n\n=== Start kolla-ansible $action ===\n\n"
          run_kolla $action "$KOLLA_EXTRA_OPTS"
        done
        ;;
  (pb)
        [ "$2" == "ls" ] && ls -l $PB_PATH && echo 
        ;;
  (*)     
        usage
        exit 3
        ;;
esac

