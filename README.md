This project contains a loose collection of Perl 5 scripts that
give you better insight into your weapons and armor of the
[Tau Station](https://taustation.space) Universe.

On each station where I have storage space, I visit the storage space, and
save the page (HTML only) as a file named `storage-XXX.html`, where XXX
is a shorthand for the station, so `YoG` for *Yards of Gadani* etc.

The tools all take a list of HTML file names as input, you can call them as

    $ ./unique-items.pl storage-*.html
    $ ./storage.pl storage-*.html

etc.

The scripts do:

* `unique-items.pl` prints a list of unique armor and weapons
* `storage.pl` produces a list of all items, including many properties, as CSV
* `armor-classification.pl` ranks armor
* `weapon-classification.pl` ranks weapons

## Disclaimer

These are quick-and-dirty one-off scripts, and do not reflect the author's
style or quality of work when developing production-ready software.

## License

All code and documentation in this repository is available under the MIT license:

Copyright 2018 Moritz Lenz (and other contributors, as apparent by running `git log`).

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
