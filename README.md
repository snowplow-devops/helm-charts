[![License][license-image]][license] [![Artifact Hub][artifact-hub-image]][artifact-hub] 

# helm-charts

A collection of Helm Charts for deploying Snowplow micro-services and additional addons for public cloud based kubernetes services.

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

```
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
```

If you had already added this repo earlier, run `helm repo update` to retrieve the latest versions of the packages.  You can then run `helm search repo snowplow-devops` to see the charts.

# Copyright and license

The Snowplow Helm Charts project is Copyright 2022-2022 Snowplow Analytics Ltd.

Licensed under the [Apache License, Version 2.0][license] (the "License");
you may not use this software except in compliance with the License.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

[license]: https://www.apache.org/licenses/LICENSE-2.0
[license-image]: https://img.shields.io/badge/license-Apache--2-blue.svg?style=flat

[artifact-hub]: https://artifacthub.io/packages/search?repo=snowplow-devops
[artifact-hub-image]: https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/snowplow-devops
