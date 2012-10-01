#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use File::Basename;

=head1 SYNOPSIS

 convertPhoto.pl --image /path/to/image@2x.jpg --title "Title of the post" --date YYYYMMDDhhmm--tag Tag1 --tag Tag2 --tag Tag3

 The image must exist and its name must end with @2x.  For the
 purposes of this doc, we'll assume that the filename is image@2x.jpg.

This script will do the following:

=over 4

=item 1

Scale image@2x.jpg to 50% and save the scaled image as image.jpg

=item 2

Scale image@2x.jpg to 384x256 or (256x384 if portrait) and save it as the thumbnail image image_tn.jpg

=item 3

Scale image@2x.jpg to 768x512 or (512x768 if portrait) and save it as the thumbnail image image_tn@2x.jpg

=item 4

Create a 128x50 histogram of the image and save it as image_hist.jpg

=item 5

If the --title option was specified, it will invoke generatePhotoPost.pl to save the relevant information into the photo post

=item 6

If -date is specified, it will be passed on to generatePhotoPost.pl

=back

This script requires the ImageMagick set of tools.  For more information on ImageMagic, visit http://www.imagemagick.org/.

=cut    
    

my $image = '';
my $title = '';
my @tags;
my $date = '';
Getopt::Long::GetOptions(
    "image=s"     => \$image,
    "title=s"     => \$title,
    "tag=s"       => \@tags,
    "date=s"      => \$date,
    );

die "--image ($image)  not specified or does not point to an existing file" unless -f $image;

my ($baseName, $path, $suffix) = fileparse($image, qr/\.[^.]*/);

if ($baseName !~ /\@2x$/) { die "The image name should end with \@2x"; } 

my $realBase = $baseName;
$realBase =~ s/\@2x//;

my $regularImage = "$path$realBase$suffix";
my $tn = "$path${realBase}_tn$suffix";
my $tn2 = "$path${realBase}_tn\@2x$suffix";
my $hist = "$path${realBase}_hist.png";

# original dimensions should be 2040x1360 or 902x1356
my $img_info         = `identify $image`;
my @info_list        = split(/ /, $img_info);
my ($width, $height) = $info_list[2] =~ /(\d+)x(\d+)/;


doSys("convert $image -resize '50%' $regularImage");

if ($width > $height) { 
    doSys("convert $image -resize  '384x256' $tn");
    doSys("convert $image -resize  '768x512' $tn2");
}
else { 
    doSys("convert $image -resize  '256x384' $tn");
    doSys("convert $image -resize  '512x768' $tn2");
}
doSys("convert $image -define histogram:unique-colors=false  histogram:$hist");
doSys("mogrify -format png -fuzz 40% -fill \"#999999\" -opaque \"#000000\" -resize 128x50! $hist");

my $tags = join (" ", (map { "--tag '$_'"} @tags));

if ($title) {
    if ($date) {
        doSys("./generatePhotoPost.pl --image $regularImage --thumbnail $tn --title '$title' --date $date --histogram $hist $tags");
    }
    else { 
        doSys("./generatePhotoPost.pl --image $regularImage --thumbnail $tn --title '$title' --histogram $hist $tags");
    }
}


 sub doSys {
    my $cmd = shift;
    print "SYS: $cmd\n";
    my $a = `$cmd`;
    die $@ if $?;
}
