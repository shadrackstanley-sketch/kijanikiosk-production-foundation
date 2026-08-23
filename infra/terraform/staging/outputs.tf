output "namespace_name" {
  description = "KijaniKiosk staging namespace provisioned by Terraform"
  value       = kubernetes_namespace_v1.kijani_staging.metadata[0].name
}

output "environment" {
  description = "Environment represented by this Terraform stack"
  value       = kubernetes_namespace_v1.kijani_staging.metadata[0].labels["environment"]
}
