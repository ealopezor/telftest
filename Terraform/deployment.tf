provider "azurerm" {
  features {}
}

variable "source_acr_name" {
  default = "reference"
}

variable "destination_acr_name" {
  default = "instance"
}

variable "destination_acr_resource_group" {
  default = "instance-acr-rg"
}

variable "destination_subscription_id" {
  default = "c9e7611c-d508-4-f-aede-0bedfabc1560"
}

variable "helm_chart_name" {
  default = "your-helm-chart-name"
}

variable "helm_chart_version" {
  default = "1.0.0"
}

resource "azurerm_container_registry_import" "import_helm_chart" {
  name                 = var.destination_acr_name
  resource_group_name  = var.destination_acr_resource_group
  registry_name        = var.destination_acr_name
  source {
    registry_uri        = "${var.source_acr_name}.azurecr.io"
    source_image        = "helm/${var.helm_chart_name}:${var.helm_chart_version}"
    credentials {
      username = "<source-acr-username>"
      password = "<source-acr-password>"
    }
  }
  target {
    repository_name = "helm/${var.helm_chart_name}"
  }
}

output "imported_chart_info" {
  value = azurerm_container_registry_import.import_helm_chart.target
}
