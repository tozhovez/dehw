import os, sys
import subprocess

pg_url = str(f"postgres://docker:docker@localhost:6432/dockerdb")
query = "create database transportation;"
subprocess.run(["psql", pg_url, "-X", "--quiet", "-c", query])
pg_url = str(f"postgres://docker:docker@localhost:6432/transportation")
with open("createdb.sql", 'r') as f:
        query = f.read()
        subprocess.run(["psql", pg_url, "-X", "--quiet", "-c", query])
