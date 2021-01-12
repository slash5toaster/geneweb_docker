#!/usr/bin/env bash

# Run Geneweb
GW_ACTION=${1:-"start"}
GW_LANG=${GW_LANG:="en"}
GW_ROOT=${GW_ROOT:="/opt/geneweb"}
GW_LOGDIR=${GW_LOGDIR:="/${GW_ROOT}/logs"}


#=============================================================================
setup()
{
  test -d $(dirname ${GW_LOG}) || mkdir -vp $(dirname ${GW_LOG})

  # Check to see if we're running already!
  if [[ $(ps aux | grep gwd  ) -gt 0 ]]; then
      echo "geneweb running"
      return 22
  fi
}

#=============================================================================
start()
{
  echo "Starting gwd"
  cd ${GW_ROOT}

  test -e ${GW_LOG}/gwd.log && mv ${GW_LOG}/gwd.log.old
  ${GW_ROOT}/gwd \
             -lang ${GW_LANG} \
             -log ${GW_LOG}/gwd.log \
             --daemon 2>&1

  test -e ${GW_LOG}/gwsetup.log && mv ${GW_LOG}/gwsetup.log.old
  ${GW_ROOT}/gwsetup \
             -lang ${GW_LANG} \
             -log ${GW_LOG}/gwsetup.log \
             --daemon 2>&1

}
#=============================================================================
get_version()
{
  # test to make sure everything is copacetic

}
#=============================================================================

# If no arguments passed, then launch cromwell server,
# otherwise execute arguments.
if [[ ${#@} -eq 0 ]]; then
  setup || exit 44
  start || exit 2
elif [[ $1 == "version" ]]; then
  get_version
else
  "$@"
fi
