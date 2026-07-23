resource "aws_s3_bucket" "avatars" {
  bucket = "ttrpg-club-avatars"

  tags = {
    Terraform = "true"
    Project   = "ttrpg-club"
  }
}

resource "aws_s3_bucket_public_access_block" "avatars" {
  bucket                  = aws_s3_bucket.avatars.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Presigned PUT uploads happen directly from the browser to S3 (not through CloudFront),
# so the bucket itself needs to allow that cross-origin PUT.
resource "aws_s3_bucket_cors_configuration" "avatars" {
  bucket = aws_s3_bucket.avatars.id

  cors_rule {
    allowed_methods = ["PUT"]
    allowed_origins = [var.cors_allowed_origin]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_cloudfront_origin_access_control" "avatars" {
  name                              = "ttrpg-club-avatars"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "avatars" {
  enabled     = true
  price_class = "PriceClass_100"
  comment     = "TTRPG club — member/GM profile pictures (public read)"

  origin {
    domain_name              = aws_s3_bucket.avatars.bucket_regional_domain_name
    origin_id                = "s3-avatars"
    origin_access_control_id = aws_cloudfront_origin_access_control.avatars.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-avatars"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

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

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Terraform = "true"
    Project   = "ttrpg-club"
  }
}

data "aws_iam_policy_document" "avatars_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontOAC"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.avatars.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.avatars.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "avatars" {
  bucket = aws_s3_bucket.avatars.id
  policy = data.aws_iam_policy_document.avatars_bucket_policy.json
}
