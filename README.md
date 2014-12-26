# Metamaps Docker

Metamaps is a free and AGPL open source technology for changemakers, innovators, educators and students. It enables individuals and communities to build and visualize their shared knowledge and unlock their collective intelligence. You can find out about more about the project at the [blog](http://blog.metamaps.cc).

You can find a version of this software running at [metamaps.cc](http://metamaps.cc), where the technology is being tested in a private beta.

This repository is some scripts to get yourself a docker container up and running, for use in development and production. Tweak it as necessary and open issues *specifically related* to annoyances or problems with the dockerized Metamaps here. Please use the [main metamaps respository](https://github.com/metamaps/metamaps_gen002) for all other issues related to the metamaps platform itself. 

If you don't have docker installed, you should probably Google it. 

Type this if you want [Docker for Ubuntu 14.04](https://docs.docker.com/installation/ubuntulinux/) 

```bash
 $ curl -sSL https://get.docker.com/ubuntu/ | sudo sh
```

## Installation

Simple clone the repository and make use the ./docker.sh script to build, run, and provision the docker container(s). If you know what you're doing, it's easy to use the Dockerfile directly. If you are a scripting ninja who would like to help us grasshoppers improve our scripts, then pull request it!

```bash
 # clone this repository
 $ git clone https://github.com/metamaps/metamaps_gen002 metamaps-docker
```

This is our repository's structure.

```bash
# default development instance		
├── config 
│   ├── database.yml
│   └── Dockerfile

# script to perform common tasks for MetaMaps
├── docker.sh

# will be downloaded later
├── src
└── volumes
```


## Usage

docker.sh is the file
 
**Prepare**
 
```bash
 # clones repo and applies configuration from the config directory
 $ ./docker.sh prepare
 
 # If it succeeded you will have a new ./src folder
```

**Build**
 
```bash
 # pulls "rails" docker image...
 # copies gem lock, installs ruby gems...
 # copy src into container...
 $ ./docker.sh build
 
 # this will take a while the first time, but caches layers and goes quickly later
 # rerun this when you change the src, or gems
```
 
**Run Containers**
 
```bash
 # Pulls and runs the postgres container
 $ ./docker.sh run db 
 
 # Run the metamaps container
 $ ./docker.sh run mm
 
 # verify this succeeded by typing 
 $ docker ps
 
```

**Seed Postgres DB**

```bash
$ ./docker.sh seed
```
 

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## History

TODO: Write history

## Credits

Credits to the Metamaps team for an awesome platform! 

The dockerization was put together and contributed by Daniel Sont =].

## License

Have fun, see MetaMaps License.
