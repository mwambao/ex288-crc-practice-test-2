#!/usr/bin/env bash
set -u
for p in amber cobalt sienna violet probe-lab template-lab helm-two pipeline-two hook-two kustomize-two registry-two operator-two; do oc delete project "$p" --ignore-not-found=true; done
echo 'Practice Test 2 projects removed; shared lab-infra retained.'
