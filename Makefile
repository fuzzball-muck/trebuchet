#!/bin/make -f

CP=cp -f
RM=rm
MV=mv
LN=ln
MKDIR=./mkdir_recursive


MAINEXEC=Trebuchet.tcl

# The root of the directory tree to install to.
prefix=/usr/local
exec_prefix=${prefix}
# Destinations for files
bindir=${exec_prefix}/bin
ROOT=${prefix}/libexec/trebuchet

REVISION=`head -1 changes.txt | cut -c8- | tr -d '\r'`

all:
	# Nothing to compile.

check:
	procheck lib/*.tcl ${MAINEXEC}

debug:
	prodebug trebtk.tpj

install:
	find . ! \( \
		    \( -name 'CVS' -type d -prune \) -o \
		    \( -name 'Makefile.*' -type f -prune \) -o \
		    \( -name '*.txt' -type f -prune \) -o \
		    \( -name '*.spec' -type f -prune \) -o \
		    \( -name '*.tar.gz' -type f -prune \) \
		\) \( \
		    \( \
			-type d \
			-exec ${MKDIR} ${ROOT}/{} \; \
			-exec chmod 755 ${ROOT}/{} \; \
		    \) -o \( \
			-type f \
			\( -name '*.tcl' -o -name '*.trh' -o \
			   -name '*.gif' -o -name '*.jpg' -o \
			   -name '*.dat' -o -name '*.pem' \) \
			-exec ${CP} {} ${ROOT}/{} \; \
			-exec chmod 644 ${ROOT}/{} \; \
		    \) \
		\)
	chmod 755 ${ROOT}/${MAINEXEC}
	${MKDIR} ${bindir}
	${RM} -f ${bindir}/treb
	${LN} -s ../libexec/trebuchet/${MAINEXEC} ${bindir}/treb

trebspec:
	sed 's/^\(.define *version *\).*/\1'${REVISION}/ trebuchet.spec > trebuchet.spec.tmp
	${MV} -f trebuchet.spec.tmp trebuchet.spec
	${RM} -f trebuchet.spec.tmp
	${RM} -f trebuchet.spec.tmp2

package:
	${RM} -rf trebuchet-${REVISION}
	${RM} -f trebuchet-${REVISION}.tar
	${RM} -f trebuchet-${REVISION}.tar.gz
	${MKDIR} trebuchet-${REVISION}
	find * ! \( \
		    \( -name 'CVS' -type d -prune \) -o \
		    \( -name 'trebuchet-*' -type d -prune \) -o \
		    \( -name '*.rpm' -type f -prune \) \
		\) \( \
		    \( \
			    -type d \
			    -exec ${MKDIR} trebuchet-${REVISION}/{} \; \
			    -exec chmod 755 trebuchet-${REVISION}/{} \; \
		    \) -o \( \
			    -type f \
			    -exec ${CP} {} trebuchet-${REVISION}/{} \; \
			    -exec chmod 644 trebuchet-${REVISION}/{} \; \
		    \) \
		\)
	${RM} -f trebuchet-${REVISION}/trebuchet.spec
	find trebuchet-${REVISION} -type d -exec chmod 755 {} \;
	find trebuchet-${REVISION} -type f -exec chmod 644 {} \;
	chmod 755 trebuchet-${REVISION}/mkdir_recursive
	chmod 755 trebuchet-${REVISION}/${MAINEXEC}
	tar cf trebuchet-${REVISION}.tar trebuchet-${REVISION}
	gzip trebuchet-${REVISION}.tar
	${RM} -rf trebuchet-${REVISION}

rpm: trebspec package
	rpmbuild -ta --target noarch trebuchet-${REVISION}.tar.gz

dmg:
	cd ../Tcl && ./mktreb


clean:
	rm -rf trebuchet-*.tar.gz

# #######################################################################
# #######################################################################

# DO NOT DELETE THIS LINE -- make depend depends on it.
