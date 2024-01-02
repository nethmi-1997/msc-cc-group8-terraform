resource "aws_s3_bucket" "website_bucket" {
  bucket = "msc-cc-group8-bucket-2"
  acl    = "private" # Access Control List (ACL) for the bucket
}