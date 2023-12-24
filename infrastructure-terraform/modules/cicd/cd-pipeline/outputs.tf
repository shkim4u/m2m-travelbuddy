output "application_configuration_repo_url" {
  value = aws_codecommit_repository.configuration_source.clone_url_http
}
