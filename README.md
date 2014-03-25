Introduction
============

RECORDS (Remote Control Framework for Underwater Network) is an open source framework that makes it possible to remotely monitor and control a heterogeneous network of underwater acoustic nodes.

How to use it
=============

1. git clone git@github.com:uwsignet/records.git
2. open a first terminal and
    * cd records
    * ./boot.sh 9201 9200 12701 folder1 [--no-check-port|--check-port]
3. open another terminal and
    * rlwrap nc 127.0.0.1 12703
    * type HELP

System requirements
===================
`sudo apt-get install tcl expect rlwrap netcat`
