#!/bin/sh
#!/bin/bash
basedir=$(dirname $(readlink -f $0))
keyfile=${basedir}/remote-ssh-key
logfile=${basedir}/run.txt
remote="localhost" #"root@10.0.0.107"
remote_port=22
verbose=

if [ "$1" = "-v" ] ; then
    verbose=1
    shift
fi

if [ -z "$1" ] ; then
    echo "Usage: $0 COMMAND ARG..."
    exit 1
fi

set -e -u

if [ -x "$1" ] ; then
    if [ -n "$verbose" ] ; then
       echo "Copying $1 to $remote" >&2
    else
       echo "$(date) Copying $1 to $remote" >> ${logfile}
    fi
    scp -P ${remote_port} -q -i ${keyfile} "$1" ${remote}:/tmp
    remotename="/tmp/$(basename $1)"
    shift
    if [ -n "$verbose" ] ; then
       echo "Running remotely: ${remotename} $@" >&2
    else
       echo "$(date) Running remotely: ${remotename} $@" >> ${logfile}
    fi
    ssh -p ${remote_port} -q -i ${keyfile} ${remote} "${remotename} $@"
else
    if [ -n "$verbose" ] ; then
       echo "Running remotely: $@" >&2
    else
       echo "$(date) Running remotely: $@" >> ${logfile}
    fi
    ssh -p ${remote_port} -q -i ${keyfile} ${remote} "$@"
fi
