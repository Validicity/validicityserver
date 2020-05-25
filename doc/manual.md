# Manual
This is an operating manual for the Validicity system intended for employees at Validicity.

## Parts
Our own parts as they are named in Github:

* Validicityserver - The Dart server running in the cloud backed by PostgreSQL.
* Validicityclient - A Dart headless server for the NFC scanner device.
* Validicityapp    - A Flutter mobile application acting as UI to the whole system.
* Validicitytool   - A Dart command line uility that can interact with the system over REST/MQTT.

There are also two reusable libraries:

* Validicitylib    - A Dart library shared between server, client, tool and app.

Important other components:

* PostgreSQL - The database on the server.
* Nginx - The HTTP frontend on the server.

## Tools
The following tools are available to interact with the system:

* Validicitytool - The command line utility, typically used from a Linux shell but can be built and used on Windows too.
* DBeaver - A good cross platform database tool to dig into the database, see [DBEaver.io](https://dbeaver.io)

## Servers
Today we have one server hosted at Upcloud.com:

* prod.validi.city - Used for production use, currently demonstrations.

...to be written...