INSTALL=/usr/bin/install

DIRS={base,pd}

all:

install:
	mkdir -p -- $(bindir)
	for i in $(DIRS)/*; do\
	  [ "$${i##*/}" != Readme ] || continue;\
	  $(INSTALL) -Dpm 755 "$$i" "$(bindir)/$${i##*/}";\
	done
