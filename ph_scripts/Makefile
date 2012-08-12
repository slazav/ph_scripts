bindir?=/usr/bin
datadir?=/usr/share
INSTALL?=/usr/bin/install

SCRIPTS=\
  addphoto\
  addphoto_img\
  addphoto_cleanup\
  addphoto_ini\
  addphoto_mkfig\
  ph_addgeo\
  ph_resize

all:

install:
	mkdir -p -- "$(bindir)"
	$(INSTALL) -Dpm 755 $(SCRIPTS) "$(bindir)"
	$(INSTALL) -Dpm 644 addphoto.pm "$(datadir)/perl5"

install-extra:
	make -C extra install
