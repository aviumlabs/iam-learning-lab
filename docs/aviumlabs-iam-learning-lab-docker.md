Avium Labs IAM Learning Lab Docker Environment Guide (c) by Michael Konrad

Avium Labs IAM Learning Lab Docker Environment is licensed under a
Creative Commons Attribution 4.0 International License.

You should have received a copy of the license along with this
work. If not, see <http://creativecommons.org/licenses/by/4.0/>


The included docker compose file launches a stack that meets the requirements 
to run SailPoint IdentityIQ.

PostgreSQL 15.x
Apache Tomcat 9.0.x

## Prerequisite Steps

Prior to launching the docker environment the database password file needs to 
be generated and the .pgpass file created.

Create these files in the tcdocker-iam directory.

Various shell scripts that can be used to generate the password file. 

### PostgreSQL Password

**macOS**
```shell
date +%s | shasum -a 256 | base64 | head -c14 > .secret_db
```

**linux-gnu**
```shell
date +%s | sha256sum | base64 | head -c14 > .secret_db
```

**Windows**
```PowerShell
$DB_SECRET_FILE = "$pwd\.secret_db"

# Generate a random password of length PwLength, defaults to 14 characters
function New-RandomPassword {
    param (
        [int]$PwLength = 14
    )
    # Char 97 - 122 'a-z'
    # Char 65 - 90 'A-Z'
    # Char 48 - 57 '0-9'
    # Char 45 '-'
    # Char 43 '+'
    $char_list = [char]97..[char]122 + [char]65..[char]90 + [char]48..[char]57 `
    + [char]43 + [char]45

    # Select a random character from the list and convert back to character
    $pass = -Join ((Get-Random -InputObject $char_list -Count $PwLength) | ForEach-Object {[char]$_})
    
    return $pass
}

# Write the database secret file
function Write-DbSecret {
    $line1 = Get-RandomPassword
    
    $line1 | Out-File -FilePath $DB_SECRET_FILE -NoClobber
}

# Script Driver
function main {
    Write-DbSecret
}

main
```

### pgpass File Content
Replace the bracketed text with the correct passwords.
```
db:5432:identityiq:identityiq:<identityiq-password>
db:5432:identityiqPlugin:identityiqPlugin:<identityiqPlugin-password>
db:5432:identityiqah:identityiqah:<identityiqah-password>
db:5432:postgres:postgres:<generated-postgres-password>
```

## Initializing the Docker Environment

The base Apache Tomcat image for this project is maintained here:
[Avium Labs - Tomcat Ant](https://github.com/aviumlabs/tomcat-ant-img).
Check this site for the latest release and update the Docker compose file.

In the docker compose file, update the `app` `image` entry to the desired Apache Tomcat version.

## Stack Start

The containers can either be run in the foreground or the background of the shell.

Run the containers in the foreground:
```shell
docker compose up
```

Run the containers in the background:
```shell
docker compose up -d
```

## Stack Access

To access the application server, run the following docker command:

```shell
docker compose exec -it app /bin/ash
```

## Directory Structure

Tomcat instance directory: /opt/tomcat/instances/tc1

The IdentityIQ Standard Services Build (SSB) is bind mounted in the container.

SSB directory: /opt/tomcat/ssb


## Initial Deployment

Open a terminal session to the application server contianer:
```shell
docker compose exec -it app /bin/ash
```

Run the following deployment tools script commnads:

**Initial Build**
```shell
iiqdeptools -b n
```

**Initial IdentityIQ Environment**
```shell
iiqdeptools.py -c
```

**Initial IdentityIQ Build WAR**
```shell
iiqdeptools.py -b y
```

**Initial IdentityIQ Deployment**
Run the deployment and extend the Identity Schema:
```shell
iiqdeptools.py -d y
```

## Regular Deployments

**IdentityIQ Build WAR**
```shell
iiqdeptools.py -b y
```

**IdentityIQ Deployment**
```shell
iiqdeptools.py -d n
```



## Database

The Postgres database password is generated dynamically and is located here:
/run/secrets/postgres_password.

To connect to the PostgreSQL database from the application server:
```shell
psql postgres -U postgres -h db
```