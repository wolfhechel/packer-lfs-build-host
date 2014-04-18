# packer-lfs-build-host

This is a [Packer](http://www.packer.io) template created to build a suitable build system for
[Linux From Scratch](http://www.linuxfromscratch.org) builds.

## The resulting system

Running this build will create a minimal host system built with compatibility
and minimal footprints on the resulting system.

This template ** should ** always satisfy all [requirements](http://www.linuxfromscratch.org/lfs/view/stable/prologue/hostreqs.html)
on the host system for as long as it's maintained.

The template will also setup the build partition as well as the build user,
basically all the way up to [Chapter 5](http://www.linuxfromscratch.org/lfs/view/stable/chapter05/introduction.html).

## Security

Note that this system should ** NOT ** be exposed externally due to two things:

* Both the root and build user has empty passwords.
* SSH allows empty passwords login.

If you're planing on using this system from an external network I urge you
to at least set passwords on both these users!

## Usage

Since this is a Packer template I assume you already got Packer setup and running.

This template only supports VirtualBox so far, if anybody wants to adapt this to
to VMWare feel free to do so and send a pull request.

Once you've got both Packer and VirtualBox setup, all there is to it is cloning
this repository and starting the build.

    git clone https://github.com/wolfhechel/packer-lfs-build-host
    cd packer-lfs-build-host
    packer build host.json

The resulting machine is exported into packer-lfs-build-host/output-{name} as an ovf,
where {name} is equal to the configuration variable name.

## Configuration

No configuration is required to build the build-host, however in certain cases
it's wanted, possible for higher system specifications or what not.

One way of overriding the configuration is to pass the -var parameter to the packer
command:

    packer build -var 'cpus=2' -var 'ram=2048' host.json


More information on template variables can be read on
http://www.packer.io/docs/templates/user-variables.html#toc_4

There's only a handful of configuration options available:

### Host machine setup

** These variables affects the host machine created by packer. **

* iso_url - The URL to an ISO of Archlinux
* iso_checksum - A checksum to verify the integrity of the iso
* name - The name of the built machine, this is also used as hostname.
* cpus - The amount of cores allocated for the machine. [default 1]
* ram - The amount of memory allocated for the machine, in megabytes. [default 1024]
* sda_size - The amount of space made for the primary harddive, in megabytes. [default 10240]
* sdb_size - The amount of space made for the secondary (build) harddrive, in megabytes. [default 20480]

### System configuration

** These variables affects the resulting system built by packer. **

* timezone - The timezone set on the build host. [default UTC]
* language - The locale set and used on the build host. [default en_US.UTF-8]
* keymap - The keymap assigned on the build host console. [default sv-latin1]
* build_user - The build user created for LFS building. [default lfs]
* build_dir - The build directory mounted and configured, basically $LFS. [default /mnt/lfs]

### Internal variables

** These variables are only made variables because it's easier to keep track of,
   do NOT change these unless you absolutely have to. **

* _target_dir - The path to be used in the installation system when installing the machine.
* _ssh_pass - The SSH password assigned to the root account for packer
