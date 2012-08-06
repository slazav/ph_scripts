package addphoto;

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

## list all files in the directory
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

## Is first file older then second one or
## first file does not exist.
sub older($$){
  return 0 if (!-f $_[1]);
  return 1 if (!-f $_[0]);
  return (stat $_[0])[9] < (stat $_[1])[9];
}

## get image size
sub image_size($){
  `identify "$_[0]"` =~/(\d+)x(\d+)/;
  return ($1 || 0, $2 || 0);
}

### HTML writing functions

## crete TOC
## input: array of hashes with fields 'depth' and 'title'
sub mk_toc($){
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

## remove html tags from text, for html alt atribute
sub rem_html($){
  my $t=shift;
  $t=~s/<[^>]*>//g;
  $t=~s/[<>\"\']//g;
  return $t;
}

### Regular expressions for addphoto commands
our $ph_re='^\\\photo([lr]?)\s+(\S+)\s*(.*)';
our $head_re='^\\\h([1-4])(r?)\s+(.*)';
our $keep_re='^\\\keep\s+(.*)';

### EXIF

# get exif-data as a hash, convert some values
sub get_exif{
  my $file=shift;
  my $exif;
  foreach (`exiv2 -Pkv $file 2>/dev/null`){
    chomp;
    my ($k, $v) = split(/\s+/,$_,2);
    $exif->{$k}=$v;
  }

  my $n;
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


1;
