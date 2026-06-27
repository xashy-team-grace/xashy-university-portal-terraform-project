resource "aws_ssm_document" "install_tomcat" {
  name            = "${var.project}-install-tomcat"
  document_type   = "Command"
  document_format = "YAML"

  # Run Command document content is maintained separately for readability
  content = file("${path.module}/scripts/install-tomcat.yaml")

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
