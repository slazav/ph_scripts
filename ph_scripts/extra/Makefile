bindir?=/usr/bin
INSTALL?=/usr/bin/install

SCRIPTS=\
  pd_init

all:

install:
	mkdir -p -- "$(bindir)"
	$(INSTALL) -Dpm 755 $(SCRIPTS) "$(bindir)"
