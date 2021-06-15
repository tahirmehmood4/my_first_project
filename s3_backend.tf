# //////////////////////////////
# S3 BUCKET
# //////////////////////////////
resource "aws_s3_bucket" "tahir-tfremotestate" {

  //create_bucket = false   #create s3 resources conditionally
  bucket = var.bucket_name
  //force_destroy = true
  acl = "private"

  versioning {
    enabled = true
  }

//Add the following block to a Terraform S3 resource to add AES-256 encryption
  
  server_side_encryption_configuration {
  	rule {
    		apply_server_side_encryption_by_default {
      		sse_algorithm = "AES256"
    		}
  	     }
  }
  # Grant read/write access to the terraform user
  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${data.aws_iam_user.admin.arn}"
            },
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::${var.bucket_name}/*"
        }
    ]
}
EOF
}

resource "aws_s3_bucket_public_access_block" "tahir-tfremotestate" {
  bucket = aws_s3_bucket.tahir-tfremotestate.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# //////////////////////////////
# DYNAMODB TABLE
# //////////////////////////////

resource "aws_kms_key" "mykey" {

  description             = "KMS key 1"
  deletion_window_in_days = 7
  key_usage = "ENCRYPT_DECRYPT"
  is_enabled = true


}

resource "aws_dynamodb_table" "tf_db_statelock" {
  name           = "tahir-tfstatelock"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

//Notes:
//server_side_encryption
//enabled - (Required) Whether or not to enable encryption at rest using an AWS managed KMS customer master key (CMK).
//kms_key_arn - (Optional) The ARN of the CMK that should be used for the AWS KMS encryption. This attribute should only be specified if the key is different from the default DynamoDB CMK, alias/aws/dynamodb.
//If enabled is false then server-side encryption is set to AWS owned CMK (shown as DEFAULT in the AWS console). If enabled is true and no kms_key_arn is specified then server-side encryption is set to AWS managed CMK (shown as KMS in the AWS console). The AWS KMS documentation explains the difference between AWS owned and AWS managed CMKs.

  server_side_encryption {
    enabled = true
    //kms_master_key_id = aws_kms_key.mykey.arn
    kms_key_arn = aws_kms_key.mykey.arn
  //  kms_key_arn is specified then server-side encryption is set to AWS managed CMK (shown as KMS in the AWS console).
    //sse_algorithm     = "aws:kms"  
  // sse_algorithm - (required) The server-side encryption algorithm to use. Valid values are AES256 and aws:kms
  }

}

# //////////////////////////////
# IAM POLICY
# //////////////////////////////
resource "aws_iam_user_policy" "terraform_user_dbtable" {
  name = "terraform"
  user = data.aws_iam_user.admin.user_name
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["dynamodb:*"],
            "Resource": [
                "${aws_dynamodb_table.tf_db_statelock.arn}"
            ]
        }
   ]
}

EOF
}
