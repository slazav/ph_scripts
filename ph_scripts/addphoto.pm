package addphoto;

#### MESSAGES

our %msg = (
  dat_fmt => '���� � ����� ������: %s',
  alt_fmt => '������: %d �',
  crd_fmt => '����������: %s',
  pref => '&lt;&lt; ����������',
  uref => '� ����������',
  nref => '��������� &gt;&gt;',
  mark_sw => '��� ���������� ������� �������� ����� �� ��������',
);

# some settings:
our $fig_res = 14.2875; # convert pixel -> fig units
our $html_charset = 'koi8-r';
our $fig_lang = 'ru_RU.KOI8-R';
our $def_mstyle = 'aa_gif';
our $def_scale = '800:400:10000';
our $def_thscale = '200:120:600';

#### Regular expressions for addphoto commands
our $ph_re='^\\\photo([lr]?)\s+(\S+)\s*(.*)';
our $head_re='^\\\h([1-4])(r?)\s+(.*)';
our $keep_re='^\\\keep\s+(.*)';

#### FILE AND PATH FUNCTIONS

## split path into full directory name + basename + last extension
## './some/path/file.e1.e2.ext' -> './some/path/' + 'file.e1.e2' + '.ext'
sub path_split($){
  $_[0]=~m&(.*\/)?((.*)(\..*)|(.*)())&;
  return (($1 or ''), ($3 or $5 or ''), ($4 or $6 or ''));
}

## Get relative path from dir1 to dir2.
## Absolute paths, . and .. are ignored!
sub rel_dir($$){
  my @d1 = grep {/.+/ && !/^\.{1,2}$/} split '/', shift;
  my @d2 = grep {/.+/ && !/^\.{1,2}$/} split '/', shift;
  my $n;
  for ($n = 0; $n <= $#d1 && $n <= $#d2; $n++){
    last if ($d1[$n] ne $d2[$n])
  }
  my $ret='';
  $ret .= "../" foreach @d1[$n..$#d1];
  $ret .= "$_/" foreach @d2[$n..$#d2];
  return $ret;
}

## Recursively list all files in the directory.
sub read_dir{
  my @ret;
  my $dir   = shift;
  unless(opendir D, $dir){
    warn "Skipping unreadable directory $dir: $!\n";
    return;
  }
  my @list = readdir D;
  closedir D;

  foreach (@list){
    next if /^\.{1,2}$/;
    my $f = "$dir/$_";
    push(@ret, (-d $f)? read_dir($f) : $f);
  }
  return @ret;
}

## Do we need to update file1 from file2
## (is it older or does not exist)?
sub isolder($$){
  return 0 if (!-r $_[1]);
  return 1 if (!-r $_[0]);
  return (stat $_[0])[9] < (stat $_[1])[9];
}

#### IMAGE SIZE FUNCTIONS

## get image size (identify from ImageMagick is needed).
sub image_size($){
  `identify "$_[0]"` =~/(\d+)x(\d+)/;
  return ($1 || 0, $2 || 0);
}

## calculate rescaling factor:
# - "Usual" images will be scaled to fit into S1xS1 square;
# - long images will not be smaller then S2 on short edge;
# - very long images will not be larger than S3 on long edge;
# - small images will not be modified.
sub image_scfactor($$$$$){
  my ($x, $y, $m1, $m2, $m3) = @_;
  $x=1.0*$x; $y=1.0*$y;

  my $kx = $x/$m1;
  my $ky = $y/$m1;

  my $k = $kx>$ky ? $kx:$ky;

  $k = $x/$m2 if $x/$k < $m2;
  $k = $y/$m2 if $y/$k < $m2;

  $k = $x/$m3 if $x/$k > $m3;
  $k = $y/$m3 if $y/$k > $m3;

  $k = 1 if $k<=1;
  return $k;
}

## resize image
## options: scale(s1:s2:s3),quiet,dryrun
sub image_resize{
  my ($in, $out, %o) = @_;
  my ($x, $y) = image_size($in);

  my $s = $o{scale} || $def_scale;
  my ($s1, $s2, $s3) = split(':', $s);

  return unless $x && $y;
  my $k = image_scfactor($x, $y, $s1, $s2, $s3);

  if ($k == 1) {
    printf STDERR "%-20s %4d x %4d -> no changes\n", $in, $x, $y
      unless $o{quiet};
    `cp -f "$in" "$out" 1>&2` if $out ne $in && !$o{dryrun};
    return;
  }

  my ($xn, $yn) = (int($x/$k), int($y/$k));
  printf STDERR "%-20s %4d x %4d -> %3d x %3d\n", $in, $x, $y, $xn, $yn
    unless $o{quiet};

  unless ($o{dryrun}){
    if ($out ne $in){
      `convert -geometry ${xn}x${yn} "$in" "$out" || cp -f "$in" "$out" 1>&2`;
    }
    else{
      `convert -geometry ${xn}x${yn} "$in" "$in" ||: 1>&2`;
    }
  }
}


#### HTML writing functions

## remove html tags from text, for html alt atribute
sub rem_html($){
  my $t=shift;
  $t=~s/<[^>]*>//g;
  $t=~s/[<>\"\']//g;
  return $t;
}

## crete table of contents
## input: array of hashes with fields 'depth' and 'title'
sub html_toc($){
  my $hh = shift;
  my $dp=0; # prev depth
  my $d0=0; # initial depth
  for (my $i=0; $i<@{$hh}; $i++){
    my $d=$hh->[$i]->{depth};
    my $t=$hh->[$i]->{title};
    if ($dp==$d0){
      $dp=$d0=$d-1;
    }
    for (;$dp<$d;$dp++) {print '  'x($dp-1) . "<ul>\n";}
    for (;$dp>$d;$dp--) {print '  'x($dp-2) . "</ul>\n";}
    print '  'x($d-1) . "<li><a href=\"#h". ($i+1). "\">$t</a>\n";
  }
  for (;$dp>$d0;$dp--) {print '  'x($dp-2) . "</ul>\n";}
}


#### EXIF functions

## Get exif-data as a hash, convert some values to human-readable form.
## Returns hash ref with original exif fields and some converted fields:
##  dat -- Exif.Photo.DateTimeOriginal or Exif.Image.DateTime,
##  lon, lat, alt -- coordinates, altitude.
## exiv2 program is needed.
sub get_exif{
  my $file=shift;
  my $exif;
  my $n;

  # parse values from exiv2 output.
  foreach (`exiv2 -Pkv $file 2>/dev/null`){
    chomp;
    my ($k, $v) = split(/\s+/,$_,2);
    $exif->{$k}=$v;
  }

  # DateTime: convert 2009:10:20 10:11:12 -> 2009/10/20 10:11:12
  foreach $n ('Exif.Image.DateTime',
              'Exif.Photo.DateTimeOriginal'){
    if ((exists $exif->{$n}) && ($exif->{$n} =~ /^(\d+):(\d+):(\d+)\s+(\d+):(\d+):(\d+)/)){
      $exif->{dat} = "$1/$2/$3 $4:$5:$6"; }
  }

  # convert alt, lat, lon
  $n='Exif.GPSInfo.GPSAltitude';
  if ((exists $exif->{$n}) && ($exif->{$n}=~/^(\d+)\/(\d+)/)){
    $exif->{alt} = 1.0*$1/$2;
    $exif->{alt}=-$exif->{alt} if (exists $exif->{$n.'Ref'}) && ($exif->{$n.'Ref'}!=0);
  }
  $n='Exif.GPSInfo.GPSLatitude';
  if ((exists $exif->{$n}) && ($exif->{$n}=~/^(\d+)\/(\d+)\s+(\d+)\/(\d+)\s+(\d+)\/(\d+)/)){
    $exif->{lat} = 1.0*$1/$2 + 1.0/60.0*$3/$4 + 1.0/3600.0*$5/$6;
    $exif->{lat}=-$exif->{lat} if (exists $exif->{$n.'Ref'}) && ($exif->{$n.'Ref'}=~/^S/);
  }
  $n='Exif.GPSInfo.GPSLongitude';
  if ((exists $exif->{$n}) && ($exif->{$n}=~/^(\d+)\/(\d+)\s+(\d+)\/(\d+)\s+(\d+)\/(\d+)/)){
    $exif->{lon} = sprintf "%.7f", 1.0*$1/$2 + 1.0/60.0*$3/$4 + 1.0/3600.0*$5/$6;
    $exif->{lon}=-$exif->{lon} if (exists $exif->{$n.'Ref'}) && ($exif->{$n.'Ref'}=~/^W/);
  }
  return $exif;
}

## print latlon coords with or without referense to google
sub html_crd($$$){
  my ($lat, $lon, $google) = @_[0..2];
  return $google ?
    sprintf('<a href="http://maps.google.com?t=h&output=embed&' .
            'q=%.7f+%.7f&ll=%.7f,%.7f&z=13">%.7f %.7f</a><br/>',
            $lat, $lon, $lat, $lon, $lat, $lon) :
    sprintf('%.7f %.7f', $lat, $lon);
}

## print exif data in HTML for a given filename
sub html_exif($$){
  my $exif = addphoto::get_exif(shift);
  my $google = shift;
  my $ret='';

  my %fw; # wrapped format strings
  $fw{$_} = "\n      $msg{$_}<br/>"
    foreach ('dat_fmt', 'alt_fmt', 'crd_fmt');

  $ret .= sprintf($fw{dat_fmt}, $exif->{dat}) if exists $exif->{dat};
  $ret .= sprintf($fw{alt_fmt}, $exif->{alt}) if exists $exif->{alt};
  $ret .= sprintf($fw{crd_fmt}, html_crd($exif->{lat}, $exif->{lon}, $google))
                   if exists $exif->{lat} &&  exists $exif->{lon};
  return $ret;
}

#### THUMBNAILS, THMARKS and KEYS

## Thumbnail images can is marked with red dot if there are
## some marks on the image. The mark is also kept in the jpeg comment
## These two functions can add and check mark. For remothing mark
## just regenerate thumbnail...
## exiv2 and mogrify (from ImageMagick) programs are needed.
sub thmark_add($){
  my $f=shift;
  `mogrify -fill red -draw 'circle 10,10,12,12' "$f"`;
  `exiv2 -c "<marked>" "$f" 2>/dev/null`;
}
sub thmark_check($){
  my $f=shift;
  return -r $f && `exiv2 -pc "$f" 2>/dev/null` =~ /<marked>/;
}

# Key is used to check do we need to update html-file
# It is md5_hex sum of all parameters used for html-file
# generation
sub key_read($){
  return '' if ! open IN, $_[0];
  while (readline IN){return $1 if m|<!--KEY:([a-fA-F\d]*)-->|; }
  return '';
}

## get fig image dimensions in "pixels"
sub fig_im_size($$){
  my ($fig, $img) = @_;
  $img=~s|.*/||;

  open IN, $fig or return (0,0);
  while (readline IN){
    next unless (/$img/);
    readline(IN) =~
      /^\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/;
    my @x=sort($1, $3, $5, $7);
    my @y=sort($2, $4, $6, $8);
    return (($x[3]-$x[1])/$fig_res, ($y[3]-$y[1])/$fig_res);
  }
  return (0,0);
}

1;