
# S3 static website with SSL/TLS 
<div align="center">
<img src="https://github.com/Kyrylo-Lomko/cicd/blob/main/Screenshot%202023-10-06%20at%209.55.01%20AM.png?raw=true" align="center" height="400" width="800" />
</div>

## 🚀 Getting Started
This README is for the S3 static website with an SSL/TLS (ACM) certificate deployed via Terraform. 

## 🔢 Requirements
* Terraform version ~> 1.5.0
* AWS account with admin access
* Domain name integrated with Route53
* AWS CLI

## 🥙 Providers
* AWS

## 🏗️ Building S3 static website
This repo contains an S3 static website with an SSL (ACM) certificate deployed via Terraform deployed on AWS. It consists of main.tf, providers.tf, variables.tf and Makefile.
1. First S3 bucket, bucket configurations, and bucket policy are being defined.
2. Static website configurations and ownership controls. Here S3 is transformed into a static website and index.html and other files are put into the bucket. 
3. SSL/TLC certificate requests from AWS ACM. 
4. CloudFront distribution creation. 
5. Route53 record creation.
 
## S3 module inputs

|         Name         |   Description   |  Type  | Default         |
| :-------------------:|:---------------:|:------:|:---------------:|             
| domain_name            | s3/domain name            | string |    khlyuzder.com  |
___

References: 
1. [S3 Terraform Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket.html) 
2. [Hosting a Secure Static Website on AWS S3 using Terraform](https://www.alexhyett.com/terraform-s3-static-website-hosting/) 
