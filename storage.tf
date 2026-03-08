resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "pipeline-artifacts-simeng-zou" # Ensure this is unique
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "artifacts_versioning" {
  bucket = aws_s3_bucket.pipeline_artifacts.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket" "app_assets" {
  bucket = "application-assets-simeng-zou"
  force_destroy = true
}

resource "aws_dynamodb_table" "transactions" {
  name         = "transactions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "transaction_id"

  attribute {
    name = "transaction_id"
    type = "S"
  }
}