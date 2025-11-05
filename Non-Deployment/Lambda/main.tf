# Variable for reusing existing S3 bucket
variable "my_bucket_name" {
  description = "demo-csv-separate-bucket-name"
  type        = string
  default     = "demo-csv-separate-bucket-name"
}

locals {
  lambda_function_names = [
    "naming-convention",
    "Single_Custom_ConfigRule"
  ]
}

data "aws_lambda_function" "all_lambdas" {
  for_each      = toset(local.lambda_function_names)
  function_name = each.value
}

resource "local_file" "lambda_detail_file" {
  content  = jsonencode([
    for lambda_key, lambda in data.aws_lambda_function.all_lambdas :
    {
      function_name = lambda.function_name
      runtime       = lambda.runtime
      handler       = lambda.handler
      timeout       = lambda.timeout
      memory_size   = lambda.memory_size
      role          = lambda.role
      description   = lambda.description
      last_modified = lambda.last_modified
      version       = lambda.version
      environment   = lambda.environment
      vpc_config    = lambda.vpc_config
      layers        = lambda.layers
    }
  ])
  filename = "${path.module}/Lambda/lambda_details.json"
}

# Upload Lambda details JSON file to existing S3 bucket
resource "aws_s3_object" "lambda_detail_object" {
  bucket = var.my_bucket_name
  key    = "Compliance_Report/Lambda/lambda_details.json"
  source = local_file.lambda_detail_file.filename
}
locals {
  lambda_compliance_csv = join("\n", concat(
    ["Function_Name,Runtime,Compliance_Status,Reason"],
    [
      for lambda_key, lambda in data.aws_lambda_function.all_lambdas :
      format(
        "%s,%s,%s,%s",
        lambda.function_name,
        lambda.runtime,
        (lambda.runtime == "python3.13" ? "Compliant" : "Non-Compliant"),
        (lambda.runtime == "python3.13" ? "Runtime matches python3.13" : "Runtime does not match python3.13")
      )
    ]
  ))
}

resource "local_file" "lambda_compliance_csv" {
  content  = local.lambda_compliance_csv
  filename = "${path.module}/Lambda/lambda_compliance_report.csv"
}

resource "aws_s3_object" "lambda_compliance_object" {
  bucket = var.my_bucket_name
  key    = "Compliance_Report/Lambda/lambda_compliance_report.csv"
  source = local_file.lambda_compliance_csv.filename
  # no etag to avoid inconsistent plan issues
}
