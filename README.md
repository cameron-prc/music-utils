# README

## Initial Setup

### Credentials

Initialise the encrypted credentials file:

```bash
EDITOR="code --wait" rails credentials:edit
```

Generate encryption keys, then open the credentials file:

```bash
bin/rails db:encryption:init
EDITOR="code --wait" rails credentials:edit
```

Add the following keys (obtain Spotify values from the Spotify Developer Dashboard; use the generated output from `db:encryption:init` for the Active Record keys):

```yaml
active_record_encryption:
  primary_key: <your_generated_primary_key>
  deterministic_key: <your_generated_deterministic_key>
  key_derivation_salt: <your_generated_salt>
```

### Database

```bash
rails db:create db:migrate db:seed
```

---

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
