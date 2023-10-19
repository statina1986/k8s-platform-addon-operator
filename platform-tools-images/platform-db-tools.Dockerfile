FROM centos:centos7
MAINTAINER The CentOS Project <cloud-ops@centos.org

ENV container docker
LABEL RUN="docker run -it --name NAME --privileged --ipc=host --net=host --pid=host -e HOST=/host -e NAME=NAME -e IMAGE=IMAGE -v /sys/fs/selinux:/sys/fs/selinux:ro -v /run:/run -v /var/log:/var/log -v /etc/localtime:/etc/localtime -v /:/host IMAGE"

RUN [ -e /etc/yum.conf ] && sed -i '/tsflags=nodocs/d' /etc/yum.conf || true

# Reinstall all packages to get man pages for them
RUN yum -y reinstall "*" && yum clean all

# Swap out the systemd-container package and install all useful packages
RUN yum -y install \
           gcc \
           make \
           perl \
           perl-Date-Time \
           perl-DBD-Pg \
           sudo \
           screen \
           tar \
           vim-enhanced \
           vim-minimal \
           bash-completion \
           yum-utils \
           curl \
           && yum clean all

RUN        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

RUN        yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

RUN yum -y install \
           MariaDB-client \
           postgresql14 \
           perl-devel

# Set default command
CMD ["/usr/bin/bash"]