# Makefile for password generator
# THVV 12/24/03 updated to build on gcc 3.3 (gets warnings on Panther, FreeBSD, and RH9)
# Unlimited use with this notice (c) 2017 George Georgalis <george@galis.org>

DICT = en_master.wl
COMPILER=gcc

all : gpw loadtris
	@#echo gpw created, can delete loadtris
	$(MAKE) clean

gpw : gpw.o
	$(COMPILER) $(DEBUGARGS) -o gpw gpw.o

trigram.h : loadtris
	aspell dump master >$(DICT)
	./loadtris $(DICT) | sed "s/, }/}/" > trigram.h

gpw.o : gpw.c trigram.h
	$(COMPILER) $(DEBUGARGS) -o gpw.o -c gpw.c
# gcc produces some warnings about long int vs double, shd fix

loadtris : loadtris.o
	$(COMPILER) $(DEBUGARGS) -o loadtris loadtris.o

loadtris.o : loadtris.c
	$(COMPILER) $(DEBUGARGS) -o loadtris.o -c loadtris.c

distclean : 
	rm -f gpw loadtris loadtris.o gpw.o trigram.h $(DICT) 

clean : 
	rm -f loadtris loadtris.o gpw.o trigram.h $(DICT) 

install :
	install -m 755 gpw /usr/local/bin

deinstall :
	rm -f /usr/local/bin/gpw
