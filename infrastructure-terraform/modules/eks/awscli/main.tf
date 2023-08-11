resource "kubernetes_deployment" "awscli" {
  metadata {
    name = "awscli"
    namespace = "default"
    labels = {
      app = "awscli"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "awscli"
      }
    }
    template {
      metadata {
        labels = {
          app = "awscli"
        }
      }
      spec {
        container {
          image = "amazon/aws-cli"
          name  = "awscli"
          command = ["tail"]
          args = ["-f", "/dev/null"]
          resources {
            requests = {
              cpu    = "250m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
          }
          image_pull_policy = "IfNotPresent"
        }
        restart_policy = "Always"
      }
    }
  }
}
