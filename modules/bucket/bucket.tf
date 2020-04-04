variable "domain_name" {}

# https://www.terraform.io/docs/providers/template/d/file.html
data "template_file" "json-bucket-policy" {
  template = "${file("${path.module}/templates/bucket_policy.tpl.json")}"
  vars     = {
    domain_name = var.domain_name
  }
}
data "template_file" "html-index" {
  template = "${file("${path.module}/templates/index.tpl.html")}"
  vars     = {
    domain_name = var.domain_name
  }
}
data "template_file" "html-404" {
  template = "${file("${path.module}/templates/404.tpl.html")}"
  vars     = {
    domain_name = var.domain_name
  }
}

# https://www.terraform.io/docs/providers/aws/r/s3_bucket.html
resource "aws_s3_bucket" "bucket-apex" {
  bucket = var.domain_name
  acl    = "private"
  policy = data.template_file.json-bucket-policy.rendered

  website {
    index_document = "index.html"
    error_document = "404.html"
    routing_rules  = <<ROUTING_RULE
[{
    "Condition": {
        "KeyPrefixEquals": "/"
    },
    "Redirect": {
        "ReplaceKeyWith": "index.html"
    }
}]
ROUTING_RULE
  }

  tags = {
    Site = var.domain_name
    Type = "website"
    Function = "serve"
  }

}
resource "aws_s3_bucket" "bucket-apex-log" {
  bucket = format("%s-log", var.domain_name)
  acl    = "private"

  tags = {
    Site = var.domain_name
    Type = "website"
    Function = "logging"
  }

}
resource "aws_s3_bucket" "bucket-www" {
  bucket = format("www.%s", var.domain_name)
  acl    = "private"

  website {
    redirect_all_requests_to = format("https://%s", var.domain_name)
  }

  tags = {
    Site = format("www.%s", var.domain_name)
    Type = "website"
    Function = "redirect"
  }

}

# https://www.terraform.io/docs/providers/aws/r/route53_zone.html
data "aws_route53_zone" "dns_zone" {
  name         = var.domain_name
  private_zone = false
}

# https://www.terraform.io/docs/providers/aws/r/route53_record.html
# https://docs.aws.amazon.com/general/latest/gr/s3.html
resource "aws_route53_record" "dns_record_www_v4" {
  zone_id = data.aws_route53_zone.dns_zone.id
  name    = format("www.%s", var.domain_name)
  type    = "A"

  alias {
    name                   = "s3-website-eu-west-1.amazonaws.com"
    zone_id                = "Z1BKCTXD74EZPE"
    evaluate_target_health = false
  }
}
resource "aws_route53_record" "dns_record_www_v6" {
  zone_id = data.aws_route53_zone.dns_zone.id
  name    = format("www.%s", var.domain_name)
  type    = "AAAA"

  alias {
    name                   = "s3-website-eu-west-1.amazonaws.com"
    zone_id                = "Z1BKCTXD74EZPE"
    evaluate_target_health = false
  }
}

# https://www.terraform.io/docs/providers/aws/r/s3_bucket_object.html
resource "aws_s3_bucket_object" "bucket-apex_html-index" {
  bucket         = var.domain_name
  key            = "index.html"
  content_base64 = base64encode(data.template_file.html-index.rendered)
  etag           = md5(data.template_file.html-index.rendered)
  content_type   = "text/html; charset=utf-8"

  depends_on = [
    aws_s3_bucket.bucket-apex
  ]
}
resource "aws_s3_bucket_object" "bucket-apex_html-404" {
  bucket         = var.domain_name
  key            = "404.html"
  content_base64 = base64encode(data.template_file.html-404.rendered)
  etag           = md5(data.template_file.html-404.rendered)
  content_type   = "text/html; charset=utf-8"

  depends_on = [
    aws_s3_bucket.bucket-apex
  ]
}

output "dns_zone_id" {
  value       = data.aws_route53_zone.dns_zone.id
  description = "Zone Id for domain"
}
output "bucket_apex_url" {
  value       = aws_s3_bucket.bucket-apex.bucket_regional_domain_name
  description = "apex bucket URL as BUCKET_NAME.s3.amazonaws.com"
}
output "bucket_log_url" {
  value       = aws_s3_bucket.bucket-apex-log.bucket_regional_domain_name
  description = "log bucket URL as BUCKET_NAME.s3.amazonaws.com"
}
