#!/bin/sh -x
set -e

TAG=${1:-"master"}

SRCDIR=/workspace
BUILDAREA=/root/rpmbuild

mkdir -p ${SRCDIR}
pushd ${SRCDIR}

git clone git://github.com/ceph/ceph --depth 1 -b ${TAG}

pushd ${SRCDIR}/ceph

echo --START-IGNORE-WARNINGS
yum install -y rpm-build rpmdevtools
[ ! -x install-deps.sh ] || ./install-deps.sh
[ ! -x autogen.sh ] || ./autogen.sh || exit 1
autoconf || true
echo --STOP-IGNORE-WARNINGS

[ -z "$CEPH_EXTRA_CONFIGURE_ARGS" ] && CEPH_EXTRA_CONFIGURE_ARGS=--with-tcmalloc
[ ! -x configure ] || ./configure --with-debug --with-radosgw --with-fuse --with-libatomic-ops --with-gtk2 --with-nss $CEPH_EXTRA_CONFIGURE_ARGS || exit 2

if [ ! -e Makefile ]; then
    echo "$0: no Makefile, aborting." 1>&2
    exit 3
fi

# clear out any $@ potentially passed in
set --

# Make tarball 
./make-dist ${TAG}

# Set up build area
rpmdev-setuptree
cp -a ceph-*.tar.bz2 ${BUILDAREA}/SOURCES/.
cp -a rpm/*.patch ${BUILDAREA}/SOURCES || true

# Build RPMs
BUILDAREA=`readlink -fn ${BUILDAREA}`   ### rpm wants absolute path
rpmbuild -ba --define "_topdir ${BUILDAREA}" ceph.spec # --define "_smp_mflags -j4" --define "dist .el7" 

popd

popd
