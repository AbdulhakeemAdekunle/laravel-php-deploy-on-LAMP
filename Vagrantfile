# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
# Define the master node with the necessary vm specifications
  config.vm.define "master" do |master|
    master.vm.box = "ubuntu/jammy64"
    master.vm.hostname = "master"
    master.vm.network :private_network, ip: "192.168.56.100"
  end
# Define the slave node with the necessary vm specifications
  config.vm.define "slave" do |slave|
    slave.vm.box = "ubuntu/jammy64"
    slave.vm.hostname = "slave"
    slave.vm.network :private_network, ip: "192.168.56.101"
  end
# Define the necessary memory and processor specifications for virtual machine
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
    vb.cpus = "1"
  end
end
