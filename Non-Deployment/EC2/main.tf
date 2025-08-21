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

# Output instance details
output "ec2_instance_details_json" {
  value = jsonencode({
    for id, instance in data.aws_instance.details :
    id => {
      availability_zone = instance.availability_zone
      tags              = instance.tags
    }
  })
}

resource "null_resource" "apply" {
  provisioner "local-exec" {
    command = "terraform apply -auto-approve" 
  }
  depends_on = [null_resource.ec2_instance_details_json]
}

resource "null_resource" "json_upload" {
  provisioner "local-exec" {
    command = "terraform output -raw ec2_instance_details_json > ec2_data.json" 
  }
  depends_on = [null_resource.apply]
}

resource "aws_s3_object" "my_script_zip" {
  bucket = aws_s3_bucket.my_bucket.bucket
  key    = "ec2_data.json" 
  source = "${path.module}/EC2/ec2_data.json"
  acl    = "private"

  depends_on = [null_resource.json_upload]
}
