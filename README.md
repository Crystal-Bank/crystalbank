# crystalbank

An open source project to showcase a banking system writtein in Crystal.

[![CrystalBank (CI)](https://github.com/Crystal-Bank/crystalbank/actions/workflows/ci.yml/badge.svg)](https://github.com/Crystal-Bank/crystalbank/actions/workflows/ci.yml)

## Usage

### Start of the environment

In order to start the dockerized environment, simply run:
```bash
$ make dev
```

Other options of the environment can be displayed by running:
```bash
$ make help
```

### Start of the API server

In order to start the API server, just run the following command:

```bash
$ crystal src/server/start.cr
```

The project will expose the API on [http://localhost:4000](http://localhost:4000) on the docker host.

### Generation of the openAPI specs

In order to generate updated API specs, run:

```bash 
$ crystal src/server/start.cr -d -f openapi.yml 
```

This will automatically be shared with the running redoc application

### Viewing of openAPI specs

In order to easily navigate the API specs, the project contains reDoc, which can be accessed under 

[http://localhost:4002](http://localhost:4002)

### Accessing the PostgreSQL database

The PostgreSQL database can be accessed from the host via 

[postgres://es:es/eventstore@localhost:4001](postgres://es:es/eventstore@localhost:4001)
``


## Contributing

1. Fork it (<https://github.com/your-github-user/crystalbank/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Tristan Holl](https://github.com/tristanholl) - creator and maintainer
