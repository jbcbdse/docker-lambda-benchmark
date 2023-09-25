[See blog post](https://jonbarnett.hashnode.dev/cold-starts-in-aws-lambda-with-container-images-in-2023)

# Cold start times of Docker image AWS Lambda functions

Use Terraform to initialize infrastructure. From the terraform directory:

```
terraform init
```

When prompted provide an existing S3 bucket and folder where state will be stored.

Create a file named `vars.auto.tfvars` and provide variables:

```
lambda_bucket = "<bucket name to create>"
lambda_prefix = "<folder to store zip files>"
```

```
terraform apply
```

This will create the needed infrastructure.

The lambda functions may fail to deploy the first time until you push the Docker images and zip bundles.

Next, build the Docker image. From the scripts directory:

```
export BUCKET=<your S3 bucket as created by terraform>
export PREFIX=<folder in s3 you provided above>
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=<your AWS account id>
./build-push-zip.sh
```

This will build the application (the very tiny `handle` function) into a .zip 
file and upload it to S3.

This will upload 2 zip files: 1 small, and 1 larger including large-file.txt in the bundle.

It will also build the Docker image and push it to ECR. It will include 2 versions: the large version with large-file.txt and the small version without. These images will be pushed to the ECR repository created by Terraform.

You may need to re-create the Lambda function after uploading the bundles the first time. From the scripts directory run `./taint-functions.sh`. Then, from the terraform directory, re-run `terraform apply`.

To finally run the test, from the scripts diretcory, run `./invoke-lambda.sh`. This will run each lambda 20 times in quick succession. Since the Lambdas will pause for 5 seconds, this should create a lot of concurrent cold starts.

To see the results, look at CloudWatch Insights. Terraform deployed a query you can start with to observe results.
