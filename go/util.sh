#!/bin/bash

SH_NAME=$(basename $0)

if [ ! -f etc/config ];then
  cp etc/config.template etc/config
  echo "Config file 'etc/config' was generated, you can update it if needed."
  sleep 1
fi

#load Variable
echo "Found ./etc/config, load it now"
. ./etc/config

eval HYPER_ACCESS_KEY=`echo $(cat ~/.hyper/config.json | grep "tcp://${G_API_ROUTER}" -A2 | grep accesskey | awk  'BEGIN{FS="[:,]"}{print $2}' )`
eval HYPER_SECRET_KEY=`echo $(cat ~/.hyper/config.json | grep "tcp://${G_API_ROUTER}" -A2 | grep secretkey | awk  'BEGIN{FS="[:,]"}{print $2}' )`
echo "use Hyper.sh credential: AccessKey(${HYPER_ACCESS_KEY})"

if [ "$HYPER_ACCESS_KEY" == "" ];then
  echo "can not found Hyper.sh credential"
  exit 1
fi

###############################################################
function show_usage() {
  cat <<EOF
Usage: ./${SH_NAME} <ACTION> [OPTION]

<ACTION>:
 - ps                        : list test container
 - run                       : run test container
 - stop                      : stop test container
 - start                     : start test container
 - rm                        : remove test container
 - watch <FILTER> [CASE_NO]  : run watch with filter

<FILTER>:
 - container : use container.lst
 - image     : use image.lst
 - label     : use label.lst
 - event     : use event.lst

[CASE_NO]:
 - <empty>     : show watch filter list.
 - <not empty> : start websocket client to watch with filter

Example:
  ./${SH_NAME} run
  ./${SH_NAME} watch container
  ./${SH_NAME} watch container 1
  ./${SH_NAME} stop

EOF
  exit 1
}

function show_test_usage() {
  SH_NAME=$(basename $0)
  cat <<EOF
Usage: ./${SH_NAME} watch <FILTER> [CASE_NO]

<FILTER>:
 - container : use container.lst
 - image     : use image.lst
 - label     : use label.lst
 - event     : use event.lst

[CASE_NO]:
 - <empty>     : show watch filter list.
 - <not empty> : start websocket client to watch with filter

Example:
  ./${SH_NAME} watch container
  ./${SH_NAME} watch container 1

EOF
  exit 1
}

function ps_container(){
  echo -e "\nlist container:"
  echo "======================================"
  ${G_HYPERCLI} ps -a --filter name=${G_TEST_CONTAINER1} --filter name=${G_TEST_CONTAINER2}
}

function run_container() {
  TEST_CONTAINER=$1
  TEST_IMAGE=$2
  echo -e "\ncheck container: ${TEST_CONTAINER}"
  echo "======================================"
  n=$(${G_HYPERCLI} ps -a --filter name=${TEST_CONTAINER}|wc -l)
  if [ $n -ne 1  ];then
    echo "${TEST_CONTAINER} is existed"
  else
    echo "start container: ${TEST_CONTAINER}"
    echo "--------------------------------------"
    ${G_HYPERCLI} run -d --name=${TEST_CONTAINER} \
      --size=s1 \
      --label="" --label="id=test1" --label="empty" --label="type=test" --label="key=test1=test1" \
      ${TEST_IMAGE} top
  fi
}

function start_stop_container() {
  ACTION=$1
  TEST_CONTAINER=$2
  echo -e "\ncheck container: ${TEST_CONTAINER}"
  echo "======================================"
  n=$(${G_HYPERCLI} ps -a --filter name=${TEST_CONTAINER}|wc -l)
  if [ $n -ne 1  ];then
    echo "$ACTION container: $TEST_CONTAINER"
    echo "--------------------------------------"
    ${G_HYPERCLI} $ACTION $TEST_CONTAINER
  else
    echo "${TEST_CONTAINER} isn't existed, please run './${SH_NAME} run' first!"
  fi
}

function rm_container() {
  TEST_CONTAINER=$1
  echo -e "\ncheck container: ${TEST_CONTAINER}"
  echo "======================================"
  n=$(${G_HYPERCLI} ps -a --filter name=${TEST_CONTAINER}|wc -l)
  if [ $n -ne 1  ];then
    echo "remove container: $TEST_CONTAINER"
    echo "--------------------------------------"
    ${G_HYPERCLI} rm -fv ${TEST_CONTAINER}
  else
    echo "${TEST_CONTAINER} isn't existed, skip"
  fi
}

function do_watch() {
  FILTER=$1
  NO=$2
  TEST_FILE="testcase/${FILTER}.lst"

  if [ "${FILTER}" == "" ];then
    show_test_usage
  fi

  if [ ! -f ${TEST_FILE} ];then
    echo "Error: ${TEST_FILE} not found,exit"
    exit 1
  fi

  if [ "$NO" == "" ];then
    echo "list test case in ${TEST_FILE}"
    echo "===================================="
    grep -n "" ${TEST_FILE}
    echo "===================================="
    return
  fi

  echo -e "\nstart websocket client:"
  FILTER_COND=`sed -n "${NO}p" ${TEST_FILE}`
  if [ "$FILTER_COND" != "" ];then
    FILTER_COND="--filter=${FILTER_COND}"
  fi
  TEST_CMD="go run wsclient.go --addr=${G_API_ROUTER} --accessKey $HYPER_ACCESS_KEY  --secretKey $HYPER_SECRET_KEY ${FILTER_COND}"

  if [ "${FILTER}" == "container" ];then
    TEST_CONTAINER1_ID_FULL=`${G_HYPERCLI} ps -aq --no-trunc --filter=name=${G_TEST_CONTAINER1}`
    TEST_CONTAINER1_ID_PREFIX=${TEST_CONTAINER1_ID_FULL:0:12}
    TEST_CONTAINER1_NAME=${G_TEST_CONTAINER1}
    echo "TEST_CONTAINER1_ID_FULL: ${TEST_CONTAINER1_ID_FULL}"
    echo "TEST_CONTAINER1_ID_PREFIX: ${TEST_CONTAINER1_ID_PREFIX}"
    echo "TEST_CONTAINER1_NAME: ${TEST_CONTAINER1_NAME}"
    TEST_CMD=${TEST_CMD/TEST_CONTAINER1_ID_FULL/${TEST_CONTAINER1_ID_FULL}}
    TEST_CMD=${TEST_CMD/TEST_CONTAINER1_ID_PREFIX/${TEST_CONTAINER1_ID_PREFIX}}
    TEST_CMD=${TEST_CMD/TEST_CONTAINER1_NAME/${TEST_CONTAINER1_NAME}}
  fi

  if [ "${FILTER}" == "image" ];then
    TEST_IMAGE2_ID_FULL=`${G_HYPERCLI} images --no-trunc | grep "^${G_TEST_IMAGE2}.*latest" | awk '{print $3}'`
    TEST_IMAGE2_ID_FULL=${TEST_IMAGE2_ID_FULL:7}
    TEST_IMAGE2_ID_PREFIX=${TEST_IMAGE2_ID_FULL:0:12}
    echo "TEST_IMAGE2_ID_FULL: ${TEST_IMAGE2_ID_FULL}"
    echo "TEST_IMAGE2_ID_PREFIX: ${TEST_IMAGE2_ID_PREFIX}"
    TEST_CMD=${TEST_CMD/TEST_IMAGE2_ID_FULL/${TEST_IMAGE2_ID_FULL}}
    TEST_CMD=${TEST_CMD/TEST_IMAGE2_ID_PREFIX/${TEST_IMAGE2_ID_PREFIX}}
  fi

  echo -e "TEST_CMD: [\n${TEST_CMD}\n]"
  eval ${TEST_CMD}
}

#######################################
##               main                ##
#######################################
case $1 in
  run)
    run_container $G_TEST_CONTAINER1 $G_TEST_IMAGE1
    run_container $G_TEST_CONTAINER2 $G_TEST_IMAGE2
    ps_container
    ;;
  start|stop)
    start_stop_container $1 $G_TEST_CONTAINER1
    start_stop_container $1 $G_TEST_CONTAINER2
    ps_container
    ;;
  rm)
    rm_container $G_TEST_CONTAINER1
    rm_container $G_TEST_CONTAINER2
    ps_container
    ;;
  ps)
    ps_container
    ;;
  watch)
    shift 1
    do_watch $@
    ;;
  *) show_usage
esac

echo
