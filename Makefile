RELEASE=3.0

GLUSTERFSVER=3.4.1
DEBRELEASE=1

GLUSTERFSSRC=glusterfs_${GLUSTERFSVER}.orig.tar.gz
GLUSTERFSDIR=glusterfs-${GLUSTERFSVER}
DEBSRC=glusterfs_${GLUSTERFSVER}-${DEBRELEASE}.debian.tar.gz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell cat .git/refs/heads/master)
SOURCETXT="git clone git://git.proxmox.com/git/glusterfs.git\\ngit checkout ${GITVERSION}"

DEBS=									\
	glusterfs-common_${GLUSTERFSVER}-${DEBRELEASE}_${ARCH}.deb	\
	glusterfs-client_${GLUSTERFSVER}-${DEBRELEASE}_${ARCH}.deb 	\
	glusterfs-server_${GLUSTERFSVER}-${DEBRELEASE}_${ARCH}.deb

all: deb

.PHONY: dinstall
dinstall: deb
	dpkg -i ${DEBS}

.PHONY: deb
deb ${DEBS}: ${GLUSTERFSSRC} ${DEBSRC}
	rm -rf ${GLUSTERFSDIR}
	tar xf ${GLUSTERFSSRC}
	cd ${GLUSTERFSDIR}; tar xvf ../${DEBSRC}
	echo "${SOURCETXT}" > ${GLUSTERFSDIR}/debian/SOURCE
	echo "debian/SOURCE" >>${GLUSTERFSDIR}/debian/glusterfs-server.docs
	echo "debian/SOURCE" >>${GLUSTERFSDIR}/debian/glusterfs-common.docs
	echo "debian/SOURCE" >>${GLUSTERFSDIR}/debian/glusterfs-client.docs
	cd ${GLUSTERFSDIR}; dpkg-buildpackage -b -uc -us

.PHONY: upload
upload:
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o rw 
	mkdir -p /pve/${RELEASE}/extra
	rm -rf /pve/${RELEASE}/extra/glusterfs-common_*.deb
	rm -rf /pve/${RELEASE}/extra/glusterfs-client_*.deb
	rm -rf /pve/${RELEASE}/extra/glusterfs-server_*.deb
	rm -rf /pve/${RELEASE}/extra/Packages*
	cp ${DEBS} /pve/${RELEASE}/extra
	cd /pve/${RELEASE}/extra; dpkg-scanpackages . /dev/null > Packages; gzip -9c Packages > Packages.gz
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o ro

.PHONY: clean
clean:
	rm -rf *~ *_${ARCH}.deb *_${ARCH}.udeb *.changes *.dsc ${GLUSTERFSDIR}
