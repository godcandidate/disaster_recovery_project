# S3 Module for Disaster Recovery
# Primary bucket with versioning and lifecycle policies

# Primary S3 bucket
resource "aws_s3_bucket" "primary" {
  count  = var.environment == "primary" ? 1 : 0
  bucket = "dr-${var.environment}-${var.bucket_name}-${var.region}"
  
  tags = merge(
    {
      Name        = "dr-${var.environment}-${var.bucket_name}"
      Environment = var.environment
      Region      = var.region
    },
    var.tags
  )
}

# Enable versioning on primary bucket
resource "aws_s3_bucket_versioning" "primary" {
  count  = var.environment == "primary" ? 1 : 0
  bucket = aws_s3_bucket.primary[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle policy for primary bucket
resource "aws_s3_bucket_lifecycle_configuration" "primary" {
  count  = var.environment == "primary" ? 1 : 0
  bucket = aws_s3_bucket.primary[0].id

  rule {
    id     = "transition-to-standard-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
  }

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# DR S3 bucket (in DR region)
resource "aws_s3_bucket" "dr" {
  count    = var.environment == "primary" ? 1 : 0
  provider = aws.dr
  bucket   = "dr-${var.environment}-${var.bucket_name}-${var.dr_region}"
  
  tags = merge(
    {
      Name        = "dr-${var.environment}-${var.bucket_name}"
      Environment = var.environment
      Region      = var.dr_region
      Type        = "DR"
    },
    var.tags
  )
}

# Enable versioning on DR bucket
resource "aws_s3_bucket_versioning" "dr" {
  count    = var.environment == "primary" ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.dr[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle policy for DR bucket
resource "aws_s3_bucket_lifecycle_configuration" "dr" {
  count    = var.environment == "primary" ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.dr[0].id

  rule {
    id     = "transition-to-standard-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
  }

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Replication configuration for primary bucket to DR bucket
resource "aws_s3_bucket_replication_configuration" "primary" {
  count    = var.environment == "primary" ? 1 : 0
  provider = aws
  depends_on = [aws_s3_bucket_versioning.primary, aws_s3_bucket_versioning.dr]

  role   = var.replication_role_arn
  bucket = aws_s3_bucket.primary[0].id

  rule {
    id     = "entire-bucket-replication"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.dr[0].arn
      storage_class = "STANDARD"
    }
  }
}

# Public access block for primary bucket - allowing public access for image gallery
resource "aws_s3_bucket_public_access_block" "primary" {
  count  = var.environment == "primary" ? 1 : 0
  bucket = aws_s3_bucket.primary[0].id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Public access block for DR bucket - allowing public access for image gallery
resource "aws_s3_bucket_public_access_block" "dr" {
  count    = var.environment == "primary" ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.dr[0].id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy for public read access to primary bucket
resource "aws_s3_bucket_policy" "primary_public_read" {
  count  = var.environment == "primary" ? 1 : 0
  bucket = aws_s3_bucket.primary[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = ["${aws_s3_bucket.primary[0].arn}/*"]
      }
    ]
  })
  
  # Ensure the public access block settings are applied before the policy
  depends_on = [aws_s3_bucket_public_access_block.primary]
}

# Bucket policy for public read access to DR bucket
resource "aws_s3_bucket_policy" "dr_public_read" {
  count    = var.environment == "primary" ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.dr[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = ["${aws_s3_bucket.dr[0].arn}/*"]
      }
    ]
  })
  
  # Ensure the public access block settings are applied before the policy
  depends_on = [aws_s3_bucket_public_access_block.dr]
}

# CORS configuration for image gallery application
resource "aws_s3_bucket_cors_configuration" "primary" {
  count  = var.environment == "primary" ? 1 : 0
  bucket = aws_s3_bucket.primary[0].id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# CORS configuration for DR bucket
resource "aws_s3_bucket_cors_configuration" "dr" {
  count    = var.environment == "primary" ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.dr[0].id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
