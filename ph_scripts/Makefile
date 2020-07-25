bindir?=/usr/bin
datadir?=/usr/share
INSTALL?=/usr/bin/install

SCRIPTS=\
  addphoto2\
  addphoto_mkfig\
  ph_addgeo\
  ph_resize

all:

install:
	mkdir -p -- "$(bindir)" "$(datadir)/perl5"
	$(INSTALL) -Dpm 755 $(SCRIPTS) "$(bindir)"

install-extra:
	make -C extra install
