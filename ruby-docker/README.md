# Ruby docker container

Develop and run Ruby script in docker container without unnecessary rebuilds

## Getting Started

### Quick Start

```
cd workdir
wget https://raw.githubusercontent.com/vovanmozg/docker-composes/master/ruby-docker/dockerize.sh && chmod +x ./dockerize.sh && ./dockerize.sh
docker-compose up

```

### Installing

```
git clone https://github.com/vovanmozg/ruby-docker.git
cd ruby-docker
```

### Run
``` 
docker-compose up
```
### Modify
``` 
# ... edit src/run.rb
docker-compose up
```

### Add gems to Gemfile
```
# ... edit Gemfile
# Update Gemfile.lock
BUNDLE=1 docker-compose up
# Rebuild image
docker-compose up --build
```

## Prerequisites

```
Docker
Docker Compose
```

## References
https://hub.docker.com/_/ruby

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

