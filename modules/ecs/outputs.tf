output "cluster_id" {
  description = "The ECS cluster ID."
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "The ECS cluster ARN."
  value       = aws_ecs_cluster.this.arn
}
