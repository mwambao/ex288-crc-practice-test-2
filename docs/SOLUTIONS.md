# Practice Test 2 — Solutions and revision notes

> Use only after attempting the questions. Replace `<GIT_BASE>` with your Git base URL. Builder tags can differ by CRC bundle; inspect `oc get is -n openshift` first.

## Q1 solution
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

## Supplemental Q9-Q12
Use the same diagnostic-first workflow: Q9 `oc set build-hook`, `oc describe bc`, build logs; Q10 `oc kustomize` then `oc apply -k`; Q11 image-registry defaultRoute + `oc whoami -t` + Podman; Q12 API discovery + minimal `NginxGatewayFabric` CR and status verification. These intentionally repeat published objective families while changing names/resources from Practice Test 1.
