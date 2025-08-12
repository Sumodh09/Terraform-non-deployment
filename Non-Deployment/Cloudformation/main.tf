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
