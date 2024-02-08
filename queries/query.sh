#!/bin/bash
set -e
POSTGRES_HOST=postgres://docker:docker@localhost:6432/transportation;
QUERY_1=$(cat Queries_1.sql);
QUERY_2=$(cat Queries_2.sql);
QUERY_3=$(cat Queries_3.sql);
MYDATE=$(date +"%Y%m%d");

RASULTSPATH=./query_results;
if [ ! -d $RASULTSPATH ]
then
    mkdir -p $RASULTSPATH;
    chmod +x -R $RASULTSPATH;
fi;

RES_1=$RASULTSPATH"/result_"$MYDATE"_1.txt";
RES_2=$RASULTSPATH"/result_"$MYDATE"_2.txt";
RES_3=$RASULTSPATH"/result_"$MYDATE"_3.txt";
echo $MYDATE;
echo $RES_1;
echo $RES_2;
echo $RES_3;
echo "===============";
echo $QUERY_1;
echo $QUERY_2;
echo $QUERY_3;
echo "===============";
echo psql $POSTGRES_HOST -X --single-transaction --quiet -c $QUERY_1;
echo "===============";
psql $POSTGRES_HOST -t -A -F"," -c "$QUERY_1" > $RES_1  2>&1;
echo "===============";
echo "=======RESULT Of QUERY 1==";
cat $RES_1;
echo "===============";
echo "result in $RES_1";
echo "===============";
echo psql $POSTGRES_HOST -X --single-transaction --quiet -c $QUERY_2;
echo "===============";
psql $POSTGRES_HOST -t -A -F"," -c "$QUERY_2" > $RES_2  2>&1;
echo "===============";
echo "=======RESULT Of QUERY 2==";
cat $RES_2;
echo "===============";
echo "result in $RES_2";
echo "===============";
echo psql $POSTGRES_HOST -X --single-transaction --quiet -c $QUERY_3;
echo "===============";
psql $POSTGRES_HOST -t -A -F"," -c "$QUERY_3" > $RES_3  2>&1;
echo "===============";
echo "=======RESULT Of QUERY 3==";
cat $RES_3;
echo "===============";
echo "result in $RES_3";
