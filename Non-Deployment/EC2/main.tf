# Get data for all EC2 instances in the region
data "aws_instances" "all" {}

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
