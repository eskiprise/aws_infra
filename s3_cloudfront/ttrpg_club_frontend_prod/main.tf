# Prod counterpart to ../ttrpg_club_frontend — same shape, separate bucket/distribution.
# Not to be confused with ../ttrpg_club_frontend_dev, which is an unrelated sandbox for
# ttrpg_poll_bot's Mini App testing, not a real environment for this website.

resource "aws_s3_bucket" "frontend" {
  bucket = "ttrpg-club-frontend-prod"

  tags = {
    Terraform = "true"
    Project   = "ttrpg-club"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "ttrpg-club-frontend-prod"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 301-redirects www.dnaclub.com.ua to the apex domain — Route 53 points both hostnames
# at this same distribution (see aws_infra/dns/dnaclub_com_ua), so the split happens
# here rather than via a second distribution. Drops the query string for simplicity;
# acceptable for a plain www -> apex redirect on a club site.
resource "aws_cloudfront_function" "www_redirect" {
  name    = "ttrpg-club-www-redirect-prod"
  runtime = "cloudfront-js-1.0"
  comment = "Redirects www.dnaclub.com.ua to https://dnaclub.com.ua"
  publish = true
  code    = <<-EOT
    function handler(event) {
      var request = event.request;
      var host = request.headers.host && request.headers.host.value;
      if (host === "www.dnaclub.com.ua") {
        return {
          statusCode: 301,
          statusDescription: "Moved Permanently",
          headers: {
            location: { value: "https://dnaclub.com.ua" + request.uri }
          }
        };
      }
      return request;
    }
  EOT
}

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  comment             = "TTRPG club website — static frontend (prod)"
  aliases             = ["dnaclub.com.ua", "www.dnaclub.com.ua"]

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "s3-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.www_redirect.arn
    }

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # SPA client-side routing: any path CloudFront can't find in the bucket falls back
  # to index.html so React Router can handle it.
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = data.terraform_remote_state.dns.outputs.prod_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Terraform = "true"
    Project   = "ttrpg-club"
  }
}

data "aws_iam_policy_document" "frontend_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontOAC"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.frontend.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend_bucket_policy.json
}
