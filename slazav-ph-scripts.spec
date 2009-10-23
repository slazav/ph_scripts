Name: slazav-ph-scripts
Version: 0.1
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
* Thu Oct 22 2009 Vladislav Zavjalov <slazav@altlinux.org> 0.1-alt1
- core
  - addphoto
  - addphoto_ini
  - ph_size
  - ph_resize
  - ph_towww
