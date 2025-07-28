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

output "lambda_functions_config_json" {
  value = jsonencode([
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
}
