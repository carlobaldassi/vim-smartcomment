## About

The ViM SmartComment plugin helps commenting and uncommenting code in ViM.

## Installation

Suggested installation mode is via [vundle](http://github.com/gmarik/vundle)

## Usage

Once installed, it adds two mappings:

* Ctrl-C to comment
* Ctrl-F to uncomment

It tries to recognize the commenting style from the file type (looking at the
ViM options '&comments' and '&commentstring').

Comment delimiters are divided between line-comments (e.g. `//` in C++), which
act until the end of a line, and range-comments (e.g. `/*`, `*/` in C++), which
can span (possibily multi-line) regions.

When invoked in visual mode, SmartComment tries to comment out the selected
portion of text. Otherwise, it comments out a whole line.

Its 'smartest' feature is that it tries to avoid nested comments.

In case the automatic recognition fails, comment delimiters can be set manually,
e.g. in C/C++:
```vim
:call SetCommentVars('//', ['/*', '*/'])
```

## Known issues

* it only looks for comment delimiters within the selected region, therefore
  it does not recognize when the region is strictly included within an already
  commented region (vim syntax highlight should help you there, though)
* it happily mixes line comments and "region" comments; usage consistency is up
  to the user
