resource "aws_ssm_parameter" "travelbuddy_image_tag" {
  name = "/application/travelbuddy/container/image/main/tag"
  type = "String"
  description = "TravelBuddy application main branch image tag"
  value = "latest"
  tier = "Standard"
}
