variable "domain_name" {}
variable "dns_zone_id" {}

# https://www.terraform.io/docs/providers/aws/r/acm_certificate.html
resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Site = var.domain_name
    Type = "website"
  }

}

# https://www.terraform.io/docs/providers/aws/r/route53_record.html
resource "aws_route53_record" "dns_record_cert" {
  name    = aws_acm_certificate.cert.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.cert.domain_validation_options.0.resource_record_type
  zone_id = var.dns_zone_id
  records = [aws_acm_certificate.cert.domain_validation_options.0.resource_record_value]
  ttl     = 60
}

# https://www.terraform.io/docs/providers/aws/r/acm_certificate_validation.html
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.dns_record_cert.fqdn]
}

output "cert_ssl_arn" {
  value       = aws_acm_certificate.cert.arn
  description = "ARN of CloudFront certificate"
}