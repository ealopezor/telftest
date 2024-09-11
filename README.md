# telftest


# Devops Engineer Code Challenge
Code challenge for Devops Engineer in Telefonica Innovacion Digital. We’d like you to
design and develop a playable demo to create and deploy a helm chart.

Challenges

## Challenge 1

Modify the Ping Helm Chart to deploy the application on the following restrictions:

• Isolate specific node groups forbidding the pods scheduling in this node groups.

    Using this Kubernetes Node Affinity we can exclude certains nodes from running the application.

    affinity:
        nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
                nodeSelectorTerms:
                    - matchExpressions:
                      - key: group
                        operator: NotIn
                        values:
                          - isolated # The label value of the nodes you want to isolate from #

• Ensure that a pod will not be scheduled on a node that already has a pod of the
same type.

    To Ensure that de pod is not scheduled on the same node that already has a pod of the same type:

    affinity:
        podAntiAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
                - labelSelector:
                    matchExpressions:
                      - key: app
                        operator: In
                        values:
                          - ping # Assuming the label for your app is 'ping'
        topologyKey: "kubernetes.io/hostname"

• Pods are deployed across different availability zones.

    To ensure pods are deployed in different availability zones 

    topologySpreadConstraints:
        - maxSkew: 1
             topologyKey: "topology.kubernetes.io/zone"
                whenUnsatisfiable: "DoNotSchedule"
            labelSelector:
                matchLabels:
                    app: ping

• Ensure a random script is run on every helm update execution.

    To run a random script during every Helm update execution, we are going to use a "post-upgrade hook" we creat a new template and use the following:

    # templates/post-upgrade-job.yaml

    apiVersion: batch/v1
    kind: Job
    metadata:
        name: "{{ include "ping.fullname" . }}-random-script"
    labels:
        app.kubernetes.io/name: {{ include "ping.name" . }}
        helm.sh/hook: post-upgrade
        helm.sh/hook-weight: "1"
    spec:
        template:
        spec:
            containers:
              - name: random-script
                image: your-script-image:latest 
                command: ["/bin/sh", "-c", "your-random-script.sh"]
      restartPolicy: OnFailure
 

To apply this changes 

    helm upgrade --install ping-release-name path/to/ping-chart --values values.yaml
      
    



## Challenge 2
We have a private registry based on Azure Container Registry where we publish all our Helm charts. Let’s call this registry reference.azurecr.io. When we create an AKS cluster, we also create another Azure Container Registry where we need to copy the Helm charts we are going to install in that AKS from the reference registry. Let’s call this registry instsance.azurerc.io and assume it resides in an Azure subscripCon with ID
c9e7611c-d508-4-f-aede-0bedfabc1560. Provide an automation for the described process using the tool you feel more
comfortable with (terraform or ansible are preferred).
You can assume the caller will be authenticated in Azure with enough permissions to
import Helm charts into the instance registry and will provide the module a configured helm provider.

    For this challenge we are going to use a Terraform Solution, 

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


## Challenge 3
Create a Github workflow to allow installing helm chart from Challenge #1 using
module from Challenge #2, into an AKS cluster (considering a preexisting resource
group and cluster name).