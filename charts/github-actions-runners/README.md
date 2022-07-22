# github-actions-runners

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

A helm chart for managing self hosted github runners utilising [Actions Runner Controller](https://github.com/actions-runner-controller/actions-runner-controller).


Further reading on this system:
[Actions Runner Controller - Github Pages](https://actions-runner-controller.github.io/actions-runner-controller/)

## Prerequisite
Certificate Manager and Action Replica Controller must be installed as a pre-requisite to this chart.

| Repository | Name | Version |
|------------|------|---------|
| https://charts.jetstack.io | cert-manager | v1.8.2 |
| https://actions-runner-controller.github.io/actions-runner-controller| actions-runner-controller | 0.20.2 |


## Installing the Chart

Add the repository to Helm:

```bash
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
```

Install or upgrading the chart with default configuration:

```bash
helm upgrade --install github-actions-runners --namespace github-runners --create-namespace --set runnerDeployment.githubRepo="example/repo" --set runnerDeployment.runnerNamespace="github-runners" snowplow-devops/github-actions-runners
```

The default install will use the standard `summerwind/actions-runner` image - should a private image be required this can be enabled via updating the values.yaml

## Uninstalling the Chart

To uninstall/delete the `github-actions-runners` release:

```bash
helm delete github-actions-runners --namespace github-runners
```

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://snowplow-devops.github.io/helm-charts | dockerconfigjson | 0.1.0 |

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| dockerconfigjson | object | `{"email":"","name":"snowplow-github-runner-deployment-dockerhub","password":"","server":"https://index.docker.io/v1/","username":""}` | For use with private hosted images on Dockerhub |
| dockerconfigjson.email | string | `""` | Email address for user of the private repository |
| dockerconfigjson.name | string | `"snowplow-github-runner-deployment-dockerhub"` | Name of the secret to use for the private repository |
| dockerconfigjson.password | string | `""` | Password for the private repository |
| dockerconfigjson.server | string | `"https://index.docker.io/v1/"` | Repository server URL |
| dockerconfigjson.username | string | `""` | Username for the private repository |
| runnerDeployment.deploymentType | string | `"repository"` | Select Deploment type - repository / orgainization / enterprise |
| runnerDeployment.enabled | bool | `true` |  |
| runnerDeployment.enterpriseName | string | `""` | For use with enterprise deployment type |
| runnerDeployment.image | object | `{"pullPolicy":"IfNotPresent","runnerImage":"summerwind/actions-runner","tag":"latest"}` | Define the image for the runners to be deployed with. |
| runnerDeployment.isRepositoryPrivate | bool | `true` | Declare if the Runner Image is in a private repo |
| runnerDeployment.maximumReplicaCount | string | `"1"` |  |
| runnerDeployment.minimumReplicaCount | string | `"1"` | Declare the minimum and maximum avalible runners 
| runnerDeployment.organizationName | string | `""` | For use with orgainization deployment type |
| runnerDeployment.repositoryName | string | `"example/repo"` | For use with repository deployment type - Add repo for runner deployment |
| runnerDeployment.runnerDeploymentName | string | `"githubRunnerDeployment"` | Declare the name of the runner deployment |
