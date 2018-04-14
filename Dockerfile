# OAI HSS Dockerfile
# This is largely based on the juju charm by Navic Nikaein and A.B. Molini
# https://jujucharms.com/u/navid-nikaein/oai-hss/xenial/8
FROM ubuntu:16.04

MAINTAINER Balz Aschwanden <balz.aschwanden@students.unibe.ch>

ENV SQL_PW linux
ENV GIT_CHECKOUT /srv/openair-cn
ENV GIT_BRANCH develop
ENV openair_path $GIT_CHECKOUT
ENV build_path $openair_path/build
ENV hss_path $build_path/hss
ENV build_run_scripts $openair_path/scripts
ENV tools_path $build_path/tools
ENV hss_conf /usr/local/etc/oai
ENV hss_exec_name oai_hss
ENV freediameter_conf_path $hss_conf/freeDiameter
ENV oai_op_key "11111111111111111111111111111111"
ENV oai_opc_key "8E27B6AF0E692E750F32667A3B14605D"
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y install \
    apt-utils

RUN echo "mysql-server mysql-server/root_password password $PASSWORD" | debconf-set-selections && \
    echo "mysql-server mysql-server/root_password_again password $PASSWORD" | debconf-set-selections

RUN apt-get -y install \
    git \
    virt-what \
    mysql-client \
    at \
    sudo \
    make \
    cmake 

# Add Docker user to sudo group
RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo

RUN apt-get clean && \
    mkdir -p $hss_conf && \
    mkdir -p $freediameter_conf_path && \
    git clone https://gitlab.eurecom.fr/oai/openair-cn.git $GIT_CHECKOUT && \
    cd $GIT_CHECKOUT && \
    git checkout $GIT_BRANCH

#We don't need phpmyadmin in the installation
#we don't either want the low latency kernel for HSS
RUN sed -i '/phpmyadmin/d' $tools_path/build_helper && \
    sed -i -r "s/(check_kernel_release_and_install_xtables_addons_oai[^()]+)/#\1/" $tools_path/build_helper

COPY oai_hss.service /etc/systemd/system/
# https://gitlab.eurecom.fr/oai/openairinterface5g/wikis/AutoBuild#building-the-epc-modules-newer-version-latest-developmaster-branch
RUN $GIT_CHECKOUT/scripts/build_hss -c -i -F && \
    $GIT_CHECKOUT/scripts/build_hss

RUN cp -upv $openair_path/etc/hss.conf $hss_conf && \
    cp -upv $openair_path/etc/hss_fd.conf $freediameter_conf_path && \
    cp -upv $openair_path/etc/acl.conf $freediameter_conf_path

# TODO
# update_hostname(){
#   HOSTNAME=`echo $JUJU_UNIT_NAME | sed 's|/|-|'`
#   echo "$HOSTNAME" > /etc/hostname
#   hostname $HOSTNAME
#   echo "127.0.0.1 `hostname`" > /etc/hosts
# }
# 
# configure_hosts(){
#   realm=`config-get realm`
#   #define fqdn for MME
#   if [ -z "$(grep -o "`hostname`.$realm" /etc/hosts)" ]; then
#      echo 127.0.0.1 localhost > /etc/hosts
#      echo 127.0.0.1 `hostname`.$realm `hostname` mme >> /etc/hosts
#   fi
# }


