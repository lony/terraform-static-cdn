module "bucket" {
    source      = "./modules/bucket"
    domain_name = var.domain_name

    providers = {
        aws = aws.ireland
    }
}

module "certificate" {
    source      = "./modules/certificate"
    domain_name = var.domain_name
    dns_zone_id = module.bucket.dns_zone_id

    providers = {
        aws = aws.north-virginia
    }
}

module "cloudfront" {
    source          = "./modules/cloudfront"
    domain_name     = var.domain_name
    bucket_apex_url = module.bucket.bucket_apex_url
    bucket_log_url  = module.bucket.bucket_log_url
    cert_ssl_arn    = module.certificate.cert_ssl_arn
    dns_zone_id     = module.bucket.dns_zone_id

    providers = {
        aws = aws.ireland
    }
}
