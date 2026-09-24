# Practice Test 2 — Solutions and revision notes

> Use only after attempting the questions. Replace `<GIT_BASE>` with your Git base URL. Builder tags can differ by CRC bundle; inspect `oc get is -n openshift` first.

## Q1 solution
### Option A — Web console / UI-assisted
1. Create project **amber** from the project selector using **Create Project**.
2. Clone the supplied Git repository locally, repair the deliberately invalid `package.json`, commit, and push it. Source editing/committing is a Git task, so keep this part in the terminal/editor.
3. In **Developer → +Add → Import from Git**, enter `<GIT_BASE>/pt2-q1-quote-api.git`. If detection is uncertain, use **Edit import strategy** and select the Node.js builder image.
4. Set the application/name to **quote-api**. In the build environment section add `npm_config_registry=https://registry.npmjs.org/`, then create the application.
5. Open **Topology → quote-api → Resources** and follow the Build/BuildConfig logs. If the first build used the old Git commit, start a new build from **Builds → BuildConfigs → quote-api → Start build**.
6. From Topology, use **Create Route** if no route exists. Open the route and verify the response.

### Option B — CLI
```bash
# Create the project required by the task.
oc new-project amber
# Clone the supplied source so you can validate and repair it.
git clone <GIT_BASE>/pt2-q1-quote-api.git && cd pt2-q1-quote-api
# Validate package.json and locate the deliberate JSON error.
python3 -m json.tool package.json
# Edit the invalid JSON, then record and publish the correction.
vi package.json
git add package.json && git commit -m 'repair package metadata' && git push
# Create an S2I application and pass the dependency registry to the build environment.
oc new-app nodejs:20-ubi9~<GIT_BASE>/pt2-q1-quote-api.git --name=quote-api --build-env=npm_config_registry=https://registry.npmjs.org/
# Expose the Service through an OpenShift Route.
oc expose service quote-api
# Follow the latest build and verify its history.
oc logs -f bc/quote-api
oc start-build quote-api --follow
oc get builds
# Verify the application response.
curl -s http://$(oc get route quote-api -o jsonpath='{.spec.host}')/
```
Revision: OpenShift 4.18 Building applications — creating applications and S2I: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/building_applications/creating-applications

## Q2 solution
### Option A — Web console / UI-assisted
1. Create project **cobalt** in the console. Clone `<GIT_BASE>/pt2-q2-container.git`, edit the supplied Containerfile as required, then commit and push the change.
2. Go to **Developer → +Add → Import from Git**, enter the repository URL, choose **Edit import strategy**, and explicitly choose **Dockerfile** rather than an S2I builder. Name the component **parent-web**.
3. If the Containerfile/path or build arguments cannot be supplied during import, create the component and then open **Builds → BuildConfigs → parent-web → YAML**. Confirm `spec.strategy.dockerStrategy` is present, set `dockerfilePath: Containerfile`, and add build arg `BANNER_URL` with the Nexus-mock URL from the question. Set the output ImageStreamTag to `parent-web:1.0`.
4. Start a build from the BuildConfig page and inspect **Logs**. The important check is that this is a Docker build, not Source/S2I.
5. Repeat the Git-import/Dockerfile workflow for the supplied child image. Its `FROM` must reference the parent ImageStream image and the child source must override the parent content through the required `ONBUILD` behavior.
6. In **+Add → Container images**, deploy the child ImageStreamTag, create a Route from Topology, and verify the page. Use **Builds → Builds** and **Topology → Resources** to diagnose failures.

### Option B — CLI
```bash
# Create the project and clone the Containerfile source.
oc new-project cobalt
git clone <GIT_BASE>/pt2-q2-container.git && cd pt2-q2-container
# Edit the Containerfile: consolidate RUN operations and add the required ONBUILD COPY.
vi Containerfile
# Commit the optimized Containerfile so OpenShift builds from Git.
git add Containerfile && git commit -m 'optimize parent image' && git push
# Create the build explicitly as Docker strategy; do not let strategy detection choose S2I.
oc new-build <GIT_BASE>/pt2-q2-container.git --name=parent-web --strategy=docker --to=parent-web:1.0
# Tell Docker strategy which file to use and pass the artifact URL build argument.
oc patch bc/parent-web --type=merge -p '{"spec":{"strategy":{"dockerStrategy":{"dockerfilePath":"Containerfile","buildArgs":[{"name":"BANNER_URL","value":"http://nexus-mock.lab-infra.svc:8080/banner.txt"}]}}}}'
# Build and inspect logs for Containerfile/artifact failures.
oc start-build parent-web --follow
oc get is parent-web
# Inspect the resulting BuildConfig strategy before continuing.
oc get bc parent-web -o jsonpath='{.spec.strategy.type}{"\\n"}'
```
For the child image, use the supplied child Containerfile/repository, set `FROM image-registry.openshift-image-registry.svc:5000/cobalt/parent-web:1.0`, create a Docker-strategy build to `child-web:latest`, deploy it, expose the Service and curl the Route.
Revision: OpenShift 4.18 Builds using BuildConfig — build strategies: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/builds_using_buildconfig/build-strategies

## Q3 solution
### Option A — Web console / UI-assisted
1. Create project **sienna**. Clone the Git repository locally, edit `.s2i/bin/assemble`, commit and push it; the console does not replace source-code editing.
2. Use **Developer → +Add → Import from Git**, enter the repository, and select the HTTPD builder through **Edit import strategy** if auto-detection is wrong. Name it **stellar**.
3. Open **Builds → BuildConfigs → stellar**. In its environment/configuration area (or YAML editor), persist `SITE_OWNER=crc-student`. Confirm the strategy is Source/S2I and that the Git source is correct.
4. Select **Start build**, then inspect the build logs to confirm the customized assemble script runs.
5. In Topology create/open the Route and verify `/` and `/build-info.html`.
6. Use the BuildConfig and Build pages to compare the persistent build definition with individual build executions.

### Option B — CLI
```bash
# Create the project and inspect available HTTPD builders first.
oc new-project sienna
oc get is -n openshift | grep httpd
# Clone and edit the custom S2I assemble script.
git clone <GIT_BASE>/pt2-q3-stellar.git && cd pt2-q3-stellar
vi .s2i/bin/assemble
# Publish your S2I customization to Git.
git add .s2i/bin/assemble && git commit -m 'customize assemble' && git push
# Create the source-strategy application using an HTTPD builder.
oc new-app httpd:2.4-ubi9~<GIT_BASE>/pt2-q3-stellar.git --name=stellar
# Persist the required build environment variable in the BuildConfig.
oc set env bc/stellar SITE_OWNER=crc-student
# Start/follow another build and inspect the BuildConfig versus individual Builds.
oc start-build stellar --follow
oc get bc stellar -o yaml
oc get builds
# Expose and verify both pages.
oc expose svc stellar
HOST=$(oc get route stellar -o jsonpath='{.spec.host}')
curl -s http://$HOST/
curl -s http://$HOST/build-info.html
```
Revision: OpenShift 4.18 — overriding S2I builder scripts: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/images/using-images

## Q4 solution
### Option A — Web console
1. Create project **violet**, then use **+Add → Import from Git** to deploy the supplied Node.js repository as **config-api**.
2. Open **Workloads → ConfigMaps → Create ConfigMap** and create `app-settings` with `GREETING` and `LOG_LEVEL`.
3. Open **Workloads → Secrets → Create → Key/value secret** and create `backend-credentials` with `API_USER` and `API_KEY`.
4. Open the `config-api` Deployment and use its environment/configuration controls, or **Edit Deployment**, to populate environment variables from the ConfigMap and Secret. The YAML form can use `envFrom` references if that is quicker.
5. Create/open the Route from Topology and verify the response.
6. Change only `GREETING` in **ConfigMaps → app-settings**, then restart the Deployment from **Actions → Restart rollout** because environment-variable values are read when new pods are created. Verify the new response.

### Option B — CLI
```bash
# Create the project and deploy the Git application.
oc new-project violet
oc new-app nodejs:20-ubi9~<GIT_BASE>/pt2-q4-config-api.git --name=config-api
# Create non-sensitive application configuration.
oc create configmap app-settings --from-literal=GREETING='Configuration is external' --from-literal=LOG_LEVEL=info
# Create sensitive values as a Secret rather than literals in the Deployment.
oc create secret generic backend-credentials --from-literal=API_USER=serviceuser --from-literal=API_KEY=pt2-secret-key
# Import all keys from both resources into the Deployment environment.
oc set env deployment/config-api --from=configmap/app-settings
oc set env deployment/config-api --from=secret/backend-credentials
# Expose and verify the response.
oc expose svc config-api
curl -s http://$(oc get route config-api -o jsonpath='{.spec.host}')/
# Update only the ConfigMap and restart pods because env-var injection is read at pod creation.
oc set data configmap/app-settings GREETING='Configuration updated'
oc rollout restart deployment/config-api
oc rollout status deployment/config-api
```
Revision: OpenShift 4.18 ConfigMaps/Secrets: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/building_applications/config-maps

## Q5 solution
### Option A — Web console
1. Create project **probe-lab** and import the supplied Git application as **probe-api**.
2. Open **Developer → Topology → probe-api → Actions → Add Health Checks** (or edit the Deployment health checks).
3. Add the **startup probe** using HTTP GET `/startup` on port `8080`; translate the question's timing requirement into the appropriate period, timeout and failure-threshold fields.
4. Add the **liveness probe** using HTTP GET `/healthz` on port `8080`; configure its delayed start, period, timeout and failure threshold from the wording in the question.
5. Add the **readiness probe** using HTTP GET `/ready` on port `8080`; configure its timing/failure behavior from the requirement rather than copying defaults.
6. Save, then inspect **Pods → Events** and the Deployment details. Confirm the pod becomes Ready and the Service has endpoints.

### Option B — CLI
```bash
# Create/deploy the health application.
oc new-project probe-lab
oc new-app nodejs:20-ubi9~<GIT_BASE>/pt2-q5-probe-api.git --name=probe-api
# Add startup probe: 5-second period and 8 failures gives about 40 seconds.
oc set probe deployment/probe-api --startup --get-url=http://:8080/startup --period-seconds=5 --failure-threshold=8 --timeout-seconds=2
# Add liveness with delayed start, 10-second period and short timeout.
oc set probe deployment/probe-api --liveness --get-url=http://:8080/healthz --initial-delay-seconds=15 --period-seconds=10 --timeout-seconds=2 --failure-threshold=3
# Add readiness earlier and remove from endpoints after two failures.
oc set probe deployment/probe-api --readiness --get-url=http://:8080/ready --initial-delay-seconds=5 --period-seconds=5 --timeout-seconds=2 --failure-threshold=2
# Verify the persisted pod-template configuration and live probe events.
oc get deploy probe-api -o yaml
oc describe pod -l deployment=probe-api
oc get endpoints probe-api
```
Revision: OpenShift 4.18 application health: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/building_applications/application-health

## Q6 solution
### Option A — Web console / UI-assisted
1. Create project **template-lab** and clone the supplied template repository locally. Template parameter inspection/processing is fastest with `oc`, but the resulting Template objects and resources can be managed in the console.
2. Use **+Add → Import YAML** to paste/apply `build-template.yaml` and `deploy-template.yaml`. Verify both under the Template/API resources available in the console.
3. Use the terminal to process `build-template` with the required parameter values and `-l practice=two,stage=build`; apply the generated resources.
4. Process `deploy-template` with its required hostname/replica parameters and `-l practice=two,stage=deploy`; apply it. The `-l` requirement is a CLI processing feature, so do not omit it just because you are using the UI for the rest.
5. In **Topology** inspect the generated BuildConfig, Deployment, Service and Route. Confirm two replicas and the expected labels.
6. Open the Route and verify the application. Use **Builds → BuildConfigs/Builds** if the build fails.

### Option B — CLI
```bash
# Create the project and clone the supplied templates.
oc new-project template-lab
git clone <GIT_BASE>/pt2-q6-templates.git && cd pt2-q6-templates
# Inspect parameters before processing.
oc process --local -f build-template.yaml --parameters
oc process --local -f deploy-template.yaml --parameters
# Process build objects with values and labels supplied at creation time.
oc process -f build-template.yaml -p APP_NAME=ledger -p GIT_URL=<GIT_BASE>/pt2-q1-quote-api.git -p BUILDER=nodejs:20-ubi9 -l practice=two,stage=build | oc apply -f -
# Process deployment objects with required hostname and labels.
oc process -f deploy-template.yaml -p APP_NAME=ledger -p REPLICAS=2 -p APP_HOST=ledger-template-lab.apps-crc.testing -l practice=two,stage=deploy | oc apply -f -
# Verify labels, replicas and route.
oc get all -l practice=two --show-labels
oc rollout status deploy/ledger
curl -s http://ledger-template-lab.apps-crc.testing/
```
Revision: OpenShift 4.18 Templates: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/building_applications/using-templates

## Q7 solution
### Option A — Web console / UI-assisted
1. Create project **helm-two**. Clone the supplied chart locally; `helm lint`, `helm template`, `helm upgrade`, history and rollback remain Helm CLI operations.
2. In **Developer → +Add**, choose the Helm/chart option available in your console and install the local/repository chart as release **journal** when your console supports that source. Otherwise run the documented `helm install` command and continue management in the UI.
3. Open **Helm → Releases → journal** and inspect the release resources and values. In Topology verify that each pod contains both containers and that the workload is healthy.
4. Perform the required value change using **Upgrade** in the Helm release UI if available; otherwise use `helm upgrade`. Confirm the new replica count/message in Topology.
5. Inspect release history in **Helm → Releases → journal → Revision History** (or `helm history`).
6. Roll back to the required revision from the release actions if exposed by your console; otherwise use `helm rollback`. Verify the resulting revision and pods.

### Option B — CLI
```bash
# Create project and clone chart.
oc new-project helm-two
git clone <GIT_BASE>/pt2-q7-helm.git && cd pt2-q7-helm
# Validate and preview before installing.
helm lint .
helm template journal . --set message='Practice Test Two' --set replicaCount=1
# Install with runtime overrides rather than editing templates.
helm install journal . --set message='Practice Test Two' --set replicaCount=1
# Verify both containers and shared-volume pod.
oc get pods
oc get pod -l app.kubernetes.io/instance=journal -o jsonpath='{.items[0].spec.containers[*].name}{"\\n"}'
# Upgrade values and inspect history/effective values.
helm upgrade journal . --set message='Helm upgrade successful' --set replicaCount=2
helm history journal
helm get values journal
helm get manifest journal
# Roll back one revision and verify.
helm rollback journal 1
helm history journal
```
Revision: OpenShift 4.18 Helm: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/building_applications/working-with-helm-charts

## Q8 solution
### Option A — Web console
1. Create project **pipeline-two**, clone the supplied repository, and use **+Add → Import YAML** to create `build-pipeline` and `deploy-pipeline`.
2. Open **Pipelines → Pipelines** and inspect each Pipeline's tasks and required parameters before running it.
3. Select `build-pipeline` → **Actions → Start**, provide the required `IMAGE` and `SOURCE_URL` parameters, and start the run.
4. Open the resulting PipelineRun and inspect its graphical task status and logs. Do not start deployment until the build run succeeds.
5. Start `deploy-pipeline` from the UI with `APP_NAME` and `IMAGE`, then inspect its PipelineRun and TaskRuns.
6. For a failed run, open the failed task in the PipelineRun graph, inspect logs/events and compare supplied parameters/workspaces with the Pipeline definition.

### Option B — CLI
```bash
# Create the pipeline project and apply the two supplied Pipeline definitions.
oc new-project pipeline-two
git clone <GIT_BASE>/pt2-q8-pipelines.git && cd pt2-q8-pipelines
oc apply -f build-pipeline.yaml -f deploy-pipeline.yaml
# Inspect required parameters instead of guessing them.
oc describe pipeline build
oc describe pipeline deploy
# Generate a PipelineRun from the build Pipeline when tkn is available.
tkn pipeline start build -p IMAGE=image-registry.openshift-image-registry.svc:5000/pipeline-two/pipeline-app:latest -p SOURCE_URL=<GIT_BASE>/pt2-q1-quote-api.git --showlog
# Inspect PipelineRuns and TaskRuns even if tkn is unavailable.
oc get pipelinerun,taskrun
# Start deploy only after successful build.
tkn pipeline start deploy -p APP_NAME=pipeline-app -p IMAGE=image-registry.openshift-image-registry.svc:5000/pipeline-two/pipeline-app:latest --showlog
```
Revision: Red Hat OpenShift Pipelines: https://docs.redhat.com/en/documentation/red_hat_openshift_pipelines/latest/html/creating_cicd_pipelines/index

## Supplemental Q9 — Build hooks and triggers

### Option A — Web console / UI-assisted
1. Open the supplied BuildConfig in **Builds → BuildConfigs** and use its YAML editor to configure the required post-commit hook.
2. Verify the build triggers in the same YAML/details page and ensure the required trigger persists.
3. Start a new build from **Actions → Start build**.
4. Inspect the build logs and status to confirm the hook ran after the image build.
5. Re-open the BuildConfig to verify future builds retain the hook.

### Option B — CLI
```bash
# Configure the post-commit hook on the supplied BuildConfig.
oc set build-hook bc/<BUILD_CONFIG> --post-commit --command -- python <SCRIPT>.py
# Inspect the persistent hook configuration.
oc describe bc/<BUILD_CONFIG>
# Start and follow a new build.
oc start-build <BUILD_CONFIG> --follow
```

## Supplemental Q10 — Kustomize

### Option A — Web console / UI-assisted
1. Render the supplied overlay locally with `oc kustomize`; this part is not replaced by the console.
2. Apply it with `oc apply -k`.
3. Use **Topology/Workloads** to inspect the generated resources, labels, image and replica count.
4. Use the YAML view to compare the resulting objects with the base/overlay intent.
5. Inspect pod events in the console if the rollout fails.

### Option B — CLI
```bash
# Preview the rendered overlay before creating resources.
oc kustomize <OVERLAY_PATH>
# Apply the overlay.
oc apply -k <OVERLAY_PATH>
# Verify the resulting Deployment and labels.
oc get deploy --show-labels
```

## Supplemental Q11 — Integrated image registry

### Option A — Web console / UI-assisted
1. In **Administrator** perspective inspect the image-registry configuration; use YAML to enable `spec.defaultRoute: true` if your RBAC/UI exposes it.
2. Inspect the `openshift-image-registry` namespace Routes and note `default-route`.
3. Podman authentication and pull/push are workstation CLI operations, so use the commands below for those steps.
4. Return to the target project/ImageStream in the console and verify the tag appears.
5. If registry operator configuration is hidden by permissions, use the CLI immediately rather than spending exam time searching menus.

### Option B — CLI
```bash
# Expose the integrated registry externally.
oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge -p '{"spec":{"defaultRoute":true}}'
# Obtain its hostname.
REGISTRY=$(oc get route default-route -n openshift-image-registry -o jsonpath='{.spec.host}')
# Authenticate Podman with the current OpenShift identity/token.
podman login -u $(oc whoami) -p $(oc whoami -t) --tls-verify=false "$REGISTRY"
```

## Supplemental Q12 — Installed Operator application

### Option A — Web console
1. Switch to **Administrator → Operators → Installed Operators** and open the installed Operator named in the task.
2. Select the provided API/custom resource type and choose **Create instance**.
3. Use YAML view when the form does not expose all required fields.
4. Create the custom resource in the required project and inspect its **Status/Conditions**.
5. Inspect the Deployments, Services, service accounts and Events created by the Operator.

### Option B — CLI
```bash
# Discover the Operator API instead of guessing its resource name.
oc api-resources | grep -i <OPERATOR_KEYWORD>
# Inspect the custom-resource schema.
oc explain <RESOURCE>.spec --recursive
# Apply the minimal custom resource supplied/derived for the lab.
oc apply -f <CUSTOM_RESOURCE>.yaml
# Verify reconciliation and generated resources.
oc get <RESOURCE> -o yaml
oc get deploy,svc,sa
```
