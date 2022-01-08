#!/usr/bin/env bash

# Copyright (C) 2021 Aryan Karan 'aryankaran' India

# Script to setup an AOSP Build environment on Ubuntu and Linux Mint

LATEST_MAKE_VERSION="4.3"
UBUNTU_14_PACKAGES="binutils-static curl figlet libesd0-dev libwxgtk2.8-dev schedtool"
UBUNTU_16_PACKAGES="libesd0-dev"
UBUNTU_18_PACKAGES="curl"
UBUNTU_20_PACKAGES="python"
PACKAGES=""

export DEBIAN_FRONTEND=noninteractive

apt update -qq

# Install lsb-core packages
apt install lsb-core -y -qq

LSB_RELEASE="$(lsb_release -d | cut -d ':' -f 2 | sed -e 's/^[[:space:]]*//')"

if [[ ${LSB_RELEASE} =~ "Ubuntu 14" ]]; then
    PACKAGES="${UBUNTU_14_PACKAGES}"
elif [[ ${LSB_RELEASE} =~ "Mint 18" || ${LSB_RELEASE} =~ "Ubuntu 16" ]]; then
    PACKAGES="${UBUNTU_16_PACKAGES}"
elif [[ ${LSB_RELEASE} =~ "Ubuntu 18" || ${LSB_RELEASE} =~ "Ubuntu 19" || ${LSB_RELEASE} =~ "Deepin" ]]; then
    PACKAGES="${UBUNTU_18_PACKAGES}"
elif [[ ${LSB_RELEASE} =~ "Ubuntu 20" ]]; then
    PACKAGES="${UBUNTU_20_PACKAGES}"
fi

    apt install -qq\
    adb aria2 autoconf automake axel bc bison build-essential \
    ccache clang cmake expat fastboot flex g++ \
    g++-multilib gawk gcc gcc-multilib git gnupg gperf \
    htop imagemagick lib32ncurses5-dev lib32z1-dev libtinfo5 libc6-dev libcap-dev \
    libexpat1-dev libgmp-dev '^liblz4-.*' '^liblzma.*' libmpc-dev libmpfr-dev libncurses5-dev \
    libsdl1.2-dev libssl-dev libtool libxml2 libxml2-utils '^lzma.*' lzop \
    maven ncftp ncurses-dev patch patchelf pkg-config pngcrush \
    pngquant python2.7 python-all-dev re2c schedtool squashfs-tools subversion \
    texinfo unzip w3m xsltproc zip zlib1g-dev lzip \
    libxml-simple-perl tzdata apt-utils \
    screen tmate pigz axel nano \
    curl sed coreutils tar time ssh\
    "${PACKAGES}" -y

ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime

echo -e "Installing openjdk8 and setting it default\n\n"
apt install openjdk-8-jdk -y -qq && update-java-alternatives -s java-1.8.0-openjdk-amd64
echo -e "Java setup succesfully\n\n"

# For all those distro hoppers, lets setup your git credentials
GIT_USERNAME="$(git config --get user.name)"
GIT_EMAIL="$(git config --get user.email)"
echo -e "\nConfiguring git\n"
#if [[ -z ${GIT_USERNAME} ]]; then
#    echo -n "Enter your name: "
#    read -r NAME
#fi
#if [[ -z ${GIT_EMAIL} ]]; then
#    echo -n "Enter your email: "
#    read -r EMAIL
#fi
#git config --global credential.helper "cache --timeout=7200"
git config --global user.name "Aryan Karan"
git config --global user.email "aryankaran28022004@gmail.com"
echo -e "git identity setup successfully!\n"

# From Ubuntu 18.10 onwards and Debian Buster libncurses5 package is not available, so we need to hack our way by symlinking required library
# shellcheck disable=SC2076
if [[ ${LSB_RELEASE} =~ "Ubuntu 18.10" || ${LSB_RELEASE} =~ "Ubuntu 19" || ${LSB_RELEASE} =~ "Ubuntu Focal Fossa" || ${LSB_RELEASE} =~ "Debian GNU/Linux 10" ]]; then
    if [[ -e /lib/x86_64-linux-gnu/libncurses.so.6 && ! -e /usr/lib/x86_64-linux-gnu/libncurses.so.5 ]]; then
        ln -s /lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
    fi
fi

if [[ "$(command -v adb)" != "" ]]; then
    echo -e "Setting up udev rules for adb!"
    curl --create-dirs -L -o /etc/udev/rules.d/51-android.rules -O -L https://raw.githubusercontent.com/M0Rf30/android-udev-rules/master/51-android.rules
    chmod 644 /etc/udev/rules.d/51-android.rules
    chown root /etc/udev/rules.d/51-android.rules
    systemctl restart udev
    adb kill-server
    killall adb
fi

function install_latest_make() {
export a="$PWD"
cd /tmp || exit 1
axel -a -n 10 https://ftp.gnu.org/gnu/make/make-"${1}".tar.gz
tar xf /tmp/make-"${1}".tar.gz
cd /tmp/make-"${1}" || exit 1
./configure
bash ./build.sh
sudo install ./make /usr/local/bin/make
cd - || exit 1
rm -rf /tmp/make-"${1}"{,.tar.gz}
cd $a
}

if [[ "$(command -v make)" ]]; then
    makeversion="$(make -v | head -1 | awk '{print $3}')"
    if [[ ${makeversion} != "${LATEST_MAKE_VERSION}" ]]; then
        echo "Installing make ${LATEST_MAKE_VERSION} instead of ${makeversion}"
        install_latest_make "${LATEST_MAKE_VERSION}"
    fi
fi

echo "Installing repo"
curl --create-dirs -L -o /usr/local/bin/repo -O -L https://storage.googleapis.com/git-repo-downloads/repo
chmod a+rx /usr/local/bin/repo

# Install transfer
cd /usr/bin && bash -c "$(curl -sL https://git.io/file-transfer)"
