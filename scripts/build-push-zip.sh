#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo $SCRIPT_DIR
WORKSPACE=$( dirname ${SCRIPT_DIR} )
echo $WORKSPACE
source ${SCRIPT_DIR}/env


# build the dist dir
npm run build

# build the small zip file
zip -r zips/small.zip dist
aws s3 cp zips/small.zip s3://${BUCKET}/${PREFIX}/small.zip

# build the large zip file
mv large-file.txt dist/
zip -r zips/large dist
mv dist/large-file.txt ./
aws s3 cp zips/large.zip s3://${BUCKET}/${PREFIX}/large.zip

# log in to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# build the small docker image
docker build -f ${WORKSPACE}/Dockerfile -t docker-lambda-benchmark:small $WORKSPACE
docker tag docker-lambda-benchmark:small $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/docker-lambda-benchmark-lambda:small
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/docker-lambda-benchmark-lambda:small

# build the large docker image
docker build -f ${WORKSPACE}/Dockerfile.large -t docker-lambda-benchmark:large $WORKSPACE
docker tag docker-lambda-benchmark:large $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/docker-lambda-benchmark-lambda:large
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/docker-lambda-benchmark-lambda:large