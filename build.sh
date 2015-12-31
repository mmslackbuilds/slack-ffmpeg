#!/bin/sh

# DEBUG_LEVEL: 0 no debug
#              1 show packages added
#              2 show ignored packages
#              3 show parameters added to ffmpeg
DEBUG_LEVEL=${DEBUG_LEVEL:-1}

CWD=$(pwd)

OPTIONAL_DEPS_FILE='optional-deps'
OPTIONAL_CONFIG_FILE='optional-config'

IFS=$'\n' command eval "OPTIONAL_LIST=($(cat ${OPTIONAL_DEPS_FILE}))"
if [ $DEBUG_LEVEL -gt 0 ]; then
  echo "Optional dependencies: ${OPTIONAL_LIST[*]}"
fi

IN_GROUP='no'
# read optional config file and write extra parameters for ffmpeg
# first remove comment and empty lines
sed -e 's/#.*$//' -e '/^$/d' $OPTIONAL_CONFIG_FILE |
while IFS=' ' read -r CFG_LINE; do
  # verify if line correspond to group name: "[package]"
  GROUP=$(echo $CFG_LINE | grep -E -o '\[.*\]')
  if [ ! -z "$GROUP" ]; then
    # extract pagacke group name
    GROUP=$(echo $GROUP | grep -E -o '[^][]+')
    # test if group is in OPTIONAL_LIST
    # remove element from array and asign result to TEST_LIST
    TEST_LIST=${OPTIONAL_LIST[@]#${GROUP}}
    if [ "${TEST_LIST}" != "${OPTIONAL_LIST[*]}" ]; then
      # unequal means group is in optional dependencies list
      echo "CONFIGURE optional package: $GROUP"
      GROUPNAME=$GROUP
      IN_GROUP='yes'
    else
      if [ $DEBUG_LEVEL -gt 1 ]; then
        echo "Ignore package: $GROUP"
      fi
      IN_GROUP='no'
    fi
  else
    # add elements if group is in optional dependencies list
    if [ $IN_GROUP != 'no' ]; then
      if [ $DEBUG_LEVEL -gt 0 ]; then
        echo "Group [${GROUPNAME}]: add package $CFG_LINE"
      fi
    fi
  fi
  #IFS=' ' read -r -a PACKAGE_LIST <<< $CFG_LINE
done
