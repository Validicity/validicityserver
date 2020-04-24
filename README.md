
# ValidicityServer
The ValidicityServer server is built with [Aqueduct](https://aqueduct.io) in Dart. It runs on a Ubuntu Linux server and uses PostgreSQL as database. It offers a REST based API over HTTPS using OAuth2 for authentication.

## Running the Application in Development
Run `validicityserver` from this directory.

If you wish to use the debugger in your IDE, launch `validicityserver` from your IDE. If you use VSCode there is already a launcher defined.

You must have a `config.yaml` file that has connection information to a locally running PostgreSQL database. If you have a standard PostgreSQL project (at least on Linux) you can run `setup.sh` to create the database and user for Validicityserver.

Then, to provision that database with this application's schema, run the following command from this directory:

```
aqueduct db upgrade
```

This will apply the migrations that you can also look at in the `migrations` directory. A new migration is created with `aqueduct db generate` after code has been modified.

## Running Application Tests
This application is tested against a local PostgreSQL database that is **fully separate from the Validicity database**. The test harness (`test/harness/app.dart`) creates database tables for each `ManagedObject` subclass declared in this application. These tables are discarded when the tests complete. This means you can always run the sample tests in the `test` directory against this temporary database, without disturbing the existing real database.

For this to work the local database project must have a database named `dart_test`, for which a user named `dart` (with password `dart`) has full privileges to. The following command creates this database and user on a locally running PostgreSQL database:

```
aqueduct setup
```

To run all tests, run the following in this directory:

```
pub run test
```

You may also run tests from an IntelliJ IDE by right-clicking on a test file or test case and selected 'Run tests'. VSCode can now also run tests, press F1 and find "Dart: Run all tests".

Tests will be run using the configuration file `config.src.yaml`. This file should contain test configuration values and remain in source control. This file is the template for `config.yaml` files, which live on deployed server instances.

See the application test harness, `test/harness/app.dart`, for more details. This file contains a `Harness` class that can be set up and torn down for tests. It will create a temporary database that the tests run against. See all test code in directory `test`.

For more information, see [Getting Started](https://aqueduct.io/docs/) and [Testing](https://aqueduct.io/docs/testing/).

## Application Structure
The data model is defined by all declared subclasses of `ManagedObject`. Each of these subclasses are in the `lib/model` directory.

Routes and other initialization are configured in `lib/channel.dart`. Endpoint controllers are in `lib/controller/`. In `lib/service` you find various services used for scheduling, email etc.

## Configuration
The configuration file (`config.yaml`) currently requires an entry for `database:` which describes a database connection.

The file `config.src.yaml` is used for testing: it should be checked into source control and contain values for testing purposes. It should maintain the same keys as `config.yaml`.

## Creating API Documentation
In the project directory, run:

```bash
aqueduct document
```

This will print a JSON OpenAPI specification to stdout.

## Authentication
Validicity uses OAuth 2.0 and in order for users to be able to login, they need the client application to be registered first. This is done whenever we add a new application that can access the API, so typically the Validicity CLI tool `valid` is one client, the `validicityclient` is another, the mobile application is yet another. This is how such client ids are registered with their allowed scopes (UserTypes):

        aqueduct auth add-client --id city.validi.valid --allowed-scopes "admin client user superuser"
        aqueduct auth add-client --id city.validi.mobile --allowed-scopes "admin user superuser"
        aqueduct auth add-client --id city.validi.client --allowed-scopes "client"

## Nginx
Install:

        sudo apt install nginx
        
Configure default:
```
server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name prod.validi.city;
        return 301 https://$host$request_uri;
}

server {
	# SSL configuration
	listen 443 ssl default_server;
	listen [::]:443 ssl default_server;
	root /var/www/html;
	index index.html;
	server_name prod.validi.city;

	location / {
		# First attempt to serve request as file, then
		# as directory, then fall back to displaying a 404.
		try_files $uri $uri/ =404;
	}

	location ~ /\. {
		deny all;
	}

	# Validicity RPC
	location /rpc/ {
		proxy_pass_header Authorization;
		proxy_pass http://localhost:7777/;
		proxy_set_header Host $host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		add_header 'Access-Control-Allow-Origin' '*';
		proxy_http_version 1.1;
		proxy_set_header Connection "";
		proxy_buffering off;
		client_max_body_size 0;
		proxy_read_timeout 36000s;
		proxy_redirect off;
		proxy_ssl_session_reuse off;
	}
}
```

## Letsencrypt
Install certbot:

        sudo apt-get install software-properties-common
        sudo add-apt-repository ppa:certbot/certbot
        sudo apt-get update
        sudo apt-get install python-certbot-nginx 

Then run it to get a certificate installed:

        sudo certbot --nginx

## Swap

        sudo fallocate -l 2G /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile

        sudo nano /etc/fstab

        /swapfile swap swap defaults 0 0

        sudo swapon --show

## Dart
Add Dart repo:

        sudo apt-get install apt-transport-https
        sudo sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
        sudo sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'

And then:

        apt update && install dart

## PostgreSQL
We use PostgreSQL's apt repository to stay on track of updates of PostgreSQL:

Create the file `/etc/apt/sources.list.d/pgdg.list' and add a line for the repository

        deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main

Import the repository signing key, and update the package lists

        wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
        sudo apt-get update

Then we can install PostgreSQL:

        sudo apt install postgresql postgresql-client

Then we need to change password for the postgres user:

        sudo -i -u postgres
        postgres@collector:~$ psql
        psql (10.4 (Ubuntu 10.4-0ubuntu0.18.04))
        Type "help" for help.

        postgres=# \password
        Enter new password: 
        Enter it again: 
        postgres=# \q

        exit

Finally we want to make a "Validicity" user and a "dart" user:

        sudo su postgres
        psql -c 'create database Validicity;'
        psql -c 'create user Validicity;'
        psql -c "alter user Validicity with password 'Validicity';"
        psql -c 'grant all on database Validicity to Validicity;'
        psql -c 'create database dart_test;'
        psql -c 'create user dart with createdb;'
        psql -c "alter user dart with password 'dart';"
        psql -c 'grant all on database dart_test to dart;'
        exit


To see the SQL you are running, current way to do it is set your log levels really high in `Channel.prepare`:
        hierarchialLoggingEnabled = true;
        logger.level = Level.all;

You can use the `ApplicationChannel.messageHub` for synchronizing something across isolate each channel has its own hub, which is a stream and sink for dynamic data. if you add an event to it, the other isolates receive that event. (but not the one that sent it). so you can do something as simple as set up a listener in your `prepare` that listens for the string ‘clearCache’.

## Make validicity user

    adduser validicity

Make sure it can git clone from Github:

    eval `ssh-agent` && ssh-add ~/.ssh/id_rsa_validicity

    ssh -T git@github.com

Add this to .bashrc:

        eval `ssh-agent`
        ssh-add ~/.ssh/id_rsa_validicity

## Validicity
Add to ~/.profile;

        export PATH=$PATH:/usr/lib/dart/bin
        export PATH="$PATH":"$HOME/.pub-cache/bin"

Then:

        git clone git@github.com:Validicity/validicitylib.git
        git clone git@github.com:Validicity/valid.git
        git clone git@github.com:Validicity/validicityserver.git

        cd validicitylib
        pub get

        cd ../validicityserver
        pub get

Activate aqueduct tool:

        pub global activate aqueduct 

Then apply migrations:

        aqueduct db upgrade


Make validicity sudoer:

        usermod -aG sudo validicity

Then add public keys to /home/validicity/authorized_keys for users that should be able to login.

Then also create and copy a specific validicity key pair to the server:

        ssh-keygen  # Naming it id_rsa_validicity
        ssh-copy-id -i .ssh/id_rsa_validicity validicity@validi.city

Create a systemd service `/etc/systemd/system/validicityserver.service`:

        [Sample]
        Description=Validicityserver
        Documentation=http://github.com/validicity/validicityserver.git
        After=network.target

        [Service]
        User=validicity
        WorkingDirectory=/home/validicity/validicityserver
        ExecStart=/home/validicity/validicityserver/validicityserver
        LimitNOFILE=500000
        KillMode=mixed
        KillSignal=SIGTERM
        Restart=always
        RestartSec=2s
        NoNewPrivileges=yes
        StandardOutput=syslog+console
        StandardError=syslog+console

        [Install]
        WantedBy=multi-user.target
