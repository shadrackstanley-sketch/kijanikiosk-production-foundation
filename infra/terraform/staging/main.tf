provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

resource "kubernetes_namespace_v1" "kijani_staging" {
  metadata {
    name = "kijani-staging"

    labels = {
      environment = "staging"
      application = "kijanikiosk"
      managed_by  = "terraform"
    }
  }
}
