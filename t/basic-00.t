use Test;

die 'Needs to have an X11 widowing system available.'
  unless shell(qw<echo $DISPLAY>, :out).out.slurp.words > 0;

my $magick = qx/import -help/;

is $magick.substr(0,20), 'Version: ImageMagick', 'Imagemagick import utility is available';

done-testing;
