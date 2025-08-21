# Get data for all EC2 instances in the region
data "aws_instances" "all" {}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "demo-csv-separate-bucket-name" 
#   lifecycle {
#    prevent_destroy = true
#  }
}

# Loop through instance IDs to get detailed info
data "aws_instance" "details" {
  for_each = toset(data.aws_instances.all.ids)
  instance_id = each.key
}

locals {
  ec2_details_json = jsonencode({
    for id, instance in data.aws_instance.details :
    id => {
      availability_zone = instance.availability_zone
      tags              = instance.tags
    }
  })
}

# Write the JSON to a local file
resource "local_file" "ec2_detail_file" {
  content  = local.ec2_details_json
  filename = "${path.module}/EC2/ec2_detail.json"
}

# Upload the JSON file to S3
resource "aws_s3_object" "ec2_detail_object" {
  bucket = aws_s3_bucket.my_bucket.bucket
  key    = "ec2_detail.json"
  source = local_file.ec2_detail_file.filename
  etag   = filemd5(local_file.ec2_detail_file.filename)
}
