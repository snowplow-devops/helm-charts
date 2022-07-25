# Github Repository - Self Hosted Runners

A helm chart for managing self hosted github runners within a repository following [Actions Runner Controller](https://github.com/actions-runner-controller/actions-runner-controller).


Further reading on this system:
[Actions Runner Controller - Github Pages](https://actions-runner-controller.github.io/actions-runner-controller/)

## Installing the Chart

Add the repository to Helm:

```bash
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
```

Install or upgrading the chart with default configuration:

```bash
helm upgrade --install github-actions-runners --namespace github-runners --create-namespace --set runnerDeployment.githubRepo="example/repo" --set runnerDeployment.runnerNamespace="github-runners" snowplow-devops/github-actions-runners
```

Note : Certificate Manager and Action Replica Controller must be installed as a pre-requisite
The default install will use the standard `summerwind/actions-runner` image - should a private image be required this can be enabled via updating the values.yaml

## Uninstalling the Chart

To uninstall/delete the `github-actions-runners` release:

```bash
helm delete github-actions-runners --namespace github-runners
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| runnerDeployment.deploymentType | string | `repository` | Declare Where the the runner will be accessable  |
| runnerDeployment.runnerNamespace | string | `"github-runners"` | Name of the Kubernetes Namespace to deploy within |
| runnerDeployment.image.runnerImage | string | `"summerwind/actions-runner`"` | Image to use for deploying runners |
| runnerDeployment.image.tag | string | `"latest"` | Image version to use for deploying runners |
| runnerDeployment.minimumReplicaCount| string | `"1"` | Minimum ammount of Runners to deploy |
| runnerDeployment.maximumReplicaCount | string | `"1"` | Maximum ammount of Runners to deploy |
| runnerDeployment.repositoryName | string | `"example/repoName"` | *Optional* : Name of the github repository in which to deploy the runners - One deployment type must be declared|
| runnerDeployment.organizationName | string | `"myOrg"` | *Optional* : Name of the github Orgainzation in which to deploy the runners - One deployment type must be declared |
| runnerDeployment.enterpriseName | string | `"myEnterprise"` |*Optional* :  Name of the github Enterprise in which to deploy the runners - One deployment type must be declared|
| runnerDeployment.isRepositoryPublic | bollean | `true` | *Optional* :  If using a private image set to false |
| secrets.docker.username | string | `"Username"` | *Optional* : Authentication when downloading private docker images |
| secrets.docker.password | string | `"aabbccddeeff"` | *Optional* : Authentication when downloading private docker images  |
| secrets.docker.email | string | `example@testing.com` | *Optional* : Authentication when downloading private docker images |



