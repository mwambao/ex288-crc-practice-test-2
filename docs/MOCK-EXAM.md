# EX288 CRC Practice Test 2

**Target:** EX288 / OpenShift 4.18-style practice on CRC. **Suggested time:** 3 hours for Q1-Q8. Complete Q9-Q12 afterward as supplemental revision. Do not open `SOLUTIONS.md` during a timed attempt.

Replace `<GIT_BASE>` with the base URL where you pushed the repositories under `repos/`. The lab setup also creates an in-cluster artifact endpoint at `http://nexus-mock.lab-infra.svc:8080/` for questions that need a Nexus/Artifactory-like dependency source.

## Q1 — Repair and deploy a Git application with S2I
- Create project `amber` yourself and deploy `quote-api` from `<GIT_BASE>/pt2-q1-quote-api.git` with the OpenShift Node.js builder using Source/S2I strategy.
- The supplied repository contains an invalid `package.json`; locate and repair the syntax problem, commit it, and push the correction to Git before the successful build.
- Configure build environment variable `npm_config_registry=https://registry.npmjs.org/`; do not place this setting in application source.
- Ensure the build output is `quote-api:latest`, deploy it, and expose it with a Route.
- Verify `/` returns `Fortune favors the prepared` and trigger a second successful build from the same BuildConfig.
- Use BuildConfig/Build status and logs to prove which failure occurred before the correction and that the latest build succeeded.

## Q2 — Containerfile, Docker strategy, parent/child behavior
- Create project `cobalt` yourself. Clone `<GIT_BASE>/pt2-q2-container.git`; inspect its `Containerfile` and `src/` before building.
- Optimize the supplied Containerfile so related filesystem operations are consolidated and add `ONBUILD COPY src/ /opt/app-root/src/` so a child image can override default content.
- Create BuildConfig `parent-web` from Git using **Docker strategy** and explicitly set `dockerfilePath=Containerfile`; output to `parent-web:1.0`.
- Pass build argument `BANNER_URL=http://nexus-mock.lab-infra.svc:8080/banner.txt`; the build must download that artifact and include it in the image.
- Create/deploy a child build `child-web` that uses `parent-web:1.0` as its parent, supplies the repository `src/`, and exposes a working HTTP service.
- Verify build strategies, ImageStreams, build logs and final HTTP output; correct a Source-vs-Docker strategy mistake without recreating the project.

## Q3 — Customize S2I builder behavior
- Create project `sienna` and application `stellar` from `<GIT_BASE>/pt2-q3-stellar.git` using an HTTPD builder ImageStreamTag available in `openshift`.
- Customize `.s2i/bin/assemble` so all HTML files from `/tmp/src/` are copied into the runtime document root and `build-info.html` is generated during build.
- `build-info.html` must contain the build date in `YYYY-MM-DD` format and the text `Ad astra per scientiam`.
- Configure BuildConfig environment variable `SITE_OWNER=crc-student` and make the custom assemble script write that owner into `build-info.html`.
- Build, deploy and expose the application; `/` must return `Stars guide the way` and `/build-info.html` must contain all required generated information.
- Start another build and use `oc describe build`, logs and BuildConfig inspection to distinguish persistent build configuration from one Build instance.

## Q4 — ConfigMaps and Secrets
- Create project `violet` and deploy `config-api` from `<GIT_BASE>/pt2-q4-config-api.git`.
- Create ConfigMap `app-settings` with `GREETING=Configuration is external` and `LOG_LEVEL=info`; inject both values into the Deployment without hard-coding them in the pod template.
- Create Secret `backend-credentials` with `API_USER=serviceuser` and `API_KEY=pt2-secret-key`; inject it using a Secret reference, not literal values in Deployment YAML.
- Expose the app and verify `/` reports the greeting, log level and `credentials-loaded` but does not reveal the secret value.
- Change `GREETING` to `Configuration updated`, restart/roll out the workload as needed, and verify the new response while the Secret remains unchanged.
- Diagnose a deliberately misspelled ConfigMap/Secret reference by using Deployment YAML, pod events and environment inspection, then correct it.

## Q5 — Startup, liveness and readiness probes
- Create project `probe-lab` and deploy `probe-api` from `<GIT_BASE>/pt2-q5-probe-api.git` on port 8080.
- Add a startup HTTP check against `/startup`; allow about 40 seconds for startup, test every 5 seconds, and tolerate several failures before restart.
- Add a liveness HTTP check against `/healthz`; wait before the first check, test every 10 seconds, and use a short timeout plus multiple failures before restart.
- Add a readiness HTTP check against `/ready`; begin checking sooner than liveness, test every 5 seconds, and remove the pod from endpoints after two consecutive failures.
- Explicitly configure at least two non-default timing/threshold settings on **each** probe and ensure the configuration persists across rollout/rebuild.
- Verify all three probes from Deployment YAML and `oc describe pod`; confirm the Deployment becomes available and the Service has ready endpoints.

## Q6 — Two supplied templates and labels
- Create project `template-lab`. Retrieve `<GIT_BASE>/pt2-q6-templates.git`, which contains `build-template.yaml` and `deploy-template.yaml`; do not replace them with `oc new-app` generated resources.
- Import/process `build-template` with `APP_NAME=ledger`, `GIT_URL=<GIT_BASE>/pt2-q1-quote-api.git`, and an appropriate Node.js builder value; add label `practice=two,stage=build` during processing/creation with `-l`.
- Process `deploy-template` with `APP_NAME=ledger`, `REPLICAS=2`, and `APP_HOST=ledger-template-lab.apps-crc.testing`; add label `practice=two,stage=deploy` using `-l`.
- Make `APP_HOST` required so processing the deploy template without it fails, while the fully parameterized invocation succeeds.
- Ensure the deployment consumes the image produced by the build template, reaches two ready replicas, and is reachable through the requested Route.
- Use `oc process --parameters`, label selectors and rendered output to prove parameter substitution and labels are correct without editing generated resources manually.

## Q7 — Multi-container Helm deployment
- Create project `helm-two`; clone `<GIT_BASE>/pt2-q7-helm.git` and inspect/lint/render the supplied chart before installation.
- Install release `journal` so each pod contains containers `writer` and `reader` sharing an `emptyDir`; `writer` writes a configurable message and `reader` serves the shared file over HTTP.
- Override `message=Practice Test Two` and `replicaCount=1` at install time without editing templates.
- Upgrade the release to two replicas and change the message to `Helm upgrade successful`; verify both the revision history and running state.
- Inspect effective values and rendered release manifests, then intentionally supply a bad value/type, observe the failure, and recover with a valid upgrade.
- Roll back one revision and verify the release revision and application content reflect the rollback.

## Q8 — Build and deploy Pipelines
- Create project `pipeline-two`; retrieve `<GIT_BASE>/pt2-q8-pipelines.git` containing `build-pipeline.yaml` and `deploy-pipeline.yaml` and apply both supplied Pipelines without rewriting them.
- Inspect the Pipeline parameters and create a `build` PipelineRun supplying `IMAGE=.../pipeline-two/pipeline-app:latest` and `SOURCE_URL=<GIT_BASE>/pt2-q1-quote-api.git`.
- Make the build PipelineRun complete successfully and verify its TaskRuns/logs and the resulting ImageStream/image target.
- Create a `deploy` PipelineRun only after the build succeeds, supplying `APP_NAME=pipeline-app` and the image parameter required by the supplied Pipeline.
- Diagnose one intentionally failed PipelineRun caused by an incorrect parameter or Pipeline reference; create a **new corrected PipelineRun** rather than trying to mutate the completed run.
- Run a second successful cycle and show PipelineRun history, TaskRun ordering/status and logs using `oc` and, if installed, `tkn`.

---
# SUPPLEMENTAL — complete after Q1-Q8

## Supplemental Q9 — Build hook and build triggers
- Create project `hook-two` and an S2I application from `<GIT_BASE>/pt2-q9-hook.git`.
- Configure a post-commit hook that runs `python3 verify.py` from the built image after a successful build.
- Configure and inspect BuildConfig triggers, including an image/configuration trigger appropriate to the build.
- Start a build and prove in logs/status that the hook executed successfully.
- Change BuildConfig configuration to cause another build and identify its trigger cause.
- Break the hook command once, diagnose the failed build, correct it and produce a successful latest build.

## Supplemental Q10 — Kustomize
- Create project `kustomize-two` and use `<GIT_BASE>/pt2-q10-kustomize.git`.
- Inspect the base Deployment/Service and the `overlays/test` customization before applying it.
- Modify only the overlay so replicas become 2 and labels include `environment=test` and `practice=two`.
- Render with `oc kustomize overlays/test` and validate the output before applying.
- Apply with `oc apply -k overlays/test` and verify replicas/labels/service.
- Make another overlay-only environment variable change, reapply, and prove files under `base/` were not changed.

## Supplemental Q11 — Integrated image registry
- Create project `registry-two` and, using an account with required privileges, inspect whether the integrated registry has a default external route.
- Enable the default route if necessary and derive its hostname dynamically.
- Authenticate Podman using your OpenShift username and token.
- Tag and push a local test image to `<registry-host>/registry-two/toolbox:v2`.
- Verify ImageStream/tag metadata in OpenShift, remove the local tag, then pull the same image back from the registry.
- Explain from the commands/output how project, ImageStream name and tag map to the registry repository path.

## Supplemental Q12 — Installed Operator
- Create project `operator-two` and discover the installed `NginxGatewayFabric` API with `oc api-resources`, `oc explain` and CRD inspection.
- Determine its group/version/kind and minimum valid spec without copying a memorized manifest.
- Create custom resource `second-gateway` using the minimum valid specification.
- Verify its status contains successful initialization/deployment conditions.
- Identify at least three Operator-managed resources created because of the CR and verify their status.
- Use events/status/workload logs to troubleshoot reconciliation if necessary; do not manually create resources that the Operator should own.
