Introduction
============

RECORDS (Remote Control Framework for Underwater Network) is an open source framework that makes it possible to remotely monitor and control a heterogeneous network of underwater acoustic nodes.

How to use it
=============

1. `git clone git@github.com:uwsignet/records.git`
2. open a terminal and
    * `cd records`
    * `./boot.sh 192.168.100.201 9201 9200 12701 folder1 [--no-check-port|--check-port]`
        * where 192.168.100.201 is the ip of the modem
        * 9201 and 9200 are the two ports used to connect the records framework to the modem
        * 12701 is a random local port used internally by the framework
        * folder1 is the folder where all the output of the framework is placed
        * [--no-check-port|--check-port] is a parameter to be used to set if the framework must check the ports used
3. open another terminal and
    * `rlwrap nc 127.0.0.1 12703`
    * type `HELP`

System requirements
===================
`sudo apt-get install tcl expect rlwrap netcat`
