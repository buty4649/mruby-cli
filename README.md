# mruby CLI
A utility for setting up a CLI with [mruby](https://www.mruby.org) that compiles binaries to Linux, OS X, and Windows.

## Prerequisites
You'll need the following installed and in your `PATH`:

* [mruby-cli](https://github.com/hone/mruby-cli/releases)
* [Docker](https://docs.docker.com/installation/)
* [Docker Compose](https://docs.docker.com/compose/install/)

On Mac OS X and Windows, [Docker Toolbox](https://www.docker.com/toolbox) is the recommended way to install Docker and docker-compose (does not work on windows).

## Building a CLI app
To generate a new mruby CLI, there's a `--setup` option.

```sh
$ mruby-cli --setup <app name>
```

This will generate a folder `<app name>` containing a basic skeleton for getting started. Once you're in the folder, you can build all the binaries:

```sh
$ docker-compose run compile
```

You'll be able to find the binaries in the following directories:

* Linux (64-bit): `build/x86_64-pc-linux-gnu/bin`
* Linux (32-bit): `build/i686-pc-linux-gnu/bin`
* OS X (64-bit): `build/x86_64-apple-darwin14/bin/`
* OS X (32-bit): `build/i386-apple-darwin14/bin`
* Windows (64-bit): `build/x86_64-w64-mingw32/bin/`
* Windows (32-bit): `build/i686-w64-mingw32/bin`

You should be able to run the respective binary that's native on your platform. There's a `shell` service that can be used as well. In the example below, `mruby-cli --setup hello_world` was run.

```sh
$ docker-compose run shell
root@3da278e931fc:/home/mruby/code# mruby/build/host/bin/hello_world
Hello World
```

### On Windows system

When running on a windows system `docker-compose run`, you need to add the flag
`-d`. For instance, `docker-compose run -d compile`. If you don't add it, you
will got the following error:

```
[31mERROR
Please pass the -d flag when using `docker-compose run`.
```

## Docker

Each app will be generated with a Dockerfile that inherits a base image.

You can pull the image from docker hub here:
https://registry.hub.docker.com/u/hone/mruby-cli/

The Dockerfile for the base image is available on github:
https://github.com/hone/mruby-cli-docker

## Hello World

Building the canonical hello world example in mruby-cli is quite simple. The two files of note from the generate skeleton are `mrblib/hello_world.rb` and `mrbgem.rake`. The CLI hooks into the `__main__` method defined here and passes all the arguments as `argv`.

`mrblib/hello_world.rb`:
```ruby
def __main__(argv)
  puts "Hello World"
end
```

### Dependencies
The rubygems equivalent is mrbgems. [mgem-list](https://github.com/mruby/mgem-list) contains a list of mgems you can pull from. By default mruby does not include everything in the kitchen sink like MRI. This means to even get `puts`, we need to include the `mruby-print`. The list of core gems can be found [here](https://github.com/mruby/mruby/tree/master/mrbgems). Adding dependencies is simple, you just need to add a line near the bottom of your `mrbgem.rake` with the two arguments: name and where it comes from.

`mrbgem.rake`:
```ruby
MRuby::Gem::Specification.new('hello_world') do |spec|
  spec.license = 'MIT'
  spec.author  = 'Terence Lee'
  spec.summary = 'Hello World'
  spec.bins    = ['hello_world']

  spec.add_dependency 'mruby-print', :core => 'mruby-print'
  spec.add_dependency 'mruby-mtest', :mgem => 'mruby-test'
end
```
### CLI Architecture
The app is built from two parts a C wrapper in `tools/` and a mruby part in `mrblib/`. The C wrapper is fairly minimal and executes the `__main__` method in mruby and instantiates `ARGV` and passes it to the mruby code. You won't need to touch the C wrapper. The rest of the CLI is written in mruby. You can't have subfolders in `mrblib/` but you can have as many files in `mrblib/`. All these files are precompiled into mruby bytecode The build tool for mruby is written in CRuby (MRI).

### Testing
By default, `mruby-cli` generates two kinds of tests: mtest and bintest.

#### mtest
These tests are unit tests, are written in mruby, and go in the `test/` directory. It uses the mrbgem [`mruby-mtest`](https://github.com/iij/mruby-mtest). The available methods to be used can be found [here](https://github.com/mruby/mruby/blob/master/test/assert.rb). To run the tests, just execute:

```sh
$ docker-compose run mtest
```

#### bintest
These are integration tests, are written in CRuby (MRI), and go in the `bintest/` directory. It tests the status and output of the host binary inside a docker container. To run them just execute:

```sh
$ docker-compose run bintest
```

## Examples
* `mruby-cli` itself is an app generated by `mruby-cli`, so you can explore this repo on how to build one.
* [mjruby](https://github.com/jkutner/mjruby) - replacement for jruby-launcher.
* [mruby-eso-research](https://github.com/hone/mruby-eso-research) - an app for managing crafting research in Elder Scrolls Online. It uses YAML as the data store.
* [nhk-easy-cli](https://github.com/nhk-ruby/nhk-easy-cli) - a command-line client for reading NHK News Web Easy.
* [mruby-static](https://github.com/zzak/mruby-static) - a static site generator

## mruby-cli Development

### Compile the mruby-cli binaries

This app is built as a `mruby-cli` app. To compile the binaries, you **must** type

```
docker-compose run compile
```

and find the binaries in the appropriate directories (`mruby/build/<target>/bin/`).

The docker container contains the necessary cross toolchain to compile a binary for each supported target. That's why it is checked before running a rake task if it is run inside a container.

Indeed, just using `rake compile` will not work out of the box because the main build is designed to compile on a 64-bit Linux host. It could work if you are on a 64-Linux host and you have an cross toolchain equivalent to the one we provide into the docker container.

This means that if you want to add a new rake task `my_task`, you need to add it to the `docker-compose.yml` to make it available through `docker-compose run my_task`.

### Create the releases

Just type: `docker-compose run release`

After this command finishes, you'll see the releases for each target in the `releases` directory.

### Create package

We can package the ad hoc release as deb, rpm, msi, or dmg for the following
Linux.

To create all the package, just type

```
docker-compose run package
```
