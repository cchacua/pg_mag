# pg_mag
PostgreSQL scripts for Microsoft Academic Graph (MAG)

## Requirements
In order to use `pg_mag` you need:
- The MAG raw `txt` files.
- A PostgreSQL server, with the extensions `postgis` and `pg_trgm`.


## Steps

### 1. Getting the MAG raw files
In order to get the MAG raw files, please check the [official documentation](https://docs.microsoft.com/en-us/academic-services/graph/get-started-setup-provisioning) for details. The normal procedure involves creating a Microsoft Azure storage account, signing up for MAG provisioning and downloading the raw files to your host system (using [Azcopy](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10) or another tool).


### 2. Setting up a PostgreSQL server
If you are already running a Postgres Server you just need to enable the extensions `postgis` and `pg_trgm`. You can do this by uncommenting and executing the following lines from `main.sql`:

```
CREATE EXTENSION postgis;
CREATE EXTENSION pg_trgm;
```

If you want to set up a Postgres server from scratch, one of the easiest ways is through Docker and the [`postgis/postgis`](https://registry.hub.docker.com/r/postgis/postgis) image. If you use the `postgis/postgis` image, you just need to install the `pg_trgm` extension. After having installed Docker and Docker compose you can run a new server by modifying and executing the provided Docker Compose definition file (`docker-compose.yml`):

```
version: '3.5'

services:
  db:
    image: postgis/postgis:13-3.0
    restart: always
    ports:
      - 5432:5432
    environment:
      POSTGRES_PASSWORD: YOURPASSWORD # Set a password
      POSTGRES_USER: YOURUSER # Set a username
      POSTGRES_DB: DBNAME # Set a database
    volumes:
      - YOURDBDATA:/var/lib/postgresql/data # Set the folder that will contain the Postgres data
      - YOURINPUT:/home/input # Set the folder that contains the MAG txt files

```
To start the `db` service you need to run `docker-compose up` on a terminal, from your project folder (the folder that contains your `docker-compose.yml` file). If you are new to Docker you can get more information [here](https://docs.docker.com/compose/gettingstarted/).


In order to improve the performance of Postgres according to the characteristics of your host computer, you can edit the Postgres configuration file (`postgresql.conf`). Please check the official [Postgres documentation](https://registry.hub.docker.com/_/postgres/) for more details and [PGTune](https://pgtune.leopard.in.ua/#/) to get some suggested parameters according to your system. Among others, it is recommended to increase the `shared_buffers`, `effective_cache_size` and `max_wal_size`, as to allow Postgres to handle big files, before executing the script.

### 3. Running the script
You can run the script using a PostgreSQL client such as [`psql`](https://www.postgresql.org/docs/13/app-psql.html). You can run the whole script at once (`psql -h localhost -U YOURUSER -d DBNAME -f main.sql`) or manually executing the sections you need.

If you are using Docker, you can open a `psql` client session by running:
```
docker exec -it CONTAINERNAME psql -h localhost -U YOURUSER -d DBNAME
```


## FAQ

### Why are you using `COPY` instead of `\copy`?

`COPY` is a Postgres command while `\copy` is a `psql` client command. `COPY` is faster than `\copy` for large files, but the file accessibility and access rights depend on the server rather than the client (see [SQL-COPY](https://www.postgresql.org/docs/13/sql-copy.html)).

### Why are you using the sed and tr commands? (`COPY` Errors)
Once you get all the files, you may need to modify some of them. As Postgres does not allow loading files with the characters `\000` and with the character `\\` inside the text, you may need to delete or scape them before loading. You can achieve this by using the `sed` and `tr` commands in Linux. If you are using a `psql` client, you can execute Linux commands adding the  `\!` at the beginning of each line. For example, for modifying the `Papers.txt` file, you can execute inside a `psql` client the following lines:
```
\! sed -e 's/\\/\\\\/g' < Papers.txt > Papers_.txt
\! tr -d '\000' < Papers_.txt > Papers__.txt
```

Alternatively, you can execute the `sed` and `tr` commands from a Linux terminal (removing `\!` from each line), using pipes to run sed and tr at once, etc.

Another option is to read the `txt` files `WITH CSV delimiter E'\t'  ESCAPE '\' QUOTE E'\b'`, but this may not work if the character `\b` is inside the text.


### I cannot access the `input` folder from Postgres
If you are using Docker with the `postgis:postgis` image, remember to set all the necessary reading permissions for your `data` and `input` folders (e.g. in Linux, you can type `chmod 755 yourfolder`) and to mount them, when defining the Docker compose file.

### Why does your code need the `postgis` and `pg_trgm`?
The `postgis` extension is required to enable the Spatial and Geographic objects (i.e. the geom columns) and the `pg_trgm` to enable the `gin_trgm_ops` class, to create GIN indexes and speeding searching for similar strings up. If you remove the geom columns from the schema definition and the `gidx_*` indexes, you can omit these extensions.

### How much disk space do I need?
It depends on your version of MAG, Postgres and the set of indexes. For example, the set of the MAG 20200917 raw txt files for the core tables is around 456 GB. After loading the data on Postgres 13, the MAG core tables require around 450 GB. Therefore, you need at least 1TB of space to store the raw and the Postgres database files.

### How much RAM memory do I need?
It depends on the kind of analysis that you intend to perform. For basic operations, 4 - 16 GBs of RAM should be enough.  

### Can I run this script on MySQL? 

Please refer to my [mysql_mag](https://github.com/cchacua/mysql_mag) repository. 

### Questions, issues...

Please report them using Github or feel free to contact me by [email](ccdelgado@u-bordeaux.fr). Feel free to fork this repository and submit your contributions.

### Citing pg_mag in research publications
If you use these scripts in your research publications, please include the following citation:

Chacua, Christian (2020). pg_mag. PostgreSQL scripts. https://github.com/cchacua/pg_mag
