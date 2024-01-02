resource "aws_codebuild_project" "website-codebuild" {
  name         = var.codebuild_project_name
  service_role = aws_iam_role.website_iam.arn
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type         = "LINUX_CONTAINER"
  }
  source {
    type            = "GITHUB"
    location        = "https://github.com/nethmi-1997/msc-cc-group8-terraform.git"
    git_clone_depth = 1
    buildspec       = <<-EOF
      version: 0.2
      phases:
        build:
          commands:
            - sudo yum update -y
            - sudo yum install -y unzip
            - curl -O https://releases.hashicorp.com/terraform/0.15.4/terraform_0.15.4_linux_amd64.zip
            - unzip terraform_0.15.4_linux_amd64.zip
            - ls
            - sudo mv terraform /usr/local/bin/
            - terraform version
            - terraform init
            - terraform apply --auto-approve
    EOF
  }
  artifacts {
    type = "NO_ARTIFACTS"
  }
  source_version = "main"
}

resource "aws_codepipeline" "website-pipeline" {
  name = "terraform-pipeline-cc"

  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.website_bucket.id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name     = "SourceAction"
      category = "Source"
      owner    = "ThirdParty"
      provider = "GitHub"
      version  = "2"
      configuration = {
        Owner          = "nethmi-1997"
        Repo           = "msc-cc-group8"
        OAuthToken     = var.github_oauth_token
        Branch         = "main"
      }

      output_artifacts = ["source_artifact"]
    }
  }

  stage {
    name = "Build"

    action {
      name            = "BuildAction"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_artifact"]
      output_artifacts = ["build_output"]
      configuration = {
        ProjectName = aws_codebuild_project.website-codebuild.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "S3_Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      version         = "1"
      input_artifacts = ["build_output"]
      configuration   = {
        BucketName = aws_s3_bucket.website_bucket.bucket
        Extract    = "true"
      }
    }
  }

}
resource "aws_cloudfront_distribution" "website_distribution" {
  enabled = true

  origin {
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.website_bucket.id}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.website_bucket.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${aws_s3_bucket.website_bucket.bucket}"
}