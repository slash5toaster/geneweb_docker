#!/usr/bin/env bash

# Run Geneweb
GW_ACTION=${1:-"start"}
GW_LANG=${GW_LANG:="en"}
GW_ROOT=${GW_ROOT:="/opt/geneweb"}
GW_BASES=${GW_BASES:="${GW_ROOT}/bases/"}
GW_LOGDIR=${GW_LOGDIR:="${GW_ROOT}/logs"}
GWD_PORT=${GWD_PORT:="2317"}
GWSETUP_PORT=${GWSETUP_PORT:="2316"}

# default options - this can be overridden by setting environment vars

GWD_OPTS=${GWD_OPTS:=" -lang ${GW_LANG} \
                       -log ${GW_LOGDIR}/gwd.log \
                       -p $GWD_PORT \
                       -bd ${GW_BASES} \
                       -daemon"}
GWS_OPTS=${GWS_OPTS:=" -lang ${GW_LANG} \
                       -bd ${GW_BASES} \
                       -only ${GW_BASES}/only.txt \
                       -p $GWSETUP_PORT \
                       -daemon"}
#make clean
GWD_OPTS=$(echo ${GWD_OPTS} | tr -s '[[:blank:]]')
GWS_OPTS=$(echo ${GWS_OPTS} | tr -s '[[:blank:]]')

#=============================================================================
setup()
{
  test -d $(dirname ${GW_LOGDIR}) || mkdir -vp $(dirname ${GW_LOGDIR})

  local rval=0

  # Check to see if we're running already!
  if [[ $(pgrep gwd ) ]]; then
      echo "geneweb running"
      rval=22
  fi
  # Check to see if we're running already!
  if [[ $(pgrep gwsetup ) ]]; then
      echo "gwsetup running"
      rval=22
  fi

  #test to ensure bases directory is writeable!!
  if [[ $(touch ${GW_BASES}/.setup) ]]; then
    echo ${GW_BASES} " is writeable"
  else
    echo "Geneweb database directory "${GW_BASES}" is *NOT* writeable. Cannot start"
    rval=22
  fi
  return $rval
}

#=============================================================================
start()
{
  cd ${GW_ROOT}

  if [[ $(pgrep gwd) ]]; then
    echo "gwd running as $(pgrep -a gwd)"
  else
    echo "Starting Geneweb"
    test -e ${GW_LOGDIR}/gwd.log && mv ${GW_LOGDIR}/gwd.log.old
    ${GW_ROOT}/gwd ${GWD_OPTS} 2>&1
  fi

  # gwsetup
  if [[ $(pgrep gwsetup) ]]; then
      echo "gwsetup running as $(pgrep -a setup)"
  else
    ${GW_ROOT}/gwsetup ${GWS_OPTS} 2>&1
  fi
}
#=============================================================================
stop()
{
  cd ${GW_ROOT}
  pkill -e gwd || echo "gwd not running"
  pkill -e gwsetup || echo "gwsetup not running"

}

#=============================================================================
get_version()
{
  # test to make sure everything is copacetic
  # test -e ${GW_ROOT}/gwd && (echo "${GW_ROOT}/gwd ${GWD_OPTS}" | tr -s '[[:blank:]]')
  # test -e ${GW_ROOT}/gwsetup && (echo "${GW_ROOT}/gwsetup ${GWS_OPTS}" | tr -s '[[:blank:]]')
  test -e ${GW_ROOT}/gwd && echo "${GW_ROOT}/gwd ${GWD_OPTS}"
  test -e ${GW_ROOT}/gwsetup && echo "${GW_ROOT}/gwsetup ${GWS_OPTS}"

}
#=============================================================================

# If no arguments passed, then launch server,
# otherwise execute arguments.
if [[ ${#@} -eq 0 ]]; then
  setup || exit 44
  start || exit 2
elif [[ $1 == "stop" ]]; then
  stop  || exit 2
elif [[ $1 == "restart" ]]; then
  stop  || exit 2
  setup || exit 44
  start || exit 2
elif [[ $1 == "version" ]]; then
  get_version
else
  "$@"
fi
