CLIBS= 
CFLAGS=-O -Wall
YFLAGS=-d
YACC=yacc
CC=cc

PKGNAME=muv
TARGET=muv

ROOT=/usr/local
SHAREDIR=${ROOT}/share/${PKGNAME}
BINDIR=${ROOT}/bin
OBJECTS=y.tab.o keyval.o strlist.o funcinfo.o strutils.o

all: ${TARGET}

${TARGET}: configs.h ${OBJECTS}
	${CC} ${CFLAGS} ${OBJECTS} ${CLIBS} -o $@

configs.h:
	echo "#define MUV_INCLUDES_DIR \"${SHAREDIR}/incls\"" > configs.h

%.o: %.c
	${CC} -c ${CFLAGS} $< -o $@

y.tab.c: parse_rules.y
	${YACC} ${YFLAGS} parse_rules.y

clean:
	rm -f core ${TARGET} ${OBJECTS} configs.h y.tab.c y.tab.h *.output *.vcg *.tab.c *.tab.h

test: ${TARGET}
	for f in examples/*.muv ; do echo $$f ; ${TARGET} -o foo.muf $$f ; done
	rm -f foo.muf

install: ${TARGET}
	mkdir -p ${SHAREDIR}
	mkdir -p ${SHAREDIR}/incls
	mkdir -p ${SHAREDIR}/examples
	cp *.md ${SHAREDIR}
	cp -r incls/* ${SHAREDIR}/incls/
	cp -r examples/* ${SHAREDIR}/examples/
	mkdir -p ${BINDIR}
	cp ${TARGET} ${BINDIR}


