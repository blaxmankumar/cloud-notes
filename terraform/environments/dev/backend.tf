terraform {
  backend "s3" {
    bucket       = "cloud-notes-tfstate-038832652205"
    key          = "azure-devsecops/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}