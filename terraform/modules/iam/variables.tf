variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in format owner/repo for OIDC trust"
  type        = string
  default     = "AdityaNutulapati/devops-lcdt"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
