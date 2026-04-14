output "log_groups" {
  description = "Map of log group name to object with arn and name attributes."
  value = {
    for name, lg in aws_cloudwatch_log_group.this : name => {
      arn  = lg.arn
      name = lg.name
    }
  }
}
