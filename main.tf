terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.18.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

resource "random_id" "rand_id" {
  byte_length = 8
}

resource "aws_s3_bucket" "mywebapp-bucket" {
  bucket = "mywebapp-bucket-abcdef-2025"
}


resource "aws_s3_bucket_public_access_block" "mywebapp-bucket" {
  bucket = aws_s3_bucket.mywebapp-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "mywebapp" {
  bucket = aws_s3_bucket.mywebapp-bucket.id
  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Sid       = "PublicReadGetObject",
          Effect    = "Allow",
          Principal = "*",
          Action    = "s3:GetObject",
          Resource  = "arn:aws:s3:::${aws_s3_bucket.mywebapp-bucket.bucket}/*"

        }
      ]
    }
  )
}

resource "aws_s3_bucket_website_configuration" "mywebapp" {
  bucket = aws_s3_bucket.mywebapp-bucket.id

  index_document {
    suffix = "index.html"
  }


}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.mywebapp-bucket.bucket
  source       = "./index.html"
  key          = "index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "style_css" {
  bucket       = aws_s3_bucket.mywebapp-bucket.bucket
  source       = "./style.css"
  key          = "style.css"
  content_type = "text/css"
}

resource "aws_s3_object" "app_js" {
  bucket       = aws_s3_bucket.mywebapp-bucket.bucket
  source       = "./app.js"
  key          = "app.js"
  content_type = "text/js"
}


resource "aws_s3_object" "images" {
  for_each = fileset("${path.module}/images", "*") # reads all files in images/

  bucket       = aws_s3_bucket.mywebapp-bucket.bucket
  key          = "images/${each.value}"                         # S3 object key (keeps folder structure)
  source       = "${path.module}/images/${each.value}"          # local file path
  etag         = filemd5("${path.module}/images/${each.value}") # detects changes
  content_type = "image/png"
}


output "name" {
  value = aws_s3_bucket_website_configuration.mywebapp.website_endpoint
}