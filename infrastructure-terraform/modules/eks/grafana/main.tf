resource "kubernetes_secret" "grafana" {
  metadata {
    name      = "grafana"
    namespace = "grafana"
  }

  data = {
    admin-user     = "admin"
  }
}

# Grafana dashboard examples:
# - https://grafana.com/grafana/dashboards/13770-1-kubernetes-all-in-one-cluster-monitoring-kr/
resource "helm_release" "grafana" {
  repository = "https://grafana.github.io/helm-charts"
  chart = "grafana"
  name  = "grafana"
  namespace = "grafana"
  create_namespace = true
  values = [templatefile("${path.module}/values.yaml", {
    admin_existing_secret = kubernetes_secret.grafana.metadata[0].name
    admin_user_key = "admin-user"
    admin_password_key    = "admin-password"
    certificate_arn = var.certificate_arn
  })]

  timeout = 300
}
