#!/usr/bin/env raku

use Color::Names:api<2>;
use Text::Center;

my $version = v1.0;

my $limit = 20; # color distance threshold limit
my $loaded;
my %c;

# Control-C exit
signal(SIGINT).tap: { sleep .1; cleanup(); print "\n" xx 50, "\e[H\e[J"; exit(0) }

# Control-Z exit
signal(SIGTSTP).tap: { sleep .1; print "\r  \n"; cleanup(); exit(0) }

my %*SUB-MAIN-OPTS = :named-anywhere;

multi MAIN (:$distance = 20, :$list = 'XKCD,X11,CSS3') {
    $loaded = $list.split: ',';
    %c = Color::Names.color-data(|$loaded) or exit;
    use X11::libxdo;
    $limit = $distance max 1;
    my $xdo = Xdo.new;
    my ($lx, $ly) = 0, 0;
    loop {
        sleep .05;
        my ($x, $y, $) = $xdo.get-mouse-location;
        next if $lx == $x and $ly == $y;
        ($lx, $ly) = $x, $y;
        try display $x, $y, |get-pixel($x, $y);
    }

    CATCH { default {} }
}


multi MAIN (
    Int $x,          # Integer x coordinate to pick
    Int $y,          # Integer y coordinate to pick
    $q = False,      # Boolean "quiet" mode, set truthy for decimal values, set to h for hex values
    :$distance = 20, # Nearest color threshold
    :$list = 'XKCD,X11,CSS3' # Default color lists
  ) {
    $loaded = $list.split: ',';
    %c = Color::Names.color-data(|$loaded) or exit;
    my ($red, $green, $blue) = get-pixel($x, $y);
    $limit = $distance max 1;
    if $q {
        $q.lc eq 'h' ??
          ( printf "%02X:%02X:%02X\n", $red, $green, $blue ) !!
          ( printf "%03d:%03d:%03d\n", $red, $green, $blue );
    } else {
        try display($x, $y, $red, $green, $blue);
        cleanup();
    }
    exit(0);
}

sub USAGE {
    say qq:to
    '========================================================================'
    ### Interactive:

    pixelpick <--distance=Int> <--list=COLOR,LISTS>

    Gets the color of the pixel under the mouse pointer, shows the RGB values in
    both decimal and hexadecimal formats, and displays a small block colored to that
    value. Also displays colored blocks of named colors, along with their RGB
    values, that are "near" the selected color.

    Accepts an Integer "distance" parameter to fine tune the cutoff for what is
    "near". (Defaults to 20.) Always returns at least one "nearest" color, no matter
    what the threshold is.

    Uses the XKCD CSS3 and X11 color name lists by default.

    If different color lists are desired, pass in a comma joined list of names. Any
    of the lists supported by `Color::Names:api<2>` may be used.

    X11 XKCD CSS3 X11-Grey NCS NBS Crayola Resene RAL-CL RAL-DSP FS595B FS595C

    E.G.

        pixelpick --list=Crayola,XKCD

    When in interactive mode, you need to send an abort signal to exit the
    utility. Control-C will reset your terminal to its previous settings and do
    a full clean-up. Control-Z also reset the terminal, but will not clean up as
    much, leaving the last values displayed.

    ### Non-interactive: (Get the color of the pixel at 100, 200)

        pixelpick 100 200 (--distance=Int)

    If invoked with X, Y coordinates, (--distance parameter optional) runs
    non-interactive. Gets the pixel color at that coordinate and exits immediately,
    doing the partial cleanup as you would get from Control-Z.

    ### Non-interactive, quiet: (Get the RGB values of the pixel at 100, 200)

        pixelpick 100 200 q

    Add a truthy value as a "quiet" parameter to not return the standard color
    parameters and block. Only returns the RGB values in base 10 separated by
    colons. EG. `RRR:GGG:BBB`

    If you would prefer to receive hex values, use an 'h' as the quiet parameter.
    Returns the RGB values in hexadecimal, separated by colons; `RR:GG:BB`.

        pixelpick 100 200 h
    ========================================================================
}

sub get-pixel ($x, $y) {

    # import is installed as part of MagickWand. Most Linuxes
    # already have it. If not, need to install libmagickwand

    my $xcolor =
      qqx/import -window root -crop 1x1+{$x-1 max 0}+{$y-2 max 0} -depth 8 txt:-/
      .comb(/<?after '#'><xdigit> ** 6/);

    |$xcolor.comb(2)».parse-base(16);
}

sub display ($x, $y, $r, $g, $b) {
    # Uses sensitivity scaling values from wikipedia:Color_difference to search
    # for "nearby" colors. Adjust $distance ($limit) to expand or reduce search
    # space. # 25 seems like a reasonble tradeoff between too-much and
    # not-enough. # Allows passing  a threshold parameter as a command line
    # option to adjust the definition of "near".

    my @c;
    my $threshold = $limit;

    my $cols = 70;

    repeat { # Find at least one close color
        @c = %c.grep: {
            3 * abs($r - .value<rgb>[0]) < $threshold and
            4 * abs($g - .value<rgb>[1]) < $threshold and
            2 * abs($b - .value<rgb>[2]) < $threshold
        }
        $threshold += 2;
    } until @c.elems;

    my $match = @c.first( {
          $r == .value<rgb>[0] and
          $g == .value<rgb>[1] and
          $b == .value<rgb>[2]
    } );

    my $mfg = (sqrt(sum $r², $g²) > 200) ?? "\e[38;2;0;0;0m" !! "\e[38;2;255;255;255m";
    if $match {
        my $code = ($match.value<code>) ?? " - {$match.value<code>}" !! '';
        $match = center($match.key.split('-')[1] ~ ': ' ~ $match.value<name> ~ $code, $cols);
    } else {
        $match = center('No exact match', $cols);
    }

    try print "\e[?25l\e[48;2;0;0;0m\e[38;2;255;255;255m\e[H\e[J";
    try printf "  v$version  |  x: %4d y:  $y\n", $x;
    try printf "  RGB: %03d:%03d:%03d     HEX: %02X:%02X:%02X\n",
            $r, $g, $b, $r, $g, $b;
    try print "\e[48;2;{$r};{$g};{$b}m$mfg",
           ' ' x $cols, "\n",
           ' ' x $cols, "\n",
           $match // (' ' x $cols),
           "\n",
           ' ' x $cols, "\n",
           ' ' x $cols, "\n",
           "\e[48;2;0;0;0m\e[38;2;255;255;255m";

    try say "Nearby ($loaded) named colors:";


    for @c.sort -> $c {
        my $fg = (sqrt(sum $c.value<rgb>[0]², $c.value<rgb>[1]²) > 200)
        ?? [0,0,0] !! [255,255,255];
        try say "\e[48;2;{$c.value<rgb>[0]};{$c.value<rgb>[1]};{$c.value<rgb>[2]}m" ~
            "\e[38;2;{$fg[0]};{$fg[1]};{$fg[2]}m" ~
            try sprintf(" %8s RGB:%03d:%03d:%03d - HEX:%02X:%02X:%02X - %-{$cols - 43}s",
                $c.key.split('-')[1],
                |$c.value<rgb>, |$c.value<rgb>, $c.value<name>
            );
    }
    say '';


}

sub cleanup { print "\e[0m\e[?25h" }


=begin pod

=head1 NAME pixelpick

Get the color of any screen pixel in an X11 environment.

Simple command-line app to allow you to get the RGB color of ___any___ screen
pixel in an X11 environment, even those controlled by another application.

=head3 Install

    zef install App::pixelpick

Needs to have the `import` utility available. Installed part of the `MagickWand`
package. Most Linuxes have it already, if not, install ` libmagickwand`. May
want to install `libmagickwand-dev` as well, though it isn't strictly necessary
for this app.

    sudo apt-get install libmagickwand-dev

For Debian based distributions.

Uses the C<X11::libxdo> module for mouse interaction so will only run in an X11
environment.

=head2  Use

=head3 Interactive:

    pixelpick <--distance=Int> <--list=COLOR,LISTS>

If invoked with no positional parameters, runs in interactive mode. Will get the
color of the pixel under the mouse pointer and show the RGB values in both
decimal and hexadecimal formats and will display a small block colored to that
value. Will also display colored blocks of "Named colors", along with their RGB
values, that are "near" the selected color.

Will accept an Integer "distance" parameter at the command line to fine tune the
cutoff for what is "near". (Defaults to 20. More than about 80 or so is not
recommended. You'll get unusefully large numbers of matches.) Will always return
at least one "nearest" color, no matter what the threshold is. The colors may
not be exact, they are just the nearest found in the list.

Uses the XKCD CSS3 and X11 color name lists from the Color::Names module by
default as its list of known colors.

See L<XKCD color blocks|https://www.w3schools.com/colors/colors_xkcd.asp>, L<W3 CSS 3 standard web colors|https://www.w3schools.com/cssref/css_colors.asp>,
and L<X11 color blocks|https://www.w3schools.com/colors/colors_x11.asp>.


If different color lists are desired, pass  in a comma joined list of names. Any
of the lists supported by C<Color::Names:api<2>> may be used.

    X11 XKCD CSS3 X11-Grey NCS NBS Crayola Resene RAL-CL RAL-DSP FS595B FS595C

as of this writing. The (case-sensitive) names must be in one contiuous string
joined by commas. E.G.

    pixelpick --list=Crayola,XKCD

Updates moderately slowly as the mouse is moved. There is some delay just to
slow down the busy loop of checking to see if the mouse has moved. Will not
attempt to update if the mouse has not moved. Uses the `X11::xdo` module to
capture mouse motion so will only work in an X11 environment.

Note that screen sub-pixel dithering may lead to some unexpected values being
returned, especially around small text. The utility returns what the pixel color
***is***, not what it is perceived to be.

When in interactive mode, you need to send an abort signal to exit the utility.
Control-C will reset your terminal to its previous settings and do a full
clean-up. If you want to keep the color block and values around, do Control-Z
instead. That will also reset the terminal, but will not clean up as much,
effectively leaving the last values displayed.

=head3 Non-interactive: (Get the color of the pixel at 100, 200)

    pixelpick 100 200 (--distance=Int)

If invoked with X, Y coordinates, (--distance parameter optional) runs
non-interactive. Gets the pixel color at that coordinate and exits immediately,
doing the partial cleanup as you would get from Control-Z.

=head3 Non-interactive, quiet: (Get the RGB values of the pixel at 100, 200)

    pixelpick 100 200 q

Add a truthy value as a "quiet" parameter to not return the standard color
parameters and block. Only returns the RGB values in base 10 separated by
colons. EG. `RRR:GGG:BBB`


If you would prefer to receive hex values, use an 'h' as the quiet parameter.
Returns the RGB values in hexadecimal, separated by colons; `RR:GG:BB`.

    pixelpick 100 200 h

=head1 Author

2019  thundergnat (Steve Schulze)

This package is free software and is provided "as is" without express or implied
warranty. You can redistribute it and/or modify it under the same terms as Perl
itself.

=head1 License

Licensed under The Artistic 2.0; see LICENSE.

=end pod
