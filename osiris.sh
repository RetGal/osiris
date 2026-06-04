#!/bin/sh

workingDir=/home/bot/maverage
scriptName=maverage.py
# virtual environment directory
venvDir=
# -ac for holdntrade
params=
# only for maverage
exclude=mamaster
minFree=40960

set -e

resurrect() {
  instance=$1
  echo "resurrecting ${instance}"
  if ! tmux has-session -t "${instance}" 2>/dev/null; then
    tmux new -d -s "${instance}"
    sleep 1
  fi
  tmux send-keys -t "${instance}" C-z "python ${workingDir}/${scriptName} ${instance} ${params}" C-m
}

check_memory() {
  if [ ${minFree} -gt 0 ]; then
    available=$(free | awk 'NR == 2{print $7}')
    if [ "${available}" -lt ${minFree} ]; then
      echo "terminating all python processes"
      killall python 2>/dev/null
    fi
  fi
}

activate_venv() {
  [ -n "${venvDir}" ] && . "${venvDir}/bin/activate"
}

process_instances() {
  find . -name "*.pid" -type f 2>/dev/null | while read -r file; do
    read -r pid instance < "${file}"
    if [ "${instance}" != "${exclude}" ]; then
      if ! (kill -0 "${pid}" 2>/dev/null && ps --pid "${pid}" -o comm= | grep -q "python"); then
        resurrect "${instance}"
      else
        echo "${instance} is alive"
      fi
    fi
  done
}

check_memory
cd "${workingDir}" || exit 1
activate_venv
process_instances