terraform {
  required_version = ">= 0.13.1"

  required_providers {
    shoreline = {
      source  = "shorelinesoftware/shoreline"
      version = ">= 1.11.0"
    }
  }
}

provider "shoreline" {
  retries = 2
  debug = true
}

module "cannotpullcontainer_task_errors_in_amazon_elastic_container_service" {
  source    = "./modules/cannotpullcontainer_task_errors_in_amazon_elastic_container_service"

  providers = {
    shoreline = shoreline
  }
}