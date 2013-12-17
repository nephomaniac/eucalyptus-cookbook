#
# Cookbook Name:: eucalyptus
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

## Setup NTP
include_recipe "ntp"

## Disable SELinux
include_recipe "selinux"
selinux_state "SELinux Disabled" do
  action :disabled
end

## Install repo rpms
yum_repository "eucalyptus-release" do
  description "Eucalyptus Package Repo"
  url node["eucalyptus"]["eucalyptus-repo"]
  gpgkey "http://www.eucalyptus.com/sites/all/files/c1240596-eucalyptus-release-key.pub"
end

yum_repository "euca2ools-release" do
  description "Euca2ools Package Repo"
  url node["eucalyptus"]["euca2ools-repo"]
  gpgkey "http://www.eucalyptus.com/sites/all/files/c1240596-eucalyptus-release-key.pub"
end

remote_file "/tmp/epel-release.rpm" do
  source node["eucalyptus"]["epel-rpm"]
  not_if "rpm -qa | grep -qx 'epel-release'"
end

remote_file "/tmp/elrepo-release.rpm" do
  source node["eucalyptus"]["elrepo-rpm"]
  not_if "rpm -qa | grep -qx 'elrepo-release'"
end

execute 'yum install -y *release*.rpm' do
  cwd '/tmp'
end

if node["eucalyptus"]["install-type"] == "source"
  ### Create eucalyptus user
  user "eucalyptus" do
    comment "Eucalyptus User"
    system true
    shell "/bin/false"
  end
  ### Create eucalyptus home directory
  directory node["eucalyptus"]["home-directory"] do
    owner "eucalyptus"
    group "eucalyptus"
    mode 00750
    action :create
  end

  ### Add build deps repo
  yum_repository "euca-build-deps" do
    description "Eucalyptus Build Dependencies repo"
    url "http://downloads.eucalyptus.com/software/eucalyptus/build-deps/3.3/centos/6/x86_64/"
    action :add
  end

  ### This is a source install so we need the build time deps and runtime deps
  ### Build time first
  execute 'yum groupinstall -y development'
  
  %w{java-1.7.0-openjdk-devel ant ant-nodeps apache-ivy axis2-adb axis2-adb-codegen axis2c-devel
    axis2-codegen curl-devel gawk git jpackage-utils libvirt-devel libxml2-devel 
    libxslt-devel m2crypto openssl-devel python-devel python-setuptools
    rampartc-devel swig xalan-j2-xsltc}.each do |dependency|
    yum_package dependency do
      options "--nogpg"
    end
  end

  ### Runtime deps
  %w{java-1.7.0-openjdk gcc bc make ant ant-nodeps apache-ivy axis2-adb-codegen axis2-codegen axis2c 
    axis2c-devel bridge-utils coreutils curl curl-devel scsi-target-utils 
    dejavu-serif-fonts device-mapper dhcp41 dhcp41-common drbd drbd83 drbd83-kmod 
    drbd83-utils e2fsprogs euca2ools file gawk httpd iptables iscsi-initiator-utils jpackage-utils kvm 
    PyGreSQL libcurl libvirt libvirt-devel libxml2-devel libxslt-devel lvm2 m2crypto
    openssl-devel parted patch perl-Crypt-OpenSSL-RSA perl-Crypt-OpenSSL-Random 
    postgresql91 postgresql91-server python-boto python-devel python-setuptools 
    rampartc rampartc-devel rsync scsi-target-utils sudo swig util-linux vconfig 
    velocity vtun wget which xalan-j2-xsltc ipset ebtables}.each do |dependency|
    yum_package dependency
  end
  
  ### Get WSDL2C
  execute 'wget https://raw.github.com/eucalyptus/eucalyptus-rpmspec/master/euca-WSDL2C.sh && chmod +x euca-WSDL2C.sh' do
    cwd node["eucalyptus"]["home-directory"]
  end

  ### Checkout Eucalyptus Source
  git "#{node['eucalyptus']['home-directory']}/source" do
    repository node['eucalyptus']['source-repo']
    reference node['eucalyptus']['source-branch']
    action :sync
  end

  ### Run configure
  execute "export EUCALYPTUS='#{node["eucalyptus"]["home-directory"]}' && ./configure '--with-axis2=/usr/share/axis2-*' --with-axis2c=/usr/lib64/axis2c --prefix=$EUCALYPTUS --with-apache2-module-dir=/usr/lib64/httpd/modules --with-db-home=/usr/pgsql-9.1 --with-wsdl2c-sh=#{node["eucalyptus"]["home-directory"]}/euca-WSDL2C.sh" do
    cwd "#{node["eucalyptus"]["home-directory"]}/source"
  end
end


execute 'Authorize passwordless SSH' do
  command "ssh-keygen -f /root/.ssh/id_rsa -P '' && cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && chmod og-r /root/.ssh/authorized_keys"
end

execute 'Add host key' do
  command "ssh-keyscan #{node['ipaddress']} >> /root/.ssh/known_hosts"
end