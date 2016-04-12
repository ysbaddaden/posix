UBUNTU_PROVISION = <<-SH
  echo "deb http://llvm.org/apt/precise/ llvm-toolchain-precise-3.6 main" > /etc/apt/sources.list.d/llvm.list
  wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add -
  apt-add-repository ppa:ubuntu-toolchain-r/test
  curl -s http://dist.crystal-lang.org/apt/setup.sh | bash

  apt-get install -y build-essential git clang-3.6 llvm-3.6-dev crystal
  apt-get install -y libgmp3-dev zlib1g-dev libedit-dev libxml2-dev libssl-dev libyaml-dev libreadline-dev
  apt-get clean

  echo 'export LIBRARY_PATH="/opt/crystal/embedded/lib"' > /etc/profile.d/crystal.sh
  echo 'export CC=clang-3.6 CXX=clang-3.6++' >> /etc/profile.d/crystal.sh
SH

ALPINE_PROVISION = <<-SH
  apk add openssl
  wget "https://dl.dropboxusercontent.com/u/53345358/alpine/julien%40portalier.com-56dab02e.rsa.pub" -O /etc/apk/keys/julien@portalier.com-56dab02e.rsa.pub
  echo "https://dl.dropboxusercontent.com/u/53345358/alpine/testing" >> /etc/apk/repositories
  apk update
  apk add git build-base llvm-dev clang crystal shards
  apk add bash libevent-dev pcre-dev ncurses-dev zlib-dev gc-dev libxml2-dev openssl-dev readline-dev gmp-dev yaml-dev
SH

#FREEBSD_PROVISION = <<-SH
#  TODO: download crystal compiler + patched GC
#  pkg install -y git gmake pkgconf pcre libunwind clang36 libyaml gmp libevent2
#SH

Vagrant.configure(2) do |config|
  config.vm.define "gnu32" do |c|
    c.vm.box = "erickeller/precise-i386"
    c.vm.provision :shell, inline: UBUNTU_PROVISION
  end

  config.vm.define "gnu64" do |c|
    c.vm.box = "fgrehm/precise64-lxc"
    c.vm.provision :shell, inline: UBUNTU_PROVISION
  end

  config.vm.define "musl32" do |c|
    c.ssh.shell = "ash"
    c.vm.box = "ysbaddaden/alpine32"
    c.vm.provision :shell, inline: ALPINE_PROVISION
  end

  config.vm.define "musl64" do |c|
    c.ssh.shell = "ash"
    c.vm.box = "ysbaddaden/alpine64"
    c.vm.provision :shell, inline: ALPINE_PROVISION
  end

  #config.vm.define "freebsd64" do |c|
  #  c.ssh.shell = "csh"
  #  c.vm.box = "freebsd/FreeBSD-10.2-RELEASE"
  #  c.vm.provision :shell, inline: FREEBSD_PROVISION
  #end

  #config.vm.provider "virtualbox" do |vb|
  #  vb.memory = 4096
  #  vb.cpus = 2
  #end
end
