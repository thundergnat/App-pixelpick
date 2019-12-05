use Test;

my $magick = qx/import --help/;

is $magick.substr(0,20), 'Version: ImageMagick', 'Imagemagick import utility is available';

done-testing;
