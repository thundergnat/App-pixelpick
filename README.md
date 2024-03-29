NAME pixelpick
==============

Get the color of any screen pixel in an X11 environment.

Simple command-line app to allow you to get the RGB color of ___any___ screen pixel in an X11 environment, even those controlled by another application.

### Install

    zef install App::pixelpick

Needs to have the `import` utility available. Installed part of the `MagickWand` package. Most Linuxes have it already, if not, install ` libmagickwand`. May want to install `libmagickwand-dev` as well, though it isn't strictly necessary for this app.

    sudo apt-get install libmagickwand-dev

For Debian based distributions.

Uses the `X11::libxdo` module for mouse interaction so will only run in an X11 environment.

Use
---

### Interactive:

    pixelpick <--distance=Int> <--list=COLOR,LISTS>

If invoked with no positional parameters, runs in interactive mode. Will get the color of the pixel under the mouse pointer and show the RGB values in both decimal and hexadecimal formats and will display a small block colored to that value. Will also display colored blocks of "Named colors", along with their RGB values, that are "near" the selected color.

Will accept an Integer "distance" parameter at the command line to fine tune the cutoff for what is "near". (Defaults to 20. More than about 80 or so is not recommended. You'll get unusefully large numbers of matches.) Will always return at least one "nearest" color, no matter what the threshold is. The colors may not be exact, they are just the nearest found in the list.

Uses the XKCD CSS3 and X11 color name lists from the Color::Names module by default as its list of known colors.

See [XKCD color blocks](https://www.w3schools.com/colors/colors_xkcd.asp), [W3 CSS 3 standard web colors](https://www.w3schools.com/cssref/css_colors.asp), and [X11 color blocks](https://www.w3schools.com/colors/colors_x11.asp).

If different color lists are desired, pass in a comma joined list of names. Any of the lists supported by `Color::Names:api<2>` may be used.

    X11 XKCD CSS3 X11-Grey NCS NBS Crayola Resene RAL-CL RAL-DSP FS595B FS595C

as of this writing. The (case-sensitive) names must be in one contiuous string joined by commas. E.G.

    pixelpick --list=Crayola,XKCD

Updates moderately slowly as the mouse is moved. There is some delay just to slow down the busy loop of checking to see if the mouse has moved. Will not attempt to update if the mouse has not moved. Uses the `X11::xdo` module to capture mouse motion so will only work in an X11 environment.

Note that screen sub-pixel dithering may lead to some unexpected values being returned, especially around small text. The utility returns what the pixel color ***is***, not what it is perceived to be.

When in interactive mode, you need to send an abort signal to exit the utility. Control-C will reset your terminal to its previous settings and do a full clean-up. If you want to keep the color block and values around, do Control-Z instead. That will also reset the terminal, but will not clean up as much, effectively leaving the last values displayed.

### Non-interactive: (Get the color of the pixel at 100, 200)

    pixelpick 100 200 (--distance=Int)

If invoked with X, Y coordinates, (--distance parameter optional) runs non-interactive. Gets the pixel color at that coordinate and exits immediately, doing the partial cleanup as you would get from Control-Z.

### Non-interactive, quiet: (Get the RGB values of the pixel at 100, 200)

    pixelpick 100 200 q

Add a truthy value as a "quiet" parameter to not return the standard color parameters and block. Only returns the RGB values in base 10 separated by colons. EG. `RRR:GGG:BBB`

If you would prefer to receive hex values, use an 'h' as the quiet parameter. Returns the RGB values in hexadecimal, separated by colons; `RR:GG:BB`.

    pixelpick 100 200 h

Author
======

2019 thundergnat (Steve Schulze)

This package is free software and is provided "as is" without express or implied warranty. You can redistribute it and/or modify it under the same terms as Perl itself.

License
=======

Licensed under The Artistic 2.0; see LICENSE.

