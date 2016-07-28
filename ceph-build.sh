#!/bin/sh -x
set -e

TAG=${1:-"master"}

SRCDIR=/working
BUILDAREA=/root/rpmbuild

mkdir -p ${SRCDIR}
pushd ${SRCDIR}

git clone git://github.com/ceph/ceph

pushd ${SRCDIR}/ceph
git checkout ${TAG}

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

# Actually build the project

# clear out any $@ potentially passed in
set --

# enable ccache if it is installed
export CCACHE_DIR="$HOME/.ccache"
if command -v ccache >/dev/null; then
  if [ ! -e "$CCACHE_DIR" ]; then
    echo "$0: have ccache but cache directory does not exist: $CCACHE_DIR" 1>&2
  else
    set -- CC='ccache gcc' CXX='ccache g++'
  fi
else
  echo "$0: no ccache found, compiles will be slower." 1>&2
fi

#  Build Source tarball.  We do this after runing autogen/configure so that
#  ceph.spec has the correct version number filled in.
echo "**** Building Tarball ***"
make dist-bzip2

# Set up build area
mkdir -p ${BUILDAREA}/SOURCES
mkdir -p ${BUILDAREA}/SRPMS
mkdir -p ${BUILDAREA}/SPECS
mkdir -p ${BUILDAREA}/RPMS
mkdir -p ${BUILDAREA}/BUILD
cp -a ceph-*.tar.bz2 ${BUILDAREA}/SOURCES/.
cp -a rpm/*.patch ${BUILDAREA}/SOURCES || true

# Build RPMs
BUILDAREA=`readlink -fn ${BUILDAREA}`   ### rpm wants absolute path
rpmbuild -ba --define "_topdir ${BUILDAREA}" --define "_smp_mflags -j4" --define "dist .el7" ceph.spec

popd

popd
