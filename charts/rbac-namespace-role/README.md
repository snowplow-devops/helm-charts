# rbac-namespace-role

A helm chart to setup a role which can access a single namespace.

## TL;DR

```bash
kubectl create namespace isolated
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
helm install rbac-namespace-role snowplow-devops/rbac-namespace-role --namespace isolated
```

## Introduction

This chart is designed to leverage the inherent isolation layer between `namespace` structures to create a role that can only interact with a single specific space.  This allows you to, somewhat, safely multi-tenant a Kubernetes cluster.

*Note*: By default the role created has full permissions on all apis, resources and verbs (it is assumed to be an admin role for this namespace).

### Tutorial: Binding a `Role` in an EKS Cluster

*Pre-requisite*: For this step you will need to ensure you have `eksctl` [installed](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html).

To bind the created role you will need to already have a cluster that you can access from your CLI - you can validate this by running:

```bash
eksctl get iamidentitymapping --cluster "<cluster_name>" --region "<region>"

# Should return something like ...
ARN								USERNAME				GROUPS					ACCOUNT
arn:aws:iam::000000000000:role/some-role-name	system:node:{{EC2PrivateDNSName}}	system:bootstrappers,system:nodes
```

Parameters:

* `group`: If you deployed the default values the `group` parameter is `isolated-group`
* `username`: This can be anything you like!
* `arn`: This can be either a `user` or `role` ARN

```bash
eksctl create iamidentitymapping --cluster "<cluster_name>" --region "<region>" \
    --arn "<user | role ARN>" --username "<username>" --group "isolated-group" \
    --no-duplicate-arns

# IAM Identity Mapping now includes something like ...
arn:aws:iam::000000000000:role/some-other-role-name	admin					isolated-group
```

Connecting to the EKS Cluster with the defined role assumed or with a user should now allow access to the specified namespace.

The [long-form guide](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html) contains a lot of extra details if the commands here do not work.

## Installing the Chart

Install or upgrading the chart with default configuration:

```bash
helm upgrade --install rbac-namespace-role snowplow-devops/rbac-namespace-role  --namespace isolated
```

## Uninstalling the Chart

To uninstall/delete the `rbac-namespace-role` release:

```bash
helm uninstall rbac-namespace-role  --namespace isolated
kubectl delete namespace isolated
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| role.name | string | `"isolated-admin-role"` | The name to assign to the role |
| role.apiGroups | list | `["*"]` | APIGroups is the name of the APIGroup that contains the resources |
| role.resources | list | `["*"]` | Resources is a list of resources this rule applies to |
| role.verbs | list | `["*"]` | Verbs is a list of Verbs that apply to ALL the ResourceKinds contained in this rule |
| roleBinding.name | string | `"isolated-admin-rolebinding"` | The name to assign to the role-binding |
| roleBinding.groupName | string | `"isolated-group"` | The name of the group which the role-binding is assigned to |
