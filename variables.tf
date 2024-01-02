variable "repo_name" {
  type    = string
  default = "msc-cc-group8"
}

variable "codebuild_project_name" {
  type    = string
  default = "demo-codebuild"
}

variable "github_oauth_token" {
  description = "OAuth token for GitHub access"
  type        = string
}
