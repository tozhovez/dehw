#

## Technology Stack:
    Programming Language: Python 3.12+ Bash
    Framework: Sanic
    Containerization: Docker Compose
    Database: PostgreSQL
    Operating System: Ubuntu
    Build tool: Makefile

## Prerequisites:
Ensure you have Ubuntu, Docker, and Python 3.7+ installed on your system.

## Git Repository:
To clone the code from a specific repository, use the following command:

        git clone https://github.com/tozhovez/dehw.git

        cd dehw;

## Makefile:

A Makefile is a text file that defines build instructions.

### Commands MAKEFILE:

        make install-requirements

        make run-infra

        make create-database

        make dummy-data

        make uploader-data

### Command in to start data loading validation and Uploading to DB:

        curl http://0.0.0.0:5050/fetch_data

---------------------------------------------------------------------------
### SQL Queries:

  Creating Materialized Views:

  Access Queries: You need the full path or location of the SQL query files within the dehw/queries directory.
  Content of Files: Each file should contain a single SQL query that defines a materialized view.
  Execution: You can use a command-line tool like psql to connect to your PostgreSQL database and execute the SQL queries from the files.


Using Docker Compose To RUN postgress and adminer
        connect to Postgress  "127.0.0.1:6432
        
    postgres://docker:docker@localhost:6432/transportation







