#!/usr/bin/env bash

set -o errexit

ALL_CMD=(install-deps bootstrap-servers prechecks deploy post-deploy prune-images destroy reconfigure pull initialize)
CMD_COUNT=${#ALL_CMD[@]}
OPENSTACK_RELEASE="2024.1"
#OPENSTACK_RELEASE="victoria"
UPPER_CONSTRAINTS="https://raw.githubusercontent.com/openstack/requirements/stable/$OPENSTACK_RELEASE/upper-constraints.txt"
#UPPER_CONSTRAINTS="https://opendev.org/openstack/requirements/raw/branch/unmaintained/$OPENSTACK_RELEASE/upper-constraints.txt"
VAR_FILE="etc/env/mystack_config.yaml"
CONF_DIR=$PWD/etc/kolla
CRED_DIR=$PWD/etc/kolla/ostack_credentials_$OPENSTACK_RELEASE
PASSWORD_FILE=passwords.yml
#INVENTORY=$PWD/etc/kolla/multinode
INVENTORY=$PWD/etc/kolla/inventory/
INVENTORYFILE=
ANSIBLE_EXTRA_OPTS="$EXTRA_OPTS"
KOLLA_EXTRA_OPTS=""
SKIP_INIT="no"
VENV="./`awk '$1 == "myvenv:"{ print $2 }' $VAR_FILE`/bin/activate"
PB_PATH=$PWD/etc/ansible/playbooks/
PB_PATH_SED=etc\\/ansible\\/playbooks\\/
PB_VERBOSE=""
PB_NAME_EXT=""
FORCE="false"
MYVAULTFILE=$PWD/.vault_password_file

if ! grep -Fxq "`echo $VENV | cut -d"/" -f2`/" .gitignore; then
  echo "`echo $VENV | cut -d"/" -f2`/" >> .gitignore
fi

source $PWD/etc/env/functions
source $PWD/etc/env/usage
source $PWD/etc/env/playbooks

SHORT_OPTS="i:t:l:e:svf"
LONG_OPTS="help,fill,yes-i-really-really-mean-it,include-images,include-dev,skip-initialize,inventory:,verbose,tags:,os:,force,limit:"
RAW_ARGS="$*"
ARGS=$(getopt -o "${SHORT_OPTS}" -l "${LONG_OPTS}" --name "$0" -- "$@") || { usage >&2; exit 2; }

eval set -- "$ARGS"

echo -e "\nCheck Options...\n"

[ $# -eq 1 ] && usage && exit 0

while [ "$#" -gt 0 ]; do
    case "$1" in
      (-l|--limit)
              KOLLA_EXTRA_OPTS="$KOLLA_EXTRA_OPTS --limit $2"
              shift 2
              ;;
      (-v|--verbose)
              KOLLA_EXTRA_OPTS="$KOLLA_EXTRA_OPTS -v"
              PB_VERBOSE="$PB_VERBOSE $1"
              shift 1
              ;;
      (-t|--tags)
              KOLLA_EXTRA_OPTS="$KOLLA_EXTRA_OPTS --tags $2"
              shift 2
              ;;
      (-e)
              KOLLA_EXTRA_OPTS="$KOLLA_EXTRA_OPTS -e $2"
              shift 2
              ;;
      (-i|--inventory)
              INVENTORY=$2
              shift 2
              ;;
      (-f|--force)
              FORCE=true
              shift 1
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

CMD=$@
[ -z "${CMD[0]}" ] && usage && exit 0 

echo -e "\nArgs: $@ \n"

while [ "$#" -gt 0 ]; do
  case "$1" in
    (initialize)
          install_local_required_pckgs
          check_virtualenv
          [ "$FILL_PASSWORD" == "yes" ] && fill_password_file
          shift 1
          ;;
    (fill-pwd)
          fill_password_file
          shift 1
          ;;
    (install-deps|bootstrap-servers|prechecks|deploy|post-deploy|prune-images|destroy|reconfigure|pull|mariadb_recovery|genconfig|validate-config|stop)
  	  ACTION=$1
          run_kolla $1 "$KOLLA_EXTRA_OPTS"
          shift 1
          ;;
    (all|all-steps)
          ## Rimane da testare se le KOLLA_EXTRA_OPTS funzionano correttamente per tutte le ACTION
          [ "$SKIP_INIT" == "no" ] && install_local_required_pckgs && check_virtualenv
          [ "$FILL_PASSWORD" == "yes" ] && fill_password_file
          for action in install-deps bootstrap-servers prechecks pull deploy post-deploy; do
            echo -e "\n\n=== Start kolla-ansible $action ===\n\n"
            run_kolla $action "$KOLLA_EXTRA_OPTS"
          done
          shift 1
          ;;
    (pb)
          pb_tune

          #[ "$2" == "ls" ] && ls -l $PB_PATH && shift 2 && break
          [ "$2" == "ls" ] && yq .myplaybooks $VAR_FILE && shift 2 && break

          pb_chk $2

          PB_EXIST=`echo $2 | tr ',' '\n' | xargs -I {} sh -c 'echo {}".yml\n"{}".yaml"' |sed -e 's/^/'$PB_PATH_SED'/g'`
          for NAME in $PB_EXIST; do 
            [ -e $NAME ] && PB_NAME_EXT="$PB_NAME_EXT $NAME"
          done
         
          #[ $CMD_COUNT == 1 ] && pb_run "$PB_PATH$(echo $2 |sed -e 's/,/.* '$PB_PATH_SED'/g').*" "$PB_VERBOSE" && shift 2 || { help_pb; exit 1; }
          [ $CMD_COUNT == 1 ] && pb_run "$PB_NAME_EXT" "$PB_VERBOSE" && shift 2 || { help_pb; exit 1; }
          PB_NAME_EXT=""
          ;;
    (*)     
          usage
          exit 3
          ;;
  esac
done

echo
