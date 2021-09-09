#!/usr/bin/env bash

# Copyright (C) 2021 Aryan Karan 'aryankaran' India

# Script to setup an AOSP Build environment on Ubuntu and Linux Mint

LATEST_MAKE_VERSION="4.3"
UBUNTU_14_PACKAGES="binutils-static curl figlet libesd0-dev libwxgtk2.8-dev schedtool"
UBUNTU_16_PACKAGES="libesd0-dev"
UBUNTU_18_PACKAGES="curl"
UBUNTU_20_PACKAGES="python"
PACKAGES=""

apt update

# Install lsb-core packages
apt install lsb-core -y

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

    apt install \
    adb aria2 autoconf automake axel bc bison build-essential \
    ccache clang cmake expat fastboot flex g++ \
    g++-multilib gawk gcc gcc-multilib git gnupg gperf \
    htop imagemagick lib32ncurses5-dev lib32z1-dev libtinfo5 libc6-dev libcap-dev \
    libexpat1-dev libgmp-dev '^liblz4-.*' '^liblzma.*' libmpc-dev libmpfr-dev libncurses5-dev \
    libsdl1.2-dev libssl-dev libtool libxml2 libxml2-utils '^lzma.*' lzop \
    maven ncftp ncurses-dev patch patchelf pkg-config pngcrush \
    pngquant python2.7 python-all-dev re2c schedtool squashfs-tools subversion \
    texinfo unzip w3m xsltproc zip zlib1g-dev lzip \
    libxml-simple-perl apt-utils \
    screen tmate pigz axel \
    "${PACKAGES}" -y

echo "Installing openjdk8 and setting it default"
apt install openjdk-8-jdk -y && update-java-alternatives -s java-1.8.0-openjdk-amd64
echo "Java setup succesfully"

# For all those distro hoppers, lets setup your git credentials
GIT_USERNAME="$(git config --get user.name)"
GIT_EMAIL="$(git config --get user.email)"
echo "Configuring git"
#if [[ -z ${GIT_USERNAME} ]]; then
#    echo -n "Enter your name: "
#    read -r NAME
#fi
#if [[ -z ${GIT_EMAIL} ]]; then
#    echo -n "Enter your email: "
#    read -r EMAIL
git config --global user.name "Aryan Karan"
git config --global user.email "aryankaran28022004@gmail.com"
#fi
#git config --global credential.helper "cache --timeout=7200"
echo "git identity setup successfully!"

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

if [[ "$(command -v make)" ]]; then
    makeversion="$(make -v | head -1 | awk '{print $3}')"
    if [[ ${makeversion} != "${LATEST_MAKE_VERSION}" ]]; then
        echo "Installing make ${LATEST_MAKE_VERSION} instead of ${makeversion}"
        bash "$(dirname "$0")"/make.sh "${LATEST_MAKE_VERSION}"
    fi
fi

echo "Installing repo"
curl --create-dirs -L -o /usr/local/bin/repo -O -L https://storage.googleapis.com/git-repo-downloads/repo
chmod a+rx /usr/local/bin/repo
