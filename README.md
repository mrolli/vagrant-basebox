This repository contains definitions and files necessary for recreating vagrant base boxes. They are primary for my personal use but you might find them usefull too though. This repo is heavily influenced by <https://raw.github.com/puppetlabs/puppet-vagrant-boxes/>.

The primary goal is to create boxes that have very little specialisation at this level, the standard veewee templates should be very rarely modified to keep it simple, and even then bug fix should always be feed back to upstream (ie. VeeWee). This holds for any bugs we find in the templates, and any new templates that are required. In short my goal here is not to fork VeeWee templates, but to provide a snapshot of the template at box build/publish time in manner that's useful for me.

## Environment setup

You'll need Ruby 1.9.3 and Bundler before you begin. Personally I'm using rbenv on OS X to manage ruby. You should also install a copy of Vagrant from the instructions provided here:

<http://downloads.vagrantup.com/>

Once you have vagrant installed, start by entering the directory where you have cloned this project:

    $ cd <path to repo>

Then install the bundle:

    $ bundle install

If you're using rbenv-binstubs and rbenv-gem-rehash like me, use these commands instead:

    $ bundle install --binstubs
    $ rbenv rehash

## Adding a new definition

Note: Change the base command between vbox or fusion depending on your target provider.

Get a list of available definitions:

    $ veewee [vbox|fusion] templates

Pick one, and define it using:

    $ veewee [vbox|fusion] vbox define '<box_name>' '<template_name>'

Make sure <box_name> follows the convention:

    <osdistro>-<derivative>-<version>-<arch>-<virtual-type>-<variant>

    * osdistro: for example: centos, ubuntu, windows
    * derivative: (optional) server, desktop
    * version: 8, 2008, 1104
    * arch: amd64, i386
    * virtual-type: type & version. For example: vbox4210, fusion503
    * variant (optional):
    * nocm: designates no configuration management tools were loaded

Examples:

    ubuntu-server-1104-x64-vbox410
    centos-58-i386-vbox410
    windows-2008r2-x64-vbox410
    debian-607-x64-vbox410-nocm
    centos-64-x64-fusion503

Naming caveats:

* The name becomes the hostname of the box ... so you have to be careful.
* Debian/Ubuntu doesn't like underscores in the name.
* A dot in the box name would create a subdomain, which is probably not desirable.

Finally, follow the next steps for building a box.

## Building a box

Pick a box to build:

    $ veewee [vbox|fusion] list

To build it:

    $ veewee [vbox|fusion] build <box-name>

At this point it will download necessary ISO's and start building a box.

Now validate the box:

    $ veewee [vbox|fusion] validate <box-name>

And export the vm to a .box file:

    $ veewee [vbox|fusion] export <box-name>

## Using a box

Make box available to vagrant (once):

    $ vagrant box add <vagrant-box-name> <box-name>.box

And use it in your project:

    $ mkdir projectdir
    $ cd projectdir
    $ vagrant init <vagrant-box-name>
