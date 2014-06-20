## About

The ViM SmartComment plugin helps commenting and uncommenting code in ViM.

## Installation

Suggested installation mode is via [vundle](http://github.com/gmarik/vundle)

## Usage

Once installed, it adds two mappings:

* Ctrl-C to comment
* Ctrl-F to uncomment

It tries to recognize the commenting style from the file type (looking at the
ViM options `&comments` and `&commentstring`).

Comment delimiters are divided between line-comments (e.g. `//` in C++), which
act until the end of a line, and range-comments (e.g. `/*`, `*/` in C++), which
can span (possibily multi-line) regions.

When invoked in visual mode, SmartComment tries to comment out/uncomment the selected
portion of text. Otherwise, it comments out/uncomments a whole line.

Its 'smartest' feature is that it tries to avoid nested comments; e.g. if you have a
line like this

```C
int myfunc(int a, /*int b, */int c)
```

and you visually select everything within the parentheses and press Ctrl-C, you get:

```C
int myfunc(/*int a, *//*int b, *//*int c*/)
```

In case the automatic recognition of the comment delimiters fails, they can be set
manually, e.g. in C/C++:

```vim
:call SetCommentVars('//', ['/*', '*/'])
```

## Known issues

* in visual mode, it relies on syntax highlighting to detemine when the start and
  end of the selection fall within an already commented region. This may fail if
  the filetype plugin uses some weird names for highlighting regions, or when mixing
  line and region comments (see below)
* it happily mixes line comments and "region" comments; usage consistency is up
  to the user
* it assumes that region comments can not be nested (this is the case e.g. for C++);
  there is currently no way to teach it about languages which allow nesting
* some exotic commenting rules are not well supported, e.g. for Matlab files
* untested on file types which I don't normally use.
