terraform-static-cdn
===

## Run

* `AWS_PROFILE=<YOUR_AWS_PROFILE> terraform plan`
* `AWS_PROFILE=<YOUR_AWS_PROFILE> terraform apply`

## Feature/ Todo

* [x] AWS S3 bucket as CloudFront origin
  * [x] Direct HTTP access for testing
  * [x] Starter index.html
  * [x] Starter 404.html
  * [ ] AWS S3 flag to disable bucket direct access
* [x] AWS S3 bucket for access logs
* [x] AWS S3 bucket for www redirect
* [x] AWS ACM for CloudFront
  * [x] Logging support
  * [x] IPv6 support
  * [x] TLS support (AWS signed)
  * [x] HTTP to TLS redirect
  * [x] Single page error reporting
* [x] AWS CF as CDN
* [x] AWS R53 to verify ACM
* [x] AWS R53 for CloudFront A
* [x] AWS R53 for CloudFront AAAA
* [x] AWS R53 for www redirect A
* [x] AWS R53 for www redirect AAAA
* [ ] Add pipeline support eg. [CodeBuild](https://aws.amazon.com/de/blogs/security/how-use-ci-cd-deploy-configure-aws-security-services-terraform/)
* [ ] Add support for different environments
* [ ] Integrate Hugo / webpack

## Inspiration

* AWS
    * https://github.com/lony/page_shouldiautomate.it
