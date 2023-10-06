#---------------------------------------------------------#
#                      S3 bucket creation                 #
#---------------------------------------------------------#
resource "aws_s3_bucket" "s3" {
  bucket = "www.${var.domain_name}"
  force_destroy = true
  object_lock_enabled = false
}

resource "aws_s3_bucket_public_access_block" "s3_public" {
  bucket = aws_s3_bucket.s3.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_versioning" "versioning_s3" {
  bucket = aws_s3_bucket.s3.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.s3.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "null_resource" "timer_1" {
  depends_on = [ aws_s3_bucket_public_access_block.s3_public ]
  provisioner "local-exec" {
    command = "sleep ${var.timer}"
  }
}

resource "aws_s3_bucket_policy" "allow_access" {
  depends_on = [ null_resource.timer_1 ]
  bucket = aws_s3_bucket.s3.id
  policy = data.aws_iam_policy_document.website_policy.json
}

data "aws_iam_policy_document" "website_policy" {
  statement {
    actions = [
      "s3:GetObject"
    ]
    principals {
      identifiers = ["*"]
      type = "AWS"
    }
    resources = [
      "arn:aws:s3:::www.${var.domain_name}/*"
    ]
  }
}

#--------------> static web site config <-----------------#

resource "aws_s3_bucket_website_configuration" "s3_config" {
  bucket = aws_s3_bucket.s3.id
  depends_on = [ aws_s3_bucket_policy.allow_access ]

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "object" {
  depends_on = [ aws_s3_bucket_policy.allow_access ]
  bucket = "www.${var.domain_name}"
  for_each = fileset("web-app/", "*")
  key    = each.value
  source = "web-app/${each.value}"
  etag = filemd5("web-app/${each.value}")

  content_type = "text/html"
}
output "s3-url" {
    value = aws_s3_bucket.s3.bucket_regional_domain_name
}

resource "aws_s3_bucket_ownership_controls" "ownership_control" {
  bucket = aws_s3_bucket.s3.id
  #depends_on = [ aws_s3_bucket_public_access_block.s3_private ]

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

#---------------------------------------------------------#
#                      SSl cert (ACM)                     #
#---------------------------------------------------------#

resource "aws_acm_certificate" "cert" {
  domain_name       = "*.${var.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "khlyuzder_com" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "r53_record" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.khlyuzder_com.zone_id
}

resource "aws_acm_certificate_validation" "example" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.r53_record : record.fqdn]
}

#---------------------------------------------------------#
#                      Cloud Front for S3                 #
#---------------------------------------------------------#

resource "aws_cloudfront_distribution" "s3_distribution" {
  depends_on = [ aws_s3_object.object ]
  origin {
    domain_name              = aws_s3_bucket.s3.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.s3.bucket_regional_domain_name
  
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = [ "TLSv1", "TLSv1.1", "TLSv1.2" ]
  }
}
  enabled             = true
  is_ipv6_enabled     = false
  default_root_object = "index.html"

  aliases = [ "www.${var.domain_name}" ]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.s3.bucket_regional_domain_name

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.example.certificate_arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
    
  tags = {
    Environment = "production"
  }
}
#---------------------------------------------------------#
#                  Route 53 for CloudFront                #
#---------------------------------------------------------#

resource "aws_route53_record" "cf_www_hk_com" {
  depends_on = [ aws_cloudfront_distribution.s3_distribution ]
  name = "www.${var.domain_name}"
  type = "A"
  zone_id = data.aws_route53_zone.khlyuzder_com.id

  alias {
    name = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

output "website_url" {
  value = "www.${var.domain_name}"
}