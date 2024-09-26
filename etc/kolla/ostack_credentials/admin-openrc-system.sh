# Ansible managed

# Clear any old environment that may conflict.
for key in $( set | awk '{FS="="}  /^OS_/ {print $1}' ); do unset $key ; done
export OS_USER_DOMAIN_NAME='Default'
export OS_SYSTEM_SCOPE=all
export OS_USERNAME='admin'
export OS_PASSWORD='BBNJ24B5eYjLVRQdRaAkFtNd6RSjTkgLfZcsrL7N'
export OS_AUTH_URL='http://10.10.10.99:5000'
export OS_INTERFACE='internal'
export OS_ENDPOINT_TYPE='internalURL'
export OS_IDENTITY_API_VERSION='3'
export OS_REGION_NAME='RegionOne'
export OS_AUTH_PLUGIN='password'
