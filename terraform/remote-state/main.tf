provider "aws" {
  region  = var.preferred_region
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.tfstate_s3_bucket_name
     
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
    bucket = aws_s3_bucket.terraform_state.id

    versioning_configuration {
      status = "Enabled"
    }
}

# only needed for resource locking i.e. multiple developers
#resource "aws_dynamodb_table" "terraform_state_lock" {
#  name           = "app-state"
#  read_capacity  = 1
#  write_capacity = 1
#  hash_key       = "LockID"

#  attribute {
#    name = "LockID"
#    type = "S"
#  }
#}
