# pixel-pick

Get the color of any screen pixel in an X11 environment.

Simple command-line app to allow you to get the RGB color of ___any___ screen
pixel in an X11 environment.

### Install

    zef install perl6-App::pixel-pick


Needs to have the `import` and `convert` utilities available. Those are part of
the `MagickWand` package. Most Linuxes have them already, if not, install `
libmagickwand`. May want to install `libmagickwand-dev` as well, though it isn't
strictly necessary for this app.

### Use

#### Interactive:

    pixel-pick

If invoked with no parameters, runs in interactive mode. Will get the color of
the pixel under the mouse pointer and show the RGB values in both decimal and
hexadecimal. Will display a small block colored to that value. Updates
(moderately) slowly as the mouse is moved. There is some delay just to slow down
the "busy" loop of checking to see if the mouse has moved. Will not attempt to
update if the mouse has not moved. Uses the X11::xdo module to capture mouse
motion so will only work in an X11 environment.

Note that screen sub-pixel dithering may lead to some unexpected values being
returned, especially around small text. The utility returns what the pixel color
***is***, not what it is perceived to be.

When in interactive mode, you need to send an abort signal to exit the utility.
Control-C will reset your terminal to its previous settings and do a full
clean-up. If you want to keep the color block and values around, do Control-Z
instead. That will also reset the terminal, but will not clean up as much,
effectively leaving the last values displayed.

#### Non-interactive: (Get the color of the pixel at 100, 200)

    pixel-pick 100 200

If invoked with X, Y coordinates, runs non-interactive. Gets the pixel color at
that coordinate and exits immediately, doing the partial cleanup as you would
get from Control-Z.

#### Non-interactive, quiet: (Get the RGB values of the pixel at 100, 200)

    pixel-pick 100 200 q

Add a truthy value as a "quiet" parameter to not return the standard color
parameters and block. Only returns the RGB values in base 10 separated by
colons. EG. `RRR:GGG:BBB`


If you would prefer to receive hex values, use an 'h' as the quiet parameter.
Returns the RGB values in hexadecimal, separated by colons; RR:GG:BB.

    pixel-pick 100 200 h

#### Author

2019  thundergnat (Steve Schulze)

This package is free software and is provided "as is" without express or implied
warranty. You can redistribute it and/or modify it under the same terms as Perl
itself.

#### License

Licensed under The Artistic 2.0; see LICENSE.
