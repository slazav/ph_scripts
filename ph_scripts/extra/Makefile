bindir?=/usr/bin
INSTALL?=/usr/bin/install

SCRIPTS=\
  pd_init\
  ph_canon_rename\
  ph_towww

all:

install:
	mkdir -p -- "$(bindir)"
	$(INSTALL) -Dpm 755 $(SCRIPTS) "$(bindir)"
