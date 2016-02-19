CLIBS= 
CFLAGS=-O -Wall
YFLAGS=-d
YACC=yacc
CC=cc

OBJECTS=y.tab.o keyval.o strlist.o funcinfo.o mufprims.o strutils.o
TARGET=muv

muv: ${OBJECTS}
	${CC} ${CFLAGS} -o $@ ${OBJECTS} ${CLIBS}

*.o: *.c
	${CC} ${CFLAGS} -c $< -o $@

y.tab.c: parse_rules.y
	${YACC} ${YFLAGS} parse_rules.y

clean:
	rm -f core ${TARGET} ${OBJECTS} y.tab.c y.tab.h *.output *.vcg *.tab.c *.tab.h

