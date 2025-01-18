# Oracle SQLcl

From [oracle.com](https://www.oracle.com/database/technologies/appdev/sqlcl/sqlcl-faq.html):
> SQLcl is a command-line interface for Oracle Database that combines the power of SQL*Plus and SQL Developer.

SQLcl is [now under the Oracle Free Use Terms and Conditions license](https://blogs.oracle.com/database/post/sqlcl-now-under-the-oracle-free-use-terms-and-conditions-license), which makes automated installation much easier.

## Java

Java is required, so ensure an appropriate version is installed.

* macOS [OpenJDK Homebrew formula](https://formulae.brew.sh/formula/openjdk).
* Linux [OpenJDK installation](https://openjdk.org/install/).
* [Adoptium](https://adoptium.net) also offers prebuilt OpenJDK binaries for many platforms.

## macOS

Use [Homebrew](https://formulae.brew.sh/cask/sqlcl) as follows or use the [shell script](#shell-script).

```sh
brew install --cask sqlcl
```

Note that this may not add the `bin` folder to `PATH`, so try the command on the Homebrew page and restart the shell.\
Alternatively, add the command to `~/.zshrc`:

```sh
# Set path variables.
path+=$(brew --prefix)/Caskroom/sqlcl/<version>/sqlcl/bin
export path
typeset -U path
```

## Linux

Use `yum` as follows or use the [shell script](#shell-script).

See the [Oracle Linux Yum Server](https://yum.oracle.com/getting-started.html#installing-software-from-oracle-linux-yum-server) for assistance with `yum` repositories.

```sh
sudo yum install sqlcl
```

## Shell script

> ❗ **Use at your own risk. It is advisable to review the script before executing it.**

1. Clone this repository and treat the root as the working directory.

   ```sh
   cd ~
   mkdir git
   cd git
   git clone <url>
   ```

1. The script may ask for the current user's password, as it will attempt to install SQLcl to `/opt`.

   ```sh
   $ sh install.sh
     % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
   100 39.4M  100 39.4M    0     0  8721k      0  0:00:04  0:00:04 --:--:-- 8900k

   Installation complete
   ```

1. Restart the shell. E.g. `zsh`:

   ```sh
   exec zsh
   ```

1. Check the SQLcl install.

   ```sh
   $ which sql
   /usr/local/bin/sql

   $ echo $SQLPATH
   /Users/<user>/.sqlcl

   $ echo $TNS_ADMIN
   /Users/<user>/.sqlcl
   ```

## Connections

### Container

For example, using an instance of Oracle XE in a [container](../database/container-engine.md):

1. Check the container is running.

   ```sh
   $ podman ps -a                                                             
   CONTAINER ID  IMAGE                            COMMAND     CREATED        STATUS            PORTS                   NAMES
   6c5800535262  docker.io/gvenzl/oracle-xe:slim              8 seconds ago  Up 8 seconds ago  0.0.0.0:1521->1521/tcp  pensive_khorana
   ```

1. Connect to database as `system` user.

   ```sh
   $ sql system@localhost:1521/XEPDB1


   SQLcl: Release 22.2 Production on Sat Jul 09 12:34:00 2022

   Copyright (c) 1982, 2022, Oracle.  All rights reserved.

   Password? (**********?) *****
   Last Successful login time: Sat Jul 09 2022 12:34:05 +01:00

   Connected to:
   Oracle Database 21c Express Edition Release 21.0.0.0.0 - Production
   Version 21.3.0.0.0
   
   SQL>
   ```

1. Optionally create a TNS entry in `$TNS_ADMIN/tnsnames.ora`.

   ```sh
   XEPDB1 =
       (DESCRIPTION =
           (ADDRESS = 
               (PROTOCOL = TCP)
               (HOST = localhost)
               (PORT = 1521)
           )
           (CONNECT_DATA =
               (SERVER = DEDICATED)
               (SERVICE_NAME = XEPDB1)
           )
       )
   ```

   Then connect using the entry:

   ```sh
   sql system@XEPDB1
   ```

### Oracle Cloud Infrastructure (OCI)

Create an account and an Autonomous Transaction Processing (ATP) database at <https://cloud.oracle.com>.

1. Select the database instance from the [Autonomous Database](https://cloud.oracle.com/db/adb) dashboard.
1. Click **DB Connection** and download the **Instance Wallet** to `~/.sqlcl`.\
   E.g. `~/.sqlcl/Wallet_demo.zip`.
1. Open SQLcl:

   ```sh
   sql /nolog
   ```

1. Load wallet:

   ```text
   SQL> SET CLOUDCONFIG Wallet_demo.zip

   Operation is successfully completed.
   Using temp directory:/var/folders/2v/jfse9ffs3sdfdfhde431dgge0000fr/T/oracle_cloud_config8573768666928582556
   ```

1. Check TNS entries:

   ```text
   SQL> SHOW TNS

   TNS_ADMIN set to: /var/folders/2v/jfse9ffs3sdfdfhde431dgge0000fr/T/oracle_cloud_config8573768666928582556
   
   
   Available TNS Entries
   ---------------------
   demo_high
   demo_low
   demo_medium
   demo_tp
   demo_tpurgent
   ```

1. Connect to database using a TNS entry:

   ```text
   SQL> CONNECT admin@demo_medium

   Password? (**********?) *********************
   Connected.
   ```

1. Execute some SQL:

   ```text
   SQL> SELECT SYSDATE
     2  FROM dual;

        SYSDATE
   ____________ 
   01-JUL-22
   ```
