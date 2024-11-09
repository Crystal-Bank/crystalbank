[![CrystalBank (CI)](https://github.com/Crystal-Bank/crystalbank/actions/workflows/ci.yml/badge.svg)](https://github.com/Crystal-Bank/crystalbank/actions/workflows/ci.yml)

# crystalbank

An open source project to showcase a banking system written in Crystal. The project will progress along the following domains:

1. Accounts
2. Transfers
3. Customers
4. Roles & Permissions (Data access rights)
5. Scopes (Data ownership)
6. ...

## Preparation

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

`postgres://<user>:<password>/eventstore@localhost:4001`



## Usage

_TODO: This section needs to be moved to a Wiki once the project grows to keep the README file clean_

### Examples

The project contains script examples in the folder `app/examples`

### Accounts

The account domain allows to create accounts to the system. An account is an entity that can hold postings, as well as calculate one or multiple balances. CrystalBank allows accounts to support multiple currencies that need to be pre-defined in the opening process.

The following request creates an account of the type `checking` that supports both `eur`, as well as `usd` as currency


**Request**
```JSON
POST /accounts/open

{
    "currencies": [
        "eur",
        "usd"
    ],
    "type": "checking"
}
```

**Response**

```JSON
200 OK

{
    "id": "00000000-0000-0000-0000-000000000001"
}
```

### Transactions :: InternalTransfers

The `InternalTransfer` is a subdomain of `Transactions` and allows to move money between existing accounts. The internal transfer requires two existing and open accounts, which both support the requested currency. Transfer amounts are always expected to be positive `> 0`

The following request intiates an internal transfer of 50 EUR cents, between the debtor account `00000000-0000-0000-0000-100000000000` and the creditor account `00000000-0000-0000-0000-200000000000` with the remittance information `test`


**Request**
```JSON
POST /transactions/internal_transfers/initiate

{
    "amount": 50,
    "creditor_account_id": "00000000-0000-0000-0000-200000000000",
    "currency": "eur",
    "debtor_account_id": "00000000-0000-0000-0000-100000000000",
    "remittance_information": "test"
}
```

**Response**

```JSON
200 OK

{
    "id": "00000000-0000-0000-0000-900000000001"
}
```

## Contributing

1. Fork it (<https://github.com/your-github-user/crystalbank/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Tristan Holl](https://github.com/tristanholl) - creator and maintainer
