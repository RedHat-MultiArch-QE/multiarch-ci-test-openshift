#!/bin/bash
yum install -y yum-utils &&

### ARCH SWITCH ###
arch=$(arch)
case $arch in

"x86_64" )
basedir=server
;;

"ppc64le" )
basedir=power-le
;;

esac

if [ -z "$basedir" ] || [ -z "$arch" ]; then
  echo "Error: Invalid base repo directory=[$basedir] or arch=[$arch]"
  exit 1
fi

# Install repos
rpm --import https://www.redhat.com/security/data/fd431d51.txt
yum-config-manager --add-repo http://pulp.dist.prod.ext.phx2.redhat.com/content/dist/rhel/$basedir/7/7Server/$arch/os/ &&
yum-config-manager --add-repo http://pulp.dist.prod.ext.phx2.redhat.com/content/dist/rhel/$basedir/7/7Server/$arch/optional/os/ &&
yum-config-manager --add-repo http://pulp.dist.prod.ext.phx2.redhat.com/content/dist/rhel/$basedir/7/7Server/$arch/extras/os/ &&
yum-config-manager --add-repo http://pulp.dist.prod.ext.phx2.redhat.com/content/dist/rhel/$basedir/7/7Server/$arch/ansible/2/os/

# Install Ansible
yum install -y ansible

echo -e "\n\n\nPLAYBOOK START :: INSTALL & CONFIGURE OPENSHIFT INSTALLER\n\n\n" &&
    ansible-playbook -i localhost.inventory configure-openshift.yml &&

echo -e "\n\n\nPLAYBOOK START :: INSTALL PREREQUISITES\n\n\n" &&
    ansible-playbook -i artifacts/host.inventory /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml
