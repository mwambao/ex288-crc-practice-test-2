#!/usr/bin/env bash
set -u
q=${1:-all}; pass=0; fail=0
check(){ local msg=$1; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $msg"; pass=$((pass+1)); else echo "FAIL  $msg"; fail=$((fail+1)); fi; }
mark(){ case $1 in
1) check 'Q1 project' oc get project amber; check 'Q1 build' oc get bc quote-api -n amber; check 'Q1 route' oc get route quote-api -n amber;;
2) check 'Q2 Docker BuildConfig' oc get bc parent-web -n cobalt; check 'Q2 parent image' oc get istag parent-web:1.0 -n cobalt;;
3) check 'Q3 BuildConfig' oc get bc stellar -n sienna; check 'Q3 route' oc get route stellar -n sienna;;
4) check 'Q4 ConfigMap' oc get cm app-settings -n violet; check 'Q4 Secret' oc get secret backend-credentials -n violet;;
5) check 'Q5 deployment' oc get deploy probe-api -n probe-lab; check 'Q5 available' bash -c "[ "$(oc get deploy probe-api -n probe-lab -o jsonpath='{.status.availableReplicas}' 2>/dev/null)" != '' ]";;
6) check 'Q6 deployment' oc get deploy ledger -n template-lab; check 'Q6 route' oc get route ledger -n template-lab;;
7) check 'Q7 Helm release' helm status journal -n helm-two;;
8) check 'Q8 build Pipeline' oc get pipeline build -n pipeline-two; check 'Q8 deploy Pipeline' oc get pipeline deploy -n pipeline-two;;
9) check 'Q9 BuildConfig' oc get bc -n hook-two;; 10) check 'Q10 deployment' oc get deploy kustom-app -n kustomize-two;; 11) check 'Q11 project' oc get project registry-two;; 12) check 'Q12 CR' oc get nginxgatewayfabric second-gateway -n operator-two;; esac; }
if [ "$q" = all ]; then for i in $(seq 1 12); do echo "=== Q$i ==="; mark $i; done; else mark "$q"; fi
echo "SUMMARY: $pass PASS, $fail FAIL"; [ $fail -eq 0 ]
