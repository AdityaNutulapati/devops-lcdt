output "cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.arn
}

output "cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.name
}

output "node_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = aws_iam_role.eks_node.arn
}

output "node_role_name" {
  description = "Name of the EKS node group IAM role"
  value       = aws_iam_role.eks_node.name
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions CI/CD IAM role"
  value       = aws_iam_role.github_actions.arn
}
