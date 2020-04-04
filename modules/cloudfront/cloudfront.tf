variable "domain_name" {}
variable "cert_ssl_arn" {}
variable "bucket_apex_url" {}
variable "bucket_log_url" {}
variable "dns_zone_id" {}

locals {
    origin_access_id        = "S3ApexOrigin"
    methods                 = ["HEAD", "GET", "OPTIONS"]
    #           MinTTL      DefaultTTL  MaxTTL      ErrorCachingMinTTL
    # DEV       0           0           0           0
    # STAGE     0           900         900         900
    # PROD      0           3600        3600        3600
    # Default   0           86400       31536000    300
    min_ttl                 = 0
    default_ttl             = 900
    max_ttl                 = 900
    error_caching_min_ttl   = 900
}

# https://www.terraform.io/docs/providers/aws/r/cloudfront_origin_access_identity.html
resource "aws_cloudfront_origin_access_identity" "apex" {
    comment             = "Domain apex OAI for: ${var.domain_name}"
}

# https://www.terraform.io/docs/providers/aws/r/cloudfront_distribution.html
resource "aws_cloudfront_distribution" "apex" {
    enabled             = true
    comment             = "Domain apex distribution for: ${var.domain_name}"
    default_root_object = "index.html"
    price_class         = "PriceClass_100"
    http_version        = "http2"
    is_ipv6_enabled     = true

    aliases             = [var.domain_name]

    viewer_certificate {
        acm_certificate_arn      = var.cert_ssl_arn
        ssl_support_method       = "sni-only"
        minimum_protocol_version = "TLSv1.1_2016"
    }

    origin {
        domain_name = var.bucket_apex_url
        origin_id   = local.origin_access_id

        s3_origin_config {
            origin_access_identity = "origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.apex.id}"
        }
    }

    default_cache_behavior {
        target_origin_id = local.origin_access_id
        allowed_methods  = local.methods
        cached_methods   = local.methods
        compress         = true
        # Maybe 'allow-all' better see https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_CacheBehavior.html
        viewer_protocol_policy = "redirect-to-https"
        min_ttl          = local.min_ttl
        default_ttl      = local.default_ttl
        max_ttl          = local.max_ttl

        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
        }
    }

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

    custom_error_response {
      error_code            = "400"
      response_code         = "200"
      error_caching_min_ttl = local.error_caching_min_ttl
      response_page_path    = "/index.html"
    }
    custom_error_response {
      error_code            = "403"
      response_code         = "200"
      error_caching_min_ttl = local.error_caching_min_ttl
      response_page_path    = "/index.html"
    }
    custom_error_response {
      error_code            = "404"
      response_code         = "200"
      error_caching_min_ttl = local.error_caching_min_ttl
      response_page_path    = "/index.html"
    }

    logging_config {
        bucket          = var.bucket_log_url
        include_cookies = false
        prefix          = "access"
    }

    tags = {
        Site = var.domain_name
        Type = "website"
    }

}

# https://www.terraform.io/docs/providers/aws/r/route53_record.html
resource "aws_route53_record" "dns_record_cloudfront_v4" {
    zone_id = var.dns_zone_id
    name    = var.domain_name
    type    = "A"

    alias {
        name                   = aws_cloudfront_distribution.apex.domain_name
        zone_id                = "Z2FDTNDATAQYW2"
        evaluate_target_health = false
    }
}
resource "aws_route53_record" "dns_record_cloudfront_v6" {
    zone_id = var.dns_zone_id
    name    = var.domain_name
    type    = "AAAA"

    alias {
        name                   = aws_cloudfront_distribution.apex.domain_name
        zone_id                = "Z2FDTNDATAQYW2"
        evaluate_target_health = false
    }
}
