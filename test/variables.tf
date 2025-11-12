variable "environment" {
  description = "Environment name for testing"
  type        = string
  default     = "test"
}

variable "project_name" {
  description = "Project name for testing"
  type        = string
  default     = "terraform-toolkit-test"
}

variable "tags" {
  description = "Common tags for testing"
  type        = map(string)
  default = {
    Environment = "test"
    ManagedBy   = "terraform-toolkit"
    Purpose     = "testing"
  }
}
