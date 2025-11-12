# Test Terraform configuration for terraform-toolkit image
# This configuration tests various Terraform features

terraform {
  required_version = ">= 1.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# Random string for testing
resource "random_string" "test" {
  length  = 16
  special = false
  upper   = true
  lower   = true
  numeric = true
}

# Local file for testing
resource "local_file" "test_output" {
  content  = <<-EOT
    Test file created by terraform-toolkit
    Environment: ${var.environment}
    Project: ${var.project_name}
    Random value: ${random_string.test.result}
    Tags: ${jsonencode(var.tags)}
  EOT
  filename = "${path.module}/output/test-${random_string.test.result}.txt"
}

# Sensitive output for testing
resource "random_password" "test_sensitive" {
  length  = 32
  special = true
}

output "random_string" {
  description = "Random string generated for testing"
  value       = random_string.test.result
}

output "file_path" {
  description = "Path to the generated test file"
  value       = local_file.test_output.filename
}

output "sensitive_value" {
  description = "Sensitive value for testing"
  value       = random_password.test_sensitive.result
  sensitive   = true
}
