#!/usr/bin/env bash
set -xeuo pipefail

APP_NAME=rate_limiter
CLI_NAME=cli
login=test
pass=test
ip=133.0.4.1
ip_mask=133.0.4.0/24

make build
make compose-up-db

function testTrue() {
  if [[ "$1" == "true" ]]; then
    return
  else
    tryToKill $2
    exit 1
  fi
}

function testFalse() {
  if [[ "$1" == "false" ]]; then
    return
  else
    tryToKill $2
    exit 1
  fi
}

function tryToKill() {
  if ps -p $1 > /dev/null
  then
     kill $1 2> /dev/null || true
  fi
}

function testFullBucket() {
  for (( i=1; i<=6; i++ )); do
    OUTPUT="$(./$CLI_NAME --conf=.env.docker --cmd=check --login=${login} --pass=${pass} --ip=${ip})"
    testTrue "$OUTPUT" "1"
  done
  OUTPUT="$(./$CLI_NAME --conf=.env.docker --cmd=check --login=${login} --pass=${pass} --ip=${ip})"
  testFalse "$OUTPUT" "$1"
}

function testBlacklist() {
  ./$CLI_NAME --conf=.env.docker --cmd=ab --ip=${ip_mask}
  OUTPUT="$(./$CLI_NAME --conf=.env.docker --cmd=check --login=${login} --pass=${pass} --ip=${ip})"
  testFalse "$OUTPUT" "1"
  ./$CLI_NAME --conf=.env.docker --cmd=rb --ip=${ip_mask}
  for (( i=1; i<=6; i++ )); do
    OUTPUT="$(./$CLI_NAME --conf=.env.docker --cmd=check --login=${login} --pass=${pass} --ip=${ip})"
    testTrue "$OUTPUT" "1"
  done
  OUTPUT="$(./$CLI_NAME --conf=.env.docker --cmd=check --login=${login} --pass=${pass} --ip=${ip})"
  testFalse "$OUTPUT" "$1"
}

function testWhitelist() {
  for (( i=1; i<=6; i++ )); do
    OUTPUT="$(./$CLI_NAME --conf=.env.docker --cmd=check --login=${login} --pass=${pass} --ip=${ip})"
    testTrue "$OUTPUT" "1"
  done
  ./$CLI_NAME --conf=.env.docker --cmd=aw --ip=${ip_mask}
  OUTPUT="$(./$CLI_NAME --conf=.env.docker --cmd=check --login=${login} --pass=${pass} --ip=${ip})"
  testTrue "$OUTPUT" "1"
  ./$CLI_NAME --conf=.env.docker --cmd=rw --ip=${ip_mask}
  OUTPUT="$(./$CLI_NAME --conf=.env.docker --cmd=check --login=${login} --pass=${pass} --ip=${ip})"
  testFalse "$OUTPUT" "$1"
}

function testReset() {
  for (( i=1; i<=6; i++ )); do
    OUTPUT="$(./$CLI_NAME --conf=.env.docker --cmd=check --login=${login} --pass=${pass} --ip=${ip})"
    testTrue "$OUTPUT" "1"
  done
  OUTPUT="$(./$CLI_NAME --conf=.env.docker --cmd=check --login=${login} --pass=${pass} --ip=${ip})"
  testFalse "$OUTPUT" "$1"
  ./$CLI_NAME --conf=.env.docker --cmd=reset --login=${login} --ip=${ip_mask}
  for (( i=1; i<=6; i++ )); do
    OUTPUT="$(./$CLI_NAME --conf=.env.docker --cmd=check --login=${login} --pass=${pass} --ip=${ip})"
    testTrue "$OUTPUT" "1"
  done
  OUTPUT="$(./$CLI_NAME --conf=.env.docker --cmd=check --login=${login} --pass=${pass} --ip=${ip})"
  testFalse "$OUTPUT" "$1"
}

./$APP_NAME --conf=.env.docker > /dev/null &
RL_PID=$!
sleep 3
testFullBucket ${RL_PID}
tryToKill ${RL_PID} 2> /dev/null || true

./$APP_NAME --conf=.env.docker > /dev/null &
RL_PID=$!
sleep 3
testBlacklist ${RL_PID}
tryToKill ${RL_PID} 2> /dev/null || true

./$APP_NAME --conf=.env.docker > /dev/null &
RL_PID=$!
sleep 3
testWhitelist ${RL_PID}
tryToKill ${RL_PID} 2> /dev/null || true

./$APP_NAME --conf=.env.docker > /dev/null &
RL_PID=$!
sleep 3
testReset ${RL_PID}
tryToKill ${RL_PID} 2> /dev/null || true

rm ./$APP_NAME
rm ./$CLI_NAME

echo "PASS"

