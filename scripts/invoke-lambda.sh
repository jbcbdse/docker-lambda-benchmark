#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo $SCRIPT_DIR
source ${SCRIPT_DIR}/env


for fn in zip-small zip-large image-small image-large; do
  for num in $(seq 1 20); do
    echo $num $fn
    aws --region $AWS_REGION lambda invoke \
      --cli-binary-format raw-in-base64-out  \
      --function-name docker-lambda-benchmark-$fn \
      --payload '{ "hello": "world" }' \
      --invocation-type Event \
      /dev/stdout &
  done;
done;