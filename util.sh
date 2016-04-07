#!/bin/bash

###############################################################################################
WORKDIR=$(cd `dirname $0`; pwd)
cd ${WORKDIR}

###############################################################################################
REPO_NAME="discourse"

#discourse_docker repo config
REPO_URL="https://github.com/discourse/discourse_docker.git"
BRANCH="cc36cf2196c5848608d291689182a7372011ea67"
TARGET_DIR="${WORKDIR}/discourse"

#discourse config
APP_NAME="app"
FORUM_CFG_YML_TEMPLATE="${TARGET_DIR}/samples/standalone.yml"
FORUM_CFG_YML="${TARGET_DIR}/containers/${APP_NAME}.yml"

###############################################################################################
function quit() {
  EXIT_CODE=$1
  ERR_MSG=$2
  if [ ${EXIT_CODE} -ne 0 ];then
    echo "[ERROR] - ${EXIT_CODE} - ${ERR_MSG}:("
    exit 1
  fi
}

function log(){
  module=$1
  log_msg=$2
  echo "[$(date +'%F %T')] - (${module}) : ${log_msg}"
}

function load_config() {
  if [ ! -s ${WORKDIR}/etc/discourse.conf ];then
    quit 1 "Can not find config file ${WORKDIR}/etc/discourse.conf, please create it ,then try again"
  fi

  source ${WORKDIR}/etc/discourse.conf

  cat <<EOF
=====================================================================
FORUM_PORT     : "${FORUM_PORT}"
FORUM_SSL_PORT : "${FORUM_SSL_PORT}"
FORUM_EMAIL    : "${FORUM_EMAIL}"
FORUM_URL      : "${FORUM_URL}"
---------------------------------------------------------------------
FORUM_SMTP_SERVER   : "${FORUM_SMTP_SERVER}"
FORUM_SMTP_PORT     : "${FORUM_SMTP_PORT}"
FORUM_SMTP_SSL_TYPE : "${FORUM_SMTP_SSL_TYPE}"
FORUM_SMTP_USERNAME : "${FORUM_SMTP_USERNAME}"
FORUM_SMTP_PASSWORD : "${FORUM_SMTP_PASSWORD}"
---------------------------------------------------------------------
ENV_HTTP_PROXY  : "${ENV_HTTP_PROXY}"
ENV_HTTPS_PROXY : "${ENV_HTTPS_PROXY}"
=====================================================================
EOF
}

function check_config() {
  [ "${FORUM_PORT}" == "" ] && quit 1 "missing config parameter : ${FORUM_PORT}"
  [ "${FORUM_SSL_PORT}" == "" ] && quit 1 "missing config parameter : ${FORUM_SSL_PORT}"
  [ "${FORUM_EMAIL}" == "" ] && quit 1 "missing config parameter : ${FORUM_EMAIL}"
  [ "${FORUM_URL}" == "" ] && quit 1 "missing config parameter : ${FORUM_URL}"
  [ "${FORUM_SMTP_SERVER}" == "" ] && quit 1 "missing config parameter : ${FORUM_SMTP_SERVER}"
  [ "${FORUM_SMTP_PORT}" == "" ] && quit 1 "missing config parameter : ${FORUM_SMTP_PORT}"
  [ "${FORUM_SMTP_SSL_TYPE}" == "" ] && quit 1 "missing config parameter : ${FORUM_SMTP_SSL_TYPE}"
  [ "${FORUM_SMTP_USERNAME}" == "" ] && quit 1 "missing config parameter : ${FORUM_SMTP_USERNAME}"
  [ "${FORUM_SMTP_PASSWORD}" == "" ] && quit 1 "missing config parameter : ${FORUM_SMTP_PASSWORD}"
  [ "${ENV_HTTP_PROXY}" == "" ] && quit 1 "missing config parameter : ${ENV_HTTP_PROXY}"
  [ "${ENV_HTTPS_PROXY}" == "" ] && quit 1 "missing config parameter : ${ENV_HTTPS_PROXY}"
  log "check_config" "check config pass:)"
}

function clone_repo(){
  fn_name="clone_repo"
  cd ${WORKDIR}
  if [ -d ${TARGET_DIR}/.git ];then
    log "${fn_name}" "${TARGET_DIR} found"
    cd ${TARGET_DIR}
    CUR_BRANCH=$(git rev-parse HEAD)
    if [ "${BRANCH}" == "${CUR_BRANCH}" ];then
      log "${fn_name}" "${REPO_NAME} no need update"
    else
      git checkout master -f && git reset --hard HEAD && git pull
      quit $? "${REPO_NAME} need update, but git pull failed"
    fi
  else
    git clone ${REPO_URL} ${TARGET_DIR}
    quit $? "${REPO_NAME} not exist, and git clone failed"
  fi
  cd ${WORKDIR}/${REPO_NAME} && git checkout ${BRANCH} -f >/dev/null 2>&1
  quit $? "check out to specified commit '${BRANCH}'"

  log "${fn_name}" "${REPO_NAME} repo is ready:)"
}

function start_app() {
  fn_name="generate_config"
  log "${fn_name}" "prepare ${APP_NAME}.yml from template"
  if [ -s ${FORUM_CFG_YML_TEMPLATE} ];then
    [ -f ${FORUM_CFG_YML} ] && rm -rf ${FORUM_CFG_YML}
    cp ${FORUM_CFG_YML_TEMPLATE} ${FORUM_CFG_YML}
  fi

  log "${fn_name}" "update ${APP_NAME}.yml"
  #email,domain
  sed -i "s%\- \".*:80\"%\- \"${FORUM_PORT}:80\"%g" ${FORUM_CFG_YML}
  sed -i "s%\- \".*:443\"%\- \"${FORUM_SSL_PORT}:443\"%g" ${FORUM_CFG_YML}
  sed -i "s%DISCOURSE_DEVELOPER_EMAILS: '.*'*%DISCOURSE_DEVELOPER_EMAILS: '${FORUM_EMAIL}'%g" ${FORUM_CFG_YML}
  sed -i "s%DISCOURSE_HOSTNAME: '.*'*%DISCOURSE_HOSTNAME: '${FORUM_URL}'%g" ${FORUM_CFG_YML}
  #smtp
  sed -i "s%.*DISCOURSE_SMTP_ADDRESS: .*%  DISCOURSE_SMTP_ADDRESS: '${FORUM_SMTP_SERVER}'%g" ${FORUM_CFG_YML}
  sed -i "s%.*DISCOURSE_SMTP_PORT: .*%  DISCOURSE_SMTP_PORT: '${FORUM_SMTP_PORT}'%g" ${FORUM_CFG_YML}
  sed -i "s%.*DISCOURSE_SMTP_USER_NAME: .*%  DISCOURSE_SMTP_USER_NAME: '${FORUM_SMTP_USERNAME}'%g" ${FORUM_CFG_YML}
  sed -i "s%.*DISCOURSE_SMTP_PASSWORD: .*%  DISCOURSE_SMTP_PASSWORD: '${FORUM_SMTP_PASSWORD}'%g" ${FORUM_CFG_YML}
  sed -i "s%.*DISCOURSE_SMTP_ENABLE_START_TLS: .*%  DISCOURSE_SMTP_ENABLE_START_TLS: '${FORUM_SMTP_SSL_TYPE}'%g" ${FORUM_CFG_YML}
  #proxy
  sed -i "/^env:/c\env:\n  http_proxy: ${ENV_HTTP_PROXY}\n  https_proxy: ${ENV_HTTPS_PROXY}\n" ${FORUM_CFG_YML}

  log "${fn_name}" "view config"
  echo "----------------------------------------------------"
  cat ${FORUM_CFG_YML} | grep -E '(^  DISCOURSE_SMTP|EMAILS:|DISCOURSE_HOSTNAME:|:80|:443|http_proxy|https_proxy)'
  echo "----------------------------------------------------"

  log "${fn_name}" "check config change"
  if [ -f ${FORUM_CFG_YML}.md5 ];then
    LAST_CHECKSUM=$(cat ${FORUM_CFG_YML}.md5)
  else
    LAST_CHECKSUM=""
  fi
  NEW_CHECKSUM=$(md5sum ${FORUM_CFG_YML})
  cat <<EOF
  LAST CHECKSUM: ${LAST_CHECKSUM}
  NEW CHECKSUM : ${NEW_CHECKSUM}
EOF
  if [ "${NEW_CHECKSUM}" != "${LAST_CHECKSUM}" ];then
    log "${fn_name}" "${FORUM_CFG_YML} has changed, need rebuild app"
    cd ${TARGET_DIR} && ./launcher rebuild ${APP_NAME}
    quit $? "rebuild failed"
    log "${fn_name}" "generate and save md5 for ${FORUM_CFG_YML}"
    md5sum ${FORUM_CFG_YML} > ${FORUM_CFG_YML}.md5
  else
    log "${fn_name}" "${FORUM_CFG_YML} hasn't changed, ensure app start"
    IS_RUNNING=$(docker ps | grep 'local_discourse/app.*app'|wc -l)
    if [ ${IS_RUNNING} -eq 0 ];then
      cd ${TARGET_DIR} && ./launcher start ${APP_NAME}
      quit $? "start ${APP_NAME} failed"
    else
      echo "app '${APP_NAME}' is running"
    fi
  fi
  echo ""
  echo "running container:"
  echo "==========================================================================================================================================================="
  docker ps -f name=app
  echo "==========================================================================================================================================================="
}

###############################################################################################
load_config

check_config

clone_repo

start_app

echo "Done!"
