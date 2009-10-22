BINDIR=$(prefix)/usr/bin
INSTALL=/usr/bin/install

DIRS=base

all:

install:
	for i in $(DIRS)/*; do\
	  $(INSTALL) -Dpm 755 "$$i" "$(BINDIR)/$${i##*/}";\
	done
