#!/bin/bash
#
# Init file for Azkaban Executor Server
#
# chkconfig: 2345 60 25
# description: Azkaban Executor Server

# Source function library.
#. /etc/init.d/functions

if [ -z "$AZKBN_HOME" ]; then
  AZKBN_HOME=/opt/azkaban-executor-2.5.0
fi
export AZKBN_HOME

if [ -z "$AZKBN_PIDFILE" ]; then
  AZKBN_PIDFILE="$AZKBN_HOME/currentpid"
fi
export AZKBN_PIDFILE

if [ -z "$SHUTDOWN_WAIT" ]; then
  SHUTDOWN_WAIT=10
fi


CMD_PREFIX=''

# Option to utilize daemon
if [ ! -z "$AZKBN_USER" ]; then
  if [ -r /etc/rc.d/init.d/functions ]; then
    CMD_PREFIX="daemon --user $AZKBN_USER"
  else
    CMD_PREFIX="su - $AZKBN_USER -c"
  fi
fi

PROG='Azkaban Executor Server'
AZKBN_USER=etladmin
AGENT="$AZKBN_HOME/bin/start-exec.sh"

start()
{
  echo -n "Starting $PROG: "
  if [ -f $AZKBN_PIDFILE ]; then
    read ppid < $AZKBN_PIDFILE
    if [ `ps --pid $ppid 2> /dev/null | grep -c $ppid 2> /dev/null` -eq '1' ]; then
      echo -n "$PROG is already running"
      failure
      echo
      return 1
    else
      rm -f $AZKBN_PIDFILE
    fi
  fi


  mkdir -p $(dirname $AZKBN_PIDFILE)
  chown $AZKBN_USER $(dirname $AZKBN_PIDFILE) || true

  if [ ! -z "$AZKBN_USER" ]; then
     cd /opt/azkaban-executor-2.5.0 && bin/start-exec.sh  &
     echo $! > $AZKBN_PIDFILE
  fi

 # success
  echo
  return 0

}

stop()
{
  echo -n $"Stopping $PROG: "
  count=0;

  if [ -f $AZKBN_PIDFILE ]; then
    read kpid < $AZKBN_PIDFILE
    let kwait=$SHUTDOWN_WAIT

    # Try issuing SIGTERM

    kill -15 $kpid
    until [ `ps --pid $kpid 2> /dev/null | grep -c $kpid 2> /dev/null` -eq '0' ] || [ $count -gt $kwait ]
    do
      sleep 1
      let count=$count+1;
    done

    if [ $count -gt $kwait ]; then
      kill -9 $kpid
    fi
  fi
  rm -f $AZKBN_PIDFILE
#  success
  echo
}

status()
{
  if [ -f $AZKBN_PIDFILE ]; then
    read ppid < $AZKBN_PIDFILE
    if [ `ps --pid $ppid 2> /dev/null | grep -c $ppid 2> /dev/null` -eq 1 ]; then
      echo "$PROG is running (pid $ppid)"
      return 0
    else
      echo "$PROG dead but pid file exists"
      return 1
    fi
  fi
  echo "$PROG is not running"
  return 3
}

case "$1" in
  start)
      start
      ;;
  stop)
      stop
      ;;
  restart)
      stop
      start
      ;;
  status)
      status
      ;;
  *)
  echo "Usage: $0 start|stop|restart|status"
  exit 1
  ;;
esac
