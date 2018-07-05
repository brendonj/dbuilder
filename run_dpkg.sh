#!/bin/bash
set -ex

RELEASE=`lsb_release -c -s`

# if some deb files exist in additional_packages directory, we create a trivial
# local repository
preinstall_debs=`find /dbuilder/additional_packages/ -name \*.deb`
if [ -n "${preinstall_debs}" ]; then
    repo_path=/dbuilder/local_repository
    mkdir ${repo_path}
    cp ${preinstall_debs} ${repo_path}
    pushd ${repo_path}
    dpkg-scanpackages --multiversion . > Packages
    popd
    echo "deb [trusted=yes] file:${repo_path} ./" > /etc/apt/sources.list.d/local_repo.list

    # if pin-priority is defined, propagate it
    if [ -n "${LOCAL_REPO_PRIORITY}" ]; then
        echo -e "Package: *\nPin: origin \"\"\nPin-Priority: ${LOCAL_REPO_PRIORITY}" \
            > /etc/apt/preferences.d/local_repo
    fi
    unset repo_path
fi
unset preinstall_debs

# copy the original source to the filename that Debian expects for the orig
# tarball, stripping any release candidate versioning
ORIG_TAR_GZ=`echo ${1} | sed 's/\([a-zA-Z]*\)-\([0-9.]*\)\(~rc[0-9]*\)\{0,1\}.tar.gz/\1_\2.orig.tar.gz/'`
cp /dbuilder/sources/${1} /dbuilder/build/${ORIG_TAR_GZ}

# untar the source
cd /dbuilder/build/
tar xzvf ${ORIG_TAR_GZ}
cd ${1%.tar.gz}

# copy across the debian directory, checking first for a relevant directory
# that matches our release codename, otherwise a generic one
if [ -d /dbuilder/sources/debian.${RELEASE} ]; then
    cp -r /dbuilder/sources/debian.${RELEASE} ./debian
else
    cp -r /dbuilder/sources/debian .
fi

# preinstall hooks
if [ -d /dbuilder/preinstall.d ]; then
    for file in `find /dbuilder/preinstall.d -executable -type f | sort -n`; do
        ${file}
    done
    unset file
fi

# install dependencies as listed in the package control file
apt-get update
mk-build-deps -i -r -t 'apt-get -f -y --force-yes'

# build the package
DEB_BUILD_OPTIONS=nocheck ${DBUILDER_BUILD_CMD}

# copy the package back into the original source directory
chmod 644 ../*.deb
mkdir -p /dbuilder/sources/packages/${RELEASE}
cp ../*.deb /dbuilder/sources/packages/${RELEASE}/
if [ -n $OWNER ]; then
    chown -R $OWNER /dbuilder/sources/packages/${RELEASE}/
fi
