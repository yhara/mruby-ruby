# mruby/ruby

An mruby VM written with Ruby.

## Motivation

It is the best way to read [the source code](https://github.com/mruby/mruby) to learn mruby internal. However it is not so easy if you are not familiar with C. `mruby/ruby` illustraets how .mrb is executed in the language you (may) already know, Ruby.

## Project status

- Just started

## Setup

1. Install mruby 3.3.0
  - On Mac, use homebrew to install
  - On Linux, if you are using rbenv, you can install it with rbenv -- but this does not work because we want to run ruby and mruby at the same time.
    - You can build mruby with ruby-build like `~/.rbenv/plugins/ruby-build/bin/ruby-build mruby-3.3.0 /home/yhara/bin/mruby`
      and then set the `PATH` include it.
