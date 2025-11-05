locals {
  # Replace with real stack names manually
  known_stacks = [
    "serverlessrepo-rdklib"
  ]
}

data "aws_cloudformation_stack" "stack_info" {
  for_each = toset(local.known_stacks)
  name     = each.value
}

output "cloudformation_stack_json" {
  value = {
    for name, stack in data.aws_cloudformation_stack.stack_info :
    name => jsonencode({
      name         = stack.name
      description  = stack.description
      parameters   = stack.parameters
      outputs      = stack.outputs
      tags         = stack.tags
      capabilities = stack.capabilities
    })
  }
}

resource "local_file" "cloudformation_detail_file" {
  content  = jsonencode([
    for name, stack in data.aws_cloudformation_stack.stack_info :
    {
      name         = stack.name
      description  = stack.description
      parameters   = stack.parameters
      outputs      = stack.outputs
      tags         = stack.tags
      capabilities = stack.capabilities
    }
  ])
  filename = "${path.module}/CloudFormation/cloudformation_details.json"
}

locals {
  cloudformation_compliance_csv = join("\n", concat(
    ["Stack_Name,Compliance_Status,Reason"],
    [
      for name, stack in data.aws_cloudformation_stack.stack_info :
      format(
        "%s,%s,%s",
        stack.name,
        contains(stack.capabilities, "CAPABILITY_IAM") ? "Compliant" : "Non-Compliant",
        contains(stack.capabilities, "CAPABILITY_IAM") ? "Has IAM capability" : "Missing IAM capability"
      )
    ]
  ))
}

resource "local_file" "cloudformation_compliance_csv" {
  content  = local.cloudformation_compliance_csv
  filename = "${path.module}/CloudFormation/cloudformation_compliance_report.csv"
}


variable "my_bucket_name" {
  description = "S3 bucket for compliance reports"
  type        = string
  default     = "demo-csv-separate-bucket-name"
}

resource "aws_s3_object" "cloudformation_detail_object" {
  bucket = var.my_bucket_name
  key    = "Compliance_Report/CloudFormation/cloudformation_details.json"
  source = local_file.cloudformation_detail_file.filename
}

resource "aws_s3_object" "cloudformation_compliance_object" {
  bucket = var.my_bucket_name
  key    = "Compliance_Report/CloudFormation/cloudformation_compliance_report.csv"
  source = local_file.cloudformation_compliance_csv.filename
}
