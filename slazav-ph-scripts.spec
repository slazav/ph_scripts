Name: slazav-ph-scripts
Version: 0.2
Release: alt1
Group: Graphics
License: GPL
Packager: Vladislav Zavjalov <slazav@altlinux.org>
BuildArch: noarch

Summary: Scripts for digital photo handling

Source0: %name-%version.tar

%description
Scripts for digital photo handling

%prep
%setup

%build

%install
%makeinstall

%files
%_bindir/*

%changelog
* Fri Nov 13 2009 Vladislav Zavjalov <slazav@altlinux.org> 0.2-alt1
- new scripts:
  pd_init, ph_canon_rename, ph_update_www, ph_exif,
  ph_addgeo, addphoto_mkfig, addphoto_cleanup
- rewrite on shell: addphoto, addphoto_ini
- cleanup all ph_* scripts, fix help messages
- add Readme files in core and pd directories
- spec: BuildArch: noarch
- don't use libshell
- fix Makefile

* Thu Oct 22 2009 Vladislav Zavjalov <slazav@altlinux.org> 0.1-alt1
- core
  - addphoto
  - addphoto_ini
  - ph_size
  - ph_resize
  - ph_towww
