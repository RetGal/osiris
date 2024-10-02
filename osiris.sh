#!/bin/sh

workingDir=/home/bot/maverage
scriptName=maverage.py
# -ac for holdntrade
params=
# only for maverage
exclude=mamaster
minFree=40960

resurrect() {
  instance=$1
  echo "resurrecting ${instance}"
  tmux has-session -t "${instance}" 2>/dev/null
  if [ $? -eq 1 ]; then
    tmux new -d -s "${instance}"
  fi
  sleep 2
  tmux send-keys -t "${instance}" C-z "${workingDir}/${scriptName} ${instance} ${params}" C-m
}

if [ ${minFree} -gt 0 ]; then
  available=$(free | awk 'NR == 2{print $7}')
  if [ "${available}" -lt ${minFree} ]; then
    echo "terminating all ${scriptName} instances"
    killall ${scriptName} 2>/dev/null
    sleep 2
  fi
fi

cd "${workingDir}" || exit 1

find . -name "*.pid" -type f 2>/dev/null | while read -r file;
do
  read -r pid instance < "${file}"
  if [ "${instance}" != ${exclude} ]; then
    if kill -0 "${pid}" 2>/dev/null; then
      processName=$(ps --pid "${pid}" -o comm h)
      if [ "${scriptName}" = "${processName}" ]; then
        echo "${instance} is alive"
        continue
      fi
    fi
    resurrect "${instance}"
  fi
done
