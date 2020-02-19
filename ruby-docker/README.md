# Ruby docker container

Develop and run Ruby script in docker container without unnecessary rebuilds

## Getting Started


### Prerequisites

```
Docker
Docker Compose
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

### Update Gemfile
```
# Update Gemfile.lock
BUNDLE=1 docker-compose up
# Rebuild image
docker-compose up --build
```

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

