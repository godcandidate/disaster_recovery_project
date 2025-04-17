# S3 Module for Disaster Recovery
# Primary bucket with versioning and lifecycle policies

# Primary S3 bucket
resource "aws_s3_bucket" "primary" {
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
  bucket = aws_s3_bucket.primary.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle policy for primary bucket
resource "aws_s3_bucket_lifecycle_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id

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
  provider = aws.dr
  bucket   = aws_s3_bucket.dr.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle policy for DR bucket
resource "aws_s3_bucket_lifecycle_configuration" "dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr.id

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

# Using IAM role from IAM module for S3 replication

# Configure replication on primary bucket
resource "aws_s3_bucket_replication_configuration" "primary" {
  # Must have bucket versioning enabled on both source and destination buckets
  depends_on = [aws_s3_bucket_versioning.primary, aws_s3_bucket_versioning.dr]

  role   = var.replication_role_arn
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "entire-bucket-replication"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.dr.arn
      storage_class = "STANDARD"
    }
  }
}

# Public access block for primary bucket
resource "aws_s3_bucket_public_access_block" "primary" {
  bucket = aws_s3_bucket.primary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Public access block for DR bucket
resource "aws_s3_bucket_public_access_block" "dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create a folder structure for media files
resource "aws_s3_object" "media_folder" {
  bucket  = aws_s3_bucket.primary.id
  key     = "media/"
  content = ""
}

resource "aws_s3_object" "production_folder" {
  bucket  = aws_s3_bucket.primary.id
  key     = "production/"
  content = ""
}

resource "aws_s3_object" "production_media_folder" {
  bucket  = aws_s3_bucket.primary.id
  key     = "production/media/"
  content = ""
}
