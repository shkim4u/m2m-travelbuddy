/**
 * Certificate using private CA for various ALBs.
 */
resource "aws_acm_certificate" "this" {
  domain_name = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  certificate_authority_arn = var.certificate_authority_arn
}
