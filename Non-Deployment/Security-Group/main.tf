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
