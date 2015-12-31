#!/bin/sh

CWD=$(pwd)
DOWNLOAD_DIR='downloads'
DOWNLOAD_PATH=$CWD/$DOWNLOAD_DIR

set -e

INFO_FILES=$(find . -name '*.info')

# test if a file exists and if md5sum it's ok
# how to use downloadSources:
#   testSource URL MD5SUM
#     return 'ok' if the sources exists and this pass md5sum check.
#     return 'md5sum' otherwise or 'false' if file doesn't exists
function testSource()
{
  FILE=$(basename $1)
  if [ -f $FILE ]; then
    FILE_MD5SUM=$(md5sum $FILE | cut -d ' ' -f 1)
    if [ $FILE_MD5SUM = $2 ]; then
      echo 'ok'
    else
      echo $FILE_MD5SUM
    fi
  else
    echo 'File not exists'
  fi
}

# downloadSource url and test with md5sum
# how to use:
# downloadSource URL MD5SUM
function downloadSource()
{
  wget $1 || exit 1
  FILE=$(basename $1)
  echo "Check md5sum to $FILE"
  TEST=$(testSource $1 $2)
  if [ $TEST != 'ok' ]; then
    echo "Fail when downloading from $1" 1>&2
    echo "md5sum not match: $TEST" 1>&2
    echo "expected: $2" 1>&2
    exit 1
  else
    echo "md5sum OK"
  fi
}

# make a symbolic link of an FILE in download path
# of an INFOFILE path.
# how to use:
#   makeSymbolicLink INFOFILE FILE
function makeSymbolicLink()
{
  ( cd $(dirname "$CWD/$1")
    ln -sf ../$DOWNLOAD_DIR/$2 $2
  )
}

if [ ! -d $DOWNLOAD_PATH ]; then
  mkdir $DOWNLOAD_PATH
fi

cd $DOWNLOAD_PATH
for INFO in $INFO_FILES; do
  . $CWD/$INFO
  IFS=' ' read -r -a MD5SUM_ARRAY <<< $MD5SUM
  IFS=' ' read -r -a URL_ARRAY <<< $DOWNLOAD
  for index in ${!URL_ARRAY[@]}; do
    TEST=$(testSource ${URL_ARRAY[index]} ${MD5SUM_ARRAY[index]})
    FILE=$(basename ${URL_ARRAY[index]})
    if [ "$TEST" != 'ok' ]; then
      echo "Downloading ${URL_ARRAY[index]}"
      downloadSource ${URL_ARRAY[index]} ${MD5SUM_ARRAY[index]}
    else
      echo "md5sum $FILE OK"
    fi
    makeSymbolicLink $INFO $FILE
  done
done
