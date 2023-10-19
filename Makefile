bindir?=/usr/bin
INSTALL?=/usr/bin/install

SCRIPTS=\
  ph_addgeo\
  ph_savegeo\
  pd_arc\
  pd_norm\


all:

install:
	mkdir -p -- "$(bindir)"
	$(INSTALL) -Dpm 755 $(SCRIPTS) "$(bindir)"

install-extra:
	make -C extra install
