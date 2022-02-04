terraform {
  required_providers {
    ibm = {
      source = "ibm-cloud/ibm"
      version = "1.26.2"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 2.3"
    }
  }
}
