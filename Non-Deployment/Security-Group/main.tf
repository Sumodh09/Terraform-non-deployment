data "aws_security_groups" "all" {}

output "all_security_groups" {
  value = data.aws_security_groups.all.ids
}

# To fetch detailed info of each security group, you can use a for_each with aws_security_group data source

data "aws_security_group" "details" {
  for_each = toset(data.aws_security_groups.all.ids)
  id       = each.key
}

output "security_group_details" {
  value = {
    for sg_id, sg in data.aws_security_group.details :
    sg_id => {
      name        = sg.name
      description = sg.description
      vpc_id      = sg.vpc_id
      ingress     = try(sg.ingress, [])
      egress      = try(sg.egress, [])
      tags        = sg.tags
    }
  }
}

resource "local_file" "security_group_detail_file" {
  content = jsonencode([
    for sg_id, sg in data.aws_security_group.details :
    {
      id          = sg_id
      name        = sg.name
      description = sg.description
      vpc_id      = sg.vpc_id
      ingress     = try(sg.ingress, [])
      egress      = try(sg.egress, [])
      tags        = sg.tags
    }
  ])
  filename = "${path.module}/Security-Group/sg_details.json"
}

locals {
  vpc_id_to_check = "vpc-0ba50349bcd767084"

  security_group_compliance_csv = join("\n", concat(
    ["SG_ID,Name,VPC_ID,Compliance_Status,Reason"],
    [
      for sg_id, sg in data.aws_security_group.details :
      format(
        "%s,%s,%s,%s,%s",
        sg_id,
        sg.name,
        sg.vpc_id,
        sg.vpc_id == local.vpc_id_to_check ? "Compliant" : "Non-Compliant",
        sg.vpc_id == local.vpc_id_to_check ? "VPC ID matches expected" : "VPC ID does not match"
      )
    ]
  ))
}

resource "local_file" "security_group_compliance_csv" {
  content  = local.security_group_compliance_csv
  filename = "${path.module}/Security-Group/sg_compliance_report.csv"
}

variable "my_bucket_name" {
  description = "S3 bucket for compliance reports"
  type        = string
  default     = "demo-csv-separate-bucket-name"
}

resource "aws_s3_object" "security_group_detail_object" {
  bucket = var.my_bucket_name
  key    = "Compliance_Report/Security-Group/sg_details.json"
  source = local_file.security_group_detail_file.filename
}

resource "aws_s3_object" "security_group_compliance_object" {
  bucket = var.my_bucket_name
  key    = "Compliance_Report/Security-Group/sg_compliance_report.csv"
  source = local_file.security_group_compliance_csv.filename
}
