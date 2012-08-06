bindir?=/usr/bin
datadir?=/usr/share
INSTALL?=/usr/bin/install

SCRIPTS=\
  addphoto\
  addphoto_cleanup\
  addphoto_ini\
  addphoto_mkfig\
  ph_addgeo\
  ph_canon_rename\
  ph_exif\
  ph_resize\
  ph_size\
  ph_towww\
  ph_update_www

all:

install:
	mkdir -p -- "$(bindir)"
	$(INSTALL) -Dpm 755 $(SCRIPTS) "$(bindir)"
	$(INSTALL) -Dpm 644 addphoto.pm "$(datadir)/perl5"

install-extra:
	make -C extra install
