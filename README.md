[![CrystalBank (CI)](https://github.com/Crystal-Bank/crystalbank/actions/workflows/ci.yml/badge.svg)](https://github.com/Crystal-Bank/crystalbank/actions/workflows/ci.yml)

# crystalbank

An open source project to showcase a banking system written in Crystal. The project will progress along the following domains:

1. Accounts :white_check_mark:
2. Transfers :white_check_mark:
3. Customers :white_check_mark:
4. Users :white_check_mark:
5. ApiKeys :white_check_mark:
6. Authentication :hourglass_flowing_sand:
7. Roles & Permissions (Data access rights)
8. Scopes (Data ownership)
9. ...

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

### Seed the environment
In order to access the API, the initial API credentials need to be seeded
```bash
$ crystal src/seed.cr
```

This will result in the following console output:
```
-----------------------------------------------------
--- Seed credentials
client_id: '0193cc51-cc9b-7955-82ca-7a6482587201'
client_secret: 'secret'
-----------------------------------------------------
-----------------------------------------------------
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
$ crystal src/server/start.cr -d -f openapi.json 
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
    "type": "checking",
    "customer_ids": [
        "00000000-0000-0000-0000-000000000011"
    ]
}
```

**Response**

```JSON
200 OK

{
    "id": "00000000-0000-0000-0000-000000000001"
}
```

### Customers

The customers domain allows to onboard customers to the system. A customer is an entity that can be the sole or shared owner of an account. 

The following request creates a customer of the type `business`


**Request**
```JSON
POST /customers/onboard

{
    "name": "Business customer",
    "type": "business"
}
```

**Response**

```JSON
200 OK

{
    "id": "00000000-0000-0000-0000-000000000011"
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

### Transactions :: Postings

The `Postings` subdomain is providing a view into the postings projection

**Request**
```JSON
GET /transactions/postings?limit=10

```

**Response**

```JSON
200 OK

{
    "object": "list",
    "url": "/transactions/postings?limit=10",
    "meta": {
        "has_more": true,
        "limit": 2,
        "next_cursor": "00000000-0000-0000-0000-900000000002"
    },
    "data": [
        {
            "id": "00000000-0000-0000-0000-900000000001",
            "account_id": "00000000-0000-0000-0000-100000000000",
            "amount": -50,
            "creditor_account_id": "00000000-0000-0000-0000-200000000000",
            "debtor_account_id": "00000000-0000-0000-0000-100000000000",
            "remittance_information": "Transfer no: 1"
        },
        {
            "id": "00000000-0000-0000-0000-900000000001",
            "account_id": "00000000-0000-0000-0000-100000000000",
            "amount": 50,
            "creditor_account_id": "00000000-0000-0000-0000-100000000000",
            "debtor_account_id": "00000000-0000-0000-0000-200000000000",
            "remittance_information": "Transfer no: 1"
        }
    ]
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
