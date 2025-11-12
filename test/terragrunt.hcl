# Terragrunt configuration for testing

terraform {
  source = "."
}

# Generate backend configuration
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
EOF
}

# Input variables
inputs = {
  environment  = "test"
  project_name = "terraform-toolkit-terragrunt-test"
  tags = {
    Environment = "test"
    ManagedBy   = "terragrunt"
    Purpose     = "testing-terragrunt"
  }
}
