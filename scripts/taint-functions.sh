#!/bin/bash

## Taint the functions so that Terraform will redeploy them. This should force new cold starts

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo $SCRIPT_DIR
source ${SCRIPT_DIR}/env

cd ${SCRIPT_DIR}/../terraform

for res in aws_lambda_function.zip_small aws_lambda_function.zip_large aws_lambda_function.image_small aws_lambda_function.image_large; do
  terraform taint $res; 
done

cd -
