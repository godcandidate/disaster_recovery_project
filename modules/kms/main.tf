# KMS Module for encryption

# KMS Key for encryption
resource "aws_kms_key" "this" {
  description             = "KMS key for encryption in ${var.environment} environment"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = merge(
    {
      Name        = "dr-kms-key-${var.environment}"
      Environment = var.environment
    },
    var.tags
  )
}

# KMS Key Alias
resource "aws_kms_alias" "this" {
  name          = "alias/dr-kms-${var.environment}"
  target_key_id = aws_kms_key.this.key_id
}
