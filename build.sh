#!/bin/sh

# DEBUG_LEVEL: 0 no debug
#              1 basic debug and show packages added
#              2 show ignored packages
#              3 show parameters added to ffmpeg
DEBUG_LEVEL=${DEBUG_LEVEL:-1}
# Enable recursive packages
RECURSIVE=${RECURSIVE:-'yes'}
# Simulate installation
SIMULATION=${SIMULATION:-'no'}

CWD=$(pwd)

OPTIONAL_DEPS_FILE='optional-deps'
OPTIONAL_CONFIG_FILE='optional-config'

#  Array with list of execution lines
declare -a EXEC_CMD_LIST

# string of deps added to ffmpeg.SlackBuild
FFMPEG_DEPS=''

# usage:
#   sbopkgInstall PACKAGE [PARAMS]
function sbopkgInstall()
{
  EXEC_CMD="echo p  | $2 sbopkg -B -e stop -i $1"
  if [ $DEBUG_LEVEL -gt 2 ]; then
    echo $EXEC_CMD
  fi
  EXEC_CMD_LIST+=( "${EXEC_CMD}" )
}

# usage:
#   slackbuildInstall PACKAGE [PARAMS]
function slackbuildInstall()
{
  EXEC_CMD="(cd $1; $2 ./$1.SlackBuild && upgradepkg --reinstall --install-new /tmp/$1*_sfp.tgz )"
  if [ $DEBUG_LEVEL -gt 2 ]; then
    echo $EXEC_CMD
  fi
  EXEC_CMD_LIST+=( "${EXEC_CMD}" )
}

# Add configure option to ffmpeg.SlackBuild
# Usage:
#   addToFFMPEG option
function addToFFMPEG()
{
  if [ $DEBUG_LEVEL -gt 2 ]; then
    echo "ADD TO FFMPEG --enable-$1"
  fi
  FFMPEG_DEPS="${FFMPEG_DEPS}--enable-$1 "
}

# process one line of optional-config file, test if parameters are correct and
# generates parameters for ffmpeg
# Usage:
#   processConfigLine GROUP LINE
function processConfigLine()
{
  PARAMS=( $* )
  if [ ${#PARAMS[@]} -lt 3 ]; then
    echo "ERROR: In $OPTIONAL_CONFIG_FILE the line with '${PARAMS[@]:1}' in group '${PARAMS[0]}' is wrong, read comments in this file." 1>&2
    exit 1
  fi
  EXTRA_PARAMS=''
  RECURSIVE_PKG=false
  if [ ${#PARAMS[@]} -gt 3 ]; then
    for PARAM in "${PARAMS[@]:3}"; do
      if [ "${PARAM}" = "PARAM" ]; then
        addToFFMPEG ${PARAMS[1]}
      elif [[ "${PARAM}" =~ PARAM.* ]]; then
        FFMPEG_PARAM=$(echo ${PARAM} | cut -d '=' -f 2)
        IFS=':' read -r  -a FFMPEG_PARAM_ARR <<< ${FFMPEG_PARAM}
        if [ ${#FFMPEG_PARAM_ARR[@]} -gt 1 ]; then
          for FFPARAM in "${FFMPEG_PARAM_ARR[@]}"; do
            addToFFMPEG $FFPARAM
          done
        else
          addToFFMPEG $(echo ${PARAM} | cut -d '=' -f 2)
        fi
      elif [ ${PARAM} = "RECURSIVE" ]; then
        if [ $DEBUG_LEVEL -gt 0 ]; then
          echo "RECURSIVE package: ${PARAMS[1]}"
        fi
        RECURSIVE_PKG=true
      else
        EXTRA_PARAMS="${EXTRA_PARAMS}${PARAM} "
      fi
    done
  fi
  if [ $RECURSIVE = 'no' -a $RECURSIVE_PKG = true ]; then
    if [ $DEBUG_LEVEL -gt 1 ]; then
      echo "RECURSIVE package ignored: ${PARAMS[1]}"
    fi
  else
    if [ ${PARAMS[2]} = 'sbo' ]; then
      sbopkgInstall ${PARAMS[1]} "$EXTRA_PARAMS"
    elif [ ${PARAMS[2]} = 'slackbuild' ]; then
      slackbuildInstall ${PARAMS[1]} "$EXTRA_PARAMS"
    fi
    if [ $DEBUG_LEVEL -gt 0 ]; then
      echo "Group [${PARAMS[0]}]: add package ${PARAMS[1]}"
    fi
  fi
}


IFS=$'\n' command eval "OPTIONAL_LIST=($(sed -e 's/#.*$//' -e '/^$/d' ${OPTIONAL_DEPS_FILE}))"
if [ $DEBUG_LEVEL -gt 0 ]; then
  echo "Optional dependencies list: ${OPTIONAL_LIST[*]}"
fi

IN_GROUP='no'
BAD_OPTIONAL_PKG=( ${OPTIONAL_LIST[@]} )
# read optional config file and write extra parameters for ffmpeg
# first remove comment and empty lines (at end of while)
while IFS=' ' read -r CFG_LINE; do
  # verify if the line correspond to group name: "[package]"
  GROUP=$(echo $CFG_LINE | grep -E -o '\[.*\]')
  if [ ! -z "$GROUP" ]; then
    # extract pagacke group name
    GROUP=$(echo $GROUP | grep -E -o '[^][]+')
    # test if group is in OPTIONAL_LIST
    # remove element from array and asign result to TEST_LIST
    TEST_LIST=${OPTIONAL_LIST[@]#${GROUP}}
    BAD_OPTIONAL_PKG=( ${BAD_OPTIONAL_PKG[@]#${GROUP}} )
    if [ "${TEST_LIST}" != "${OPTIONAL_LIST[*]}" ]; then
      # unequal means group is in optional dependencies list
      echo "ADDING optional package: [$GROUP]"
      GROUPNAME=$GROUP
      IN_GROUP='yes'
    else
      if [ $DEBUG_LEVEL -gt 1 ]; then
        echo "Ignoring package group: [$GROUP]"
      fi
      IN_GROUP='no'
    fi
  else
    # add elements if group is in optional dependencies list
    if [ $IN_GROUP != 'no' ]; then
      processConfigLine $GROUPNAME $CFG_LINE
    fi
  fi
done <<< "$(sed -e 's/#.*$//' -e '/^$/d' $OPTIONAL_CONFIG_FILE)"

if [ ${#BAD_OPTIONAL_PKG[*]} -gt 0 ]; then
  echo "WARNING: Packages in $OPTIONAL_DEPS_FILE with no effect: ${BAD_OPTIONAL_PKG[*]}"
fi

for CMD in "${EXEC_CMD_LIST[@]}"; do
  if [ $SIMULATION != 'no' ]; then
    echo $CMD
  else
    eval $CMD || exit 1
  fi
done

export FFMPEG_DEPS

# cd ffmpeg
#  ./ffmpeg.SlackBuild
if [ $DEBUG_LEVEL -gt 0 ]; then
  echo "ffmpeg params to SlackBuild: "$FFMPEG_DEPS
fi
