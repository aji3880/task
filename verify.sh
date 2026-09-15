#!/usr/bin/env bash
#
# EX280 / DO280 Lab Task Verifier with Weighted Grading System
#
# Usage:
#   chmod +x verify-ex280.sh
#   ./verify-ex280.sh
#

set -u
export KUBECONFIG="${KUBECONFIG:-}"

PASS=0
FAIL=0
MANUAL=0

# Variabel Nilai Ujian
TOTAL_SCORE=0
MAX_TOTAL_SCORE=300
PASS_THRESHOLD=210

Q4_NS="${Q4_NS:-quart}"
Q4_HOST="${Q4_HOST:-}"
Q4_SERVICE="${Q4_SERVICE:-todo-http}"

say() { printf '%-8s %s\n' "$1" "$2"; }
pass() { say "PASS" "$1"; PASS=$((PASS+1)); }
fail() { say "FAIL" "$1"; FAIL=$((FAIL+1)); }
manual() { say "MANUAL" "$1"; MANUAL=$((MANUAL+1)); }

need_oc() {
  command -v oc >/dev/null 2>&1 || {
    echo "ERROR: oc command not found."
    exit 1
  }
  oc whoami >/dev/null 2>&1 || {
    echo "ERROR: current oc session is not authenticated."
    exit 1
  }
}

exists_ns() { oc get ns "$1" >/dev/null 2>&1; }

section() {
  echo
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

pause() {
  echo
  read -r -p "Tekan [Enter] untuk mengevaluasi pertanyaan berikutnya..."
}

# Helper untuk kalkulasi poin per pertanyaan
# usage: add_score <q_pass> <q_total_checks> <q_max_points>
calculate_q_score() {
  local q_pass="$1"
  local q_total_checks="$2"
  local q_max_points="$3"
  local q_score=0

  if (( q_total_checks > 0 )); then
    q_score=$(( (q_pass * q_max_points) / q_total_checks ))
  fi

  TOTAL_SCORE=$(( TOTAL_SCORE + q_score ))
  echo "------------------------------------------------------------"
  echo "POIN SOAL INI : $q_score / $q_max_points Poin ($q_pass/$q_total_checks kriteria terpenuhi)"
}

# Q1 --------------------------------------------------------------------------
check_q1() {
  local q_max=20 q_pass=0 q_total=0
  section "Q1 - HTPasswd Authentication (Bobot: $q_max Poin)"

  local users secret auth
  users="$(oc get secret super-secret -n openshift-config \
    -o jsonpath='{.data.htpasswd}' 2>/dev/null | base64 -d 2>/dev/null | cut -d: -f1 2>/dev/null || true)"

  for u in harry leader raja qa-engineer; do
    q_total=$((q_total+1))
    if grep -qx "$u" <<<"$users"; then
      pass "Q1: user $u exists in super-secret"; q_pass=$((q_pass+1))
    else
      fail "Q1: user $u missing from super-secret"
    fi
  done

  q_total=$((q_total+1))
  if oc get secret super-secret -n openshift-config >/dev/null 2>&1; then
    pass "Q1: secret super-secret exists"; q_pass=$((q_pass+1))
  else
    fail "Q1: secret super-secret does not exist"
  fi

  q_total=$((q_total+1))
  auth="$(oc get oauth cluster -o jsonpath='{.spec.identityProviders}' 2>/dev/null || true)"
  if grep -qw "super-secret" <<<"$auth"; then
    pass "Q1: OAuth HTPasswd provider references super-secret"; q_pass=$((q_pass+1))
  else
    fail "Q1: OAuth HTPasswd provider does not reference super-secret"
  fi

  q_total=$((q_total+1))
  if oc get oauth cluster -o yaml 2>/dev/null | grep -q 'name: ex280-provider'; then
    pass "Q1: identity provider ex280-provider found"; q_pass=$((q_pass+1))
  else
    fail "Q1: identity provider ex280-provider not found"
  fi

  q_total=$((q_total+1))
  if [[ "$(oc get clusteroperator authentication -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)" == "True" ]]; then
    pass "Q1: authentication ClusterOperator is Available"; q_pass=$((q_pass+1))
  else
    fail "Q1: authentication ClusterOperator is not Available=True"
  fi

  for u in harry leader raja qa-engineer; do
    q_total=$((q_total+1))
    if oc get user "$u" >/dev/null 2>&1; then
      pass "Q1: OpenShift User $u exists"; q_pass=$((q_pass+1))
    else
      fail "Q1: OpenShift User $u does not exist"
    fi
  done

  calculate_q_score "$q_pass" "$q_total" "$q_max"
}

# Q2 --------------------------------------------------------------------------
check_q2() {
  local q_max=20 q_pass=0 q_total=0
  section "Q2 - Projects and Permissions (Bobot: $q_max Poin)"

  for ns in front-end back-end app-db; do
    q_total=$((q_total+1))
    if exists_ns "$ns"; then pass "Q2: project $ns exists"; q_pass=$((q_pass+1)); else fail "Q2: project $ns missing"; fi
  done

  q_total=$((q_total+1))
  if [[ "$(oc auth can-i '*' '*' -A --as=harry 2>/dev/null)" == "yes" ]]; then
    pass "Q2: harry has cluster-admin level access"; q_pass=$((q_pass+1))
  else
    fail "Q2: harry does not have full cluster access"
  fi

  q_total=$((q_total+1))
  if [[ "$(oc auth can-i create projectrequests.project.openshift.io --as=leader 2>/dev/null)" == "yes" ]]; then
    pass "Q2: leader can create projectrequests"; q_pass=$((q_pass+1))
  else
    fail "Q2: leader cannot create projectrequests"
  fi

  for u in raja qa-engineer; do
    q_total=$((q_total+1))
    if [[ "$(oc auth can-i create projectrequests.project.openshift.io --as="$u" 2>/dev/null)" == "no" ]]; then
      pass "Q2: $u cannot create projectrequests"; q_pass=$((q_pass+1))
    else
      fail "Q2: $u can create projectrequests (expected no)"
    fi
  done

  q_total=$((q_total+1))
  if [[ "$(oc auth can-i get pods -n front-end --as=raja 2>/dev/null)" == "yes" ]]; then
    pass "Q2: raja can view front-end pods"; q_pass=$((q_pass+1))
  else
    fail "Q2: raja cannot view front-end pods"
  fi

  q_total=$((q_total+1))
  if [[ "$(oc auth can-i get pods -n back-end --as=raja 2>/dev/null)" == "yes" ]]; then
    pass "Q2: raja can view back-end pods"; q_pass=$((q_pass+1))
  else
    fail "Q2: raja cannot view back-end pods"
  fi

  q_total=$((q_total+1))
  if [[ "$(oc auth can-i create deployments.apps -n front-end --as=raja 2>/dev/null)" == "no" ]]; then
    pass "Q2: raja cannot create deployments in front-end"; q_pass=$((q_pass+1))
  else
    fail "Q2: raja can create deployments in front-end"
  fi

  q_total=$((q_total+1))
  if [[ "$(oc auth can-i create deployments.apps -n front-end --as=qa-engineer 2>/dev/null)" == "yes" ]]; then
    pass "Q2: qa-engineer can create deployments in front-end"; q_pass=$((q_pass+1))
  else
    fail "Q2: qa-engineer cannot create deployments in front-end"
  fi

  q_total=$((q_total+1))
  if [[ "$(oc auth can-i create rolebindings.rbac.authorization.k8s.io -n front-end --as=qa-engineer 2>/dev/null)" == "yes" ]]; then
    pass "Q2: qa-engineer can create rolebindings in front-end"; q_pass=$((q_pass+1))
  else
    fail "Q2: qa-engineer cannot create rolebindings in front-end"
  fi

  local sp
  sp="$(oc get clusterrolebinding.rbac self-provisioners -o yaml 2>/dev/null || true)"
  q_total=$((q_total+1))
  if grep -q 'system:authenticated:oauth' <<<"$sp"; then
    fail "Q2: self-provisioners still contains system:authenticated:oauth"
  else
    pass "Q2: system:authenticated:oauth is absent from self-provisioners"; q_pass=$((q_pass+1))
  fi

  q_total=$((q_total+1))
  if grep -q 'rbac.authorization.kubernetes.io/autoupdate: "false"' <<<"$sp"; then
    pass "Q2: self-provisioners autoupdate=false"; q_pass=$((q_pass+1))
  else
    fail "Q2: self-provisioners autoupdate=false not found"
  fi

  calculate_q_score "$q_pass" "$q_total" "$q_max"
}

# Q3 --------------------------------------------------------------------------
check_q3() {
  local q_max=15 q_pass=0 q_total=0
  section "Q3 - Groups and Project Roles (Bobot: $q_max Poin)"

  for spec in "leaders:leader" "developers:raja" "qa:qa-engineer"; do
    g="${spec%%:*}"
    u="${spec##*:}"
    members="$(oc get group "$g" -o jsonpath='{.users[*]}' 2>/dev/null || true)"

    q_total=$((q_total+1))
    if grep -qw "$u" <<< "$members"; then
        pass "Q3: $u is member of group $g"; q_pass=$((q_pass+1))
    else
        fail "Q3: $u is not member of group $g"
    fi
  done

  q_total=$((q_total+1))
  if [[ "$(oc auth can-i update deployments.apps -n back-end --as=rbac-test --as-group=leaders 2>/dev/null)" == "yes" ]]; then
    pass "Q3: leaders can update deployments in back-end"; q_pass=$((q_pass+1))
  else
    fail "Q3: leaders cannot update deployments in back-end"
  fi

  q_total=$((q_total+1))
  if [[ "$(oc auth can-i update deployments.apps -n app-db --as=rbac-test --as-group=leaders 2>/dev/null)" == "yes" ]]; then
    pass "Q3: leaders can update deployments in app-db"; q_pass=$((q_pass+1))
  else
    fail "Q3: leaders cannot update deployments in app-db"
  fi

  q_total=$((q_total+1))
  if [[ "$(oc auth can-i create rolebindings.rbac.authorization.k8s.io -n back-end --as=rbac-test --as-group=leaders 2>/dev/null)" == "no" ]]; then
    pass "Q3: leaders cannot create rolebindings in back-end"; q_pass=$((q_pass+1))
  else
    fail "Q3: leaders can create rolebindings in back-end"
  fi

  q_total=$((q_total+1))
  if [[ "$(oc auth can-i get pods -n front-end --as=rbac-test --as-group=qa 2>/dev/null)" == "yes" ]]; then
    pass "Q3: qa group can get pods in front-end"; q_pass=$((q_pass+1))
  else
    fail "Q3: qa group cannot get pods in front-end"
  fi

  q_total=$((q_total+1))
  if [[ "$(oc auth can-i create deployments.apps -n front-end --as=rbac-test --as-group=qa 2>/dev/null)" == "no" ]]; then
    pass "Q3: qa group cannot create deployments in front-end"; q_pass=$((q_pass+1))
  else
    fail "Q3: qa group can create deployments in front-end"
  fi

  q_total=$((q_total+1))
  if [[ "$(oc auth can-i get pods -n front-end --as=qa-engineer 2>/dev/null)" == "yes" ]]; then
    pass "Q3: qa-engineer can get pods in front-end"; q_pass=$((q_pass+1))
  else
    fail "Q3: qa-engineer cannot get pods in front-end"
  fi

  calculate_q_score "$q_pass" "$q_total" "$q_max"
}

# Q4 --------------------------------------------------------------------------
check_q4() {
  local q_max=15 q_pass=0 q_total=0
  section "Q4 - TLS Route (Bobot: $q_max Poin)"

  if ! exists_ns "$Q4_NS"; then
    fail "Q4: namespace $Q4_NS missing"
    manual "Q4: cannot verify Route because namespace is missing"
    calculate_q_score 0 1 "$q_max"
    return
  fi

  local route host tls cert_subject
  route="$(oc get route "$Q4_SERVICE" -n "$Q4_NS" -o name 2>/dev/null || true)"
  q_total=$((q_total+1))
  if [[ -n "$route" ]]; then pass "Q4: Route $Q4_SERVICE exists"; q_pass=$((q_pass+1)); else fail "Q4: Route $Q4_SERVICE missing"; fi

  tls="$(oc get route "$Q4_SERVICE" -n "$Q4_NS" -o jsonpath='{.spec.tls.termination}' 2>/dev/null || true)"
  q_total=$((q_total+1))
  if [[ -n "$tls" ]]; then pass "Q4: Route has TLS termination ($tls)"; q_pass=$((q_pass+1)); else fail "Q4: Route has no TLS termination"; fi

  host="$(oc get route "$Q4_SERVICE" -n "$Q4_NS" -o jsonpath='{.spec.host}' 2>/dev/null || true)"
  if [[ -n "$Q4_HOST" ]]; then
    q_total=$((q_total+1))
    if [[ "$host" == "$Q4_HOST" ]]; then
      pass "Q4: Route host matches Q4_HOST=$Q4_HOST"; q_pass=$((q_pass+1))
    else
      fail "Q4: Route host is $host, expected $Q4_HOST"
    fi
  else
    echo "Q4: detected Route host: ${host:-<none>}"
    manual "Q4: set Q4_HOST to verify the exact required hostname"
  fi

  if [[ -n "$host" ]] && command -v openssl >/dev/null 2>&1; then
    cert_subject="$(echo | openssl s_client -connect "${host}:443" -servername "$host" 2>/dev/null |
      openssl x509 -noout -subject 2>/dev/null || true)"
    q_total=$((q_total+1))
    if [[ -n "$cert_subject" ]]; then
      pass "Q4: TLS certificate is presented by the Route"; q_pass=$((q_pass+1))
      echo "         $cert_subject"
    else
      fail "Q4: could not retrieve TLS certificate from Route"
    fi
  else
    manual "Q4: verify certificate subject manually with openssl s_client"
  fi

  calculate_q_score "$q_pass" "$q_total" "$q_max"
}

# Q5 --------------------------------------------------------------------------
check_q5() {
  local q_max=15 q_pass=0 q_total=0
  section "Q5 - Application Output in red (Bobot: $q_max Poin)"
  if ! exists_ns red; then
    fail "Q5: project red missing"
    calculate_q_score 0 1 "$q_max"
    return
  fi

  local pods running
  pods="$(oc get pods -n red --no-headers 2>/dev/null | wc -l | tr -d ' ')"
  running="$(oc get pods -n red --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')"

  q_total=$((q_total+1))
  if [[ "$pods" == "1" && "$running" == "1" ]]; then
    pass "Q5: exactly one Running pod exists in red"; q_pass=$((q_pass+1))
  else
    fail "Q5: expected one Running pod in red; found total=$pods running=$running"
  fi
  manual "Q5: check 'oc logs <pod> -n red' against the required output"

  calculate_q_score "$q_pass" "$q_total" "$q_max"
}

# Q6 --------------------------------------------------------------------------
check_q6() {
  local q_max=15 q_pass=0 q_total=0
  section "Q6 - ServiceAccount + anyuid SCC (Bobot: $q_max Poin)"

  q_total=$((q_total+1))
  if oc get sa ex280-sa -n alpha >/dev/null 2>&1; then
    pass "Q6: service account ex280-sa exists in alpha"; q_pass=$((q_pass+1))
  else
    fail "Q6: service account ex280-sa missing in alpha"
    calculate_q_score "$q_pass" "$q_total" "$q_max"
    return
  fi

  q_total=$((q_total+1))
  if oc adm policy who-can use scc anyuid 2>/dev/null | grep -q 'system:serviceaccount:alpha:ex280-sa'; then
    pass "Q6: alpha/ex280-sa can use anyuid SCC"; q_pass=$((q_pass+1))
  else
    fail "Q6: alpha/ex280-sa is not shown as allowed to use anyuid SCC"
  fi

  calculate_q_score "$q_pass" "$q_total" "$q_max"
}

# Q7 --------------------------------------------------------------------------
check_q7() {
  local q_max=15 q_pass=0 q_total=0
  section "Q7 - Deployment uses ex280-sa (Bobot: $q_max Poin)"

  if ! oc get deployment gitlab -n alpha >/dev/null 2>&1; then
    fail "Q7: deployment gitlab missing in alpha"
    calculate_q_score 0 1 "$q_max"
    return
  fi

  local sa1 sa2
  sa1="$(oc get deployment gitlab -n alpha -o jsonpath='{.spec.template.spec.serviceAccountName}' 2>/dev/null || true)"
  sa2="$(oc get deployment gitlab -n alpha -o jsonpath='{.spec.template.spec.serviceAccount}' 2>/dev/null || true)"

  q_total=$((q_total+1))
  if [[ "$sa1" == "ex280-sa" || "$sa2" == "ex280-sa" ]]; then
    pass "Q7: gitlab deployment uses service account ex280-sa"; q_pass=$((q_pass+1))
  else
    fail "Q7: gitlab deployment service account is '${sa1:-<unset>}'"
  fi

  q_total=$((q_total+1))
  if oc get pods -n alpha --field-selector=status.phase=Running --no-headers 2>/dev/null | grep -q .; then
    pass "Q7: at least one Running pod exists in alpha"; q_pass=$((q_pass+1))
  else
    fail "Q7: no Running pod found in alpha"
  fi

  manual "Q7: compare application output with expected output"
  calculate_q_score "$q_pass" "$q_total" "$q_max"
}

# Q8 --------------------------------------------------------------------------
check_q8() {
  local q_max=15 q_pass=0 q_total=0
  section "Q8 - Secret (Bobot: $q_max Poin)"

  q_total=$((q_total+1))
  if oc get secret ex280-secret -n cloud >/dev/null 2>&1; then
    pass "Q8: secret ex280-secret exists in cloud"; q_pass=$((q_pass+1))
  else
    fail "Q8: secret ex280-secret missing in cloud"
    calculate_q_score 0 1 "$q_max"
    return
  fi

  local key val
  key="$(oc get secret ex280-secret -n cloud -o jsonpath='{.data.MYSQL_PASSWORD}' 2>/dev/null || true)"
  q_total=$((q_total+1))
  if [[ -n "$key" ]]; then
    pass "Q8: MYSQL_PASSWORD key exists"; q_pass=$((q_pass+1))
  else
    fail "Q8: MYSQL_PASSWORD key missing"
    calculate_q_score "$q_pass" "$q_total" "$q_max"
    return
  fi

  val="$(printf '%s' "$key" | base64 -d 2>/dev/null || true)"
  q_total=$((q_total+1))
  if [[ "$val" == "redhat123" ]]; then
    pass "Q8: MYSQL_PASSWORD has expected value"; q_pass=$((q_pass+1))
  else
    fail "Q8: MYSQL_PASSWORD value does not match expected value"
  fi

  calculate_q_score "$q_pass" "$q_total" "$q_max"
}

# Q9 --------------------------------------------------------------------------
check_q9() {
  local q_max=15 q_pass=0 q_total=0
  section "Q9 - Pod consumes ex280-secret (Bobot: $q_max Poin)"
  local found=0

  if ! exists_ns cloud; then
    fail "Q9: project cloud missing"
    calculate_q_score 0 1 "$q_max"
    return
  fi

  while read -r pod; do
    [[ -z "$pod" ]] && continue

    if oc get pod "$pod" -n cloud -o json 2>/dev/null | grep -q 'ex280-secret'; then
      found=1
      q_total=$((q_total+1))
      pass "Q9: pod $pod references ex280-secret"; q_pass=$((q_pass+1))

      local phase
      phase="$(oc get pod "$pod" -n cloud -o jsonpath='{.status.phase}' 2>/dev/null || true)"
      q_total=$((q_total+1))
      if [[ "$phase" == "Running" ]]; then
        pass "Q9: pod $pod is Running"; q_pass=$((q_pass+1))
      else
        fail "Q9: pod $pod phase=$phase"
      fi
    fi
  done < <(oc get pods -n cloud -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null)

  if [[ "$found" -eq 0 ]]; then
    q_total=$((q_total+1))
    fail "Q9: no pod in cloud references ex280-secret"
  fi

  manual "Q9: review application logs/events to confirm functional output"
  calculate_q_score "$q_pass" "$q_total" "$q_max"
}

# Q10 -------------------------------------------------------------------------
check_q10() {
  local q_max=15 q_pass=0 q_total=0
  section "Q10 - ResourceQuota (Bobot: $q_max Poin)"

  if ! oc get quota ex280-quota -n beta >/dev/null 2>&1; then
    fail "Q10: ResourceQuota ex280-quota missing in beta"
    calculate_q_score 0 1 "$q_max"
    return
  fi

  local yaml
  yaml="$(oc get quota ex280-quota -n beta -o yaml)"
  
  q_total=$((q_total+1)); pass "Q10: ResourceQuota ex280-quota exists"; q_pass=$((q_pass+1))

  q_total=$((q_total+1))
  grep -qE 'pods: "?7"?' <<<"$yaml" && { pass "Q10: pods hard limit=7"; q_pass=$((q_pass+1)); } || fail "Q10: pods hard limit is not 7"
  
  q_total=$((q_total+1))
  grep -qE 'services: "?6"?' <<<"$yaml" && { pass "Q10: services hard limit=6"; q_pass=$((q_pass+1)); } || fail "Q10: services hard limit is not 6"
  
  q_total=$((q_total+1))
  grep -qE 'replicationcontrollers: "?5"?' <<<"$yaml" && { pass "Q10: replicationcontrollers hard limit=5"; q_pass=$((q_pass+1)); } || fail "Q10: replicationcontrollers hard limit is not 5"
  
  q_total=$((q_total+1))
  grep -qE 'memory: "?1G"?' <<<"$yaml" && { pass "Q10: memory hard limit=1G"; q_pass=$((q_pass+1)); } || fail "Q10: memory hard limit is not 1G"
  
  q_total=$((q_total+1))
  grep -qE 'cpu: "?1"?' <<<"$yaml" && { pass "Q10: cpu hard limit=1"; q_pass=$((q_pass+1)); } || fail "Q10: cpu hard limit is not 1"

  calculate_q_score "$q_pass" "$q_total" "$q_max"
}

# Q11 -------------------------------------------------------------------------
check_q11() {
  local q_max=15 q_pass=0 q_total=0
  section "Q11 - LimitRange (Bobot: $q_max Poin)"
  local name
  
  name="$(oc get limitrange ex280-limitrange -n orange -o jsonpath='{.metadata.name}' 2>/dev/null || true)"
  if [[ -z "$name" ]]; then
    fail "Q11: LimitRange ex280-limitrange missing in orange"
    calculate_q_score 0 1 "$q_max"
    return
  fi
  
  q_total=$((q_total+1)); pass "Q11: LimitRange $name exists"; q_pass=$((q_pass+1))

  local mem_min mem_max mem_def_req cpu_min cpu_max cpu_def_req
  
  mem_min="$(oc get limitrange "$name" -n orange -o jsonpath='{.spec.limits[?(@.type=="Container")].min.memory}' 2>/dev/null)"
  mem_max="$(oc get limitrange "$name" -n orange -o jsonpath='{.spec.limits[?(@.type=="Container")].max.memory}' 2>/dev/null)"
  mem_def_req="$(oc get limitrange "$name" -n orange -o jsonpath='{.spec.limits[?(@.type=="Container")].defaultRequest.memory}' 2>/dev/null)"

  cpu_min="$(oc get limitrange "$name" -n orange -o jsonpath='{.spec.limits[?(@.type=="Container")].min.cpu}' 2>/dev/null)"
  cpu_max="$(oc get limitrange "$name" -n orange -o jsonpath='{.spec.limits[?(@.type=="Container")].max.cpu}' 2>/dev/null)"
  cpu_def_req="$(oc get limitrange "$name" -n orange -o jsonpath='{.spec.limits[?(@.type=="Container")].defaultRequest.cpu}' 2>/dev/null)"

  q_total=$((q_total+1))
  [[ "$mem_min" == "5Mi" ]] && { pass "Q11: memory min=5Mi"; q_pass=$((q_pass+1)); } || fail "Q11: memory min expected 5Mi, got '$mem_min'"
  
  q_total=$((q_total+1))
  [[ "$mem_max" == "300Mi" ]] && { pass "Q11: memory max=300Mi"; q_pass=$((q_pass+1)); } || fail "Q11: memory max expected 300Mi, got '$mem_max'"
  
  q_total=$((q_total+1))
  [[ "$mem_def_req" == "100Mi" ]] && { pass "Q11: memory defaultRequest=100Mi"; q_pass=$((q_pass+1)); } || fail "Q11: memory defaultRequest expected 100Mi, got '$mem_def_req'"

  q_total=$((q_total+1))
  [[ "$cpu_min" == "5m" ]] && { pass "Q11: CPU min=5m"; q_pass=$((q_pass+1)); } || fail "Q11: CPU min expected 5m, got '$cpu_min'"
  
  q_total=$((q_total+1))
  [[ "$cpu_max" == "300m" ]] && { pass "Q11: CPU max=300m"; q_pass=$((q_pass+1)); } || fail "Q11: CPU max expected 300m, got '$cpu_max'"
  
  q_total=$((q_total+1))
  [[ "$cpu_def_req" == "100m" ]] && { pass "Q11: CPU defaultRequest=100m"; q_pass=$((q_pass+1)); } || fail "Q11: CPU defaultRequest expected 100m, got '$cpu_def_req'"

  calculate_q_score "$q_pass" "$q_total" "$q_max"
}

# Q12 -------------------------------------------------------------------------
check_q12() {
  local q_max=10 q_pass=0 q_total=0
  section "Q12 - Scale tiger to 5 (Bobot: $q_max Poin)"

  if ! exists_ns tiger; then
    fail "Q12: project tiger missing"
    calculate_q_score 0 1 "$q_max"
    return
  fi

  local total running
  total="$(oc get pods -n tiger --no-headers 2>/dev/null | wc -l | tr -d ' ')"
  running="$(oc get pods -n tiger --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')"

  q_total=$((q_total+1))
  [[ "$total" == "5" ]] && { pass "Q12: 5 pods exist in tiger"; q_pass=$((q_pass+1)); } || fail "Q12: expected 5 pods; found $total"

  q_total=$((q_total+1))
  [[ "$running" == "5" ]] && { pass "Q12: all 5 pods are Running"; q_pass=$((q_pass+1)); } || fail "Q12: expected 5 Running pods; found $running"

  calculate_q_score "$q_pass" "$q_total" "$q_max"
}

# Q13 -------------------------------------------------------------------------
check_q13() {
  local q_max=15 q_pass=0 q_total=0
  section "Q13 - Requests/Limits + HPA (Bobot: $q_max Poin)"

  if ! oc get deployment hello -n scalling >/dev/null 2>&1; then
    fail "Q13: deployment hello missing in scalling"
    calculate_q_score 0 1 "$q_max"
    return
  fi

  q_total=$((q_total+1))
  if ! oc get hpa -n scalling | grep -qw hello; then
    fail "Q13: HPA for hello not found"
  else
    pass "Q13: HPA for hello exists"; q_pass=$((q_pass+1))
    local min max target
    min="$(oc get hpa hello -n scalling -o jsonpath='{.spec.minReplicas}' 2>/dev/null || true)"
    max="$(oc get hpa hello -n scalling -o jsonpath='{.spec.maxReplicas}' 2>/dev/null || true)"
    target="$(oc get hpa hello -n scalling -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}' 2>/dev/null || true)"

    q_total=$((q_total+1))
    [[ "$min" == "2" ]] && { pass "Q13: HPA minReplicas=2"; q_pass=$((q_pass+1)); } || fail "Q13: HPA minReplicas=$min, expected 2"

    q_total=$((q_total+1))
    [[ "$max" == "5" ]] && { pass "Q13: HPA maxReplicas=5"; q_pass=$((q_pass+1)); } || fail "Q13: HPA maxReplicas=$max, expected 5"

    q_total=$((q_total+1))
    [[ "$target" == "50" ]] && { pass "Q13: HPA CPU target=50%"; q_pass=$((q_pass+1)); } || fail "Q13: HPA CPU target=$target, expected 50"
  fi

  local dep
  dep="$(oc get deployment hello -n scalling -o yaml)"
  q_total=$((q_total+1))
  grep -q 'cpu: 50m' <<<"$dep" && { pass "Q13: CPU limit=50m"; q_pass=$((q_pass+1)); } || fail "Q13: CPU limit=50m missing"

  manual "Q13: deployment does not contain memory 100Mi; verify whether this requirement was intended as a LimitRange/default request"

  calculate_q_score "$q_pass" "$q_total" "$q_max"
}

# Q14 -------------------------------------------------------------------------
check_q14() {
  local q_max=15 q_pass=0 q_total=0
  section "Q14 - Helm Chart (Bobot: $q_max Poin)"

  q_total=$((q_total+1))
  if command -v helm >/dev/null 2>&1; then
    pass "Q14: helm binary available"; q_pass=$((q_pass+1))
  else
    fail "Q14: helm command not found"
    calculate_q_score "$q_pass" "$q_total" "$q_max"
    return
  fi

  q_total=$((q_total+1))
  if helm repo list 2>/dev/null | awk '$1=="ex280-repo"{found=1} END{exit !found}'; then
    pass "Q14: Helm repo ex280-repo exists"; q_pass=$((q_pass+1))
  else
    fail "Q14: Helm repo ex280-repo not found"
  fi

  q_total=$((q_total+1))
  if helm repo list 2>/dev/null | grep -q 'https://charts.bitnami.com/bitnami'; then
    pass "Q14: Bitnami repository configured"; q_pass=$((q_pass+1))
  else
    fail "Q14: Bitnami repository URL not found"
  fi

  q_total=$((q_total+1))
  if helm search repo ex280-repo --versions >/dev/null 2>&1 && [[ -n "$(helm search repo ex280-repo --versions 2>/dev/null | tail -n +2)" ]]; then
    pass "Q14: helm search repo ex280-repo --versions returns chart(s)"; q_pass=$((q_pass+1))
  else
    fail "Q14: helm search repo ex280-repo --versions returned no chart"
  fi

  q_total=$((q_total+1))
  if exists_ns helm; then
    if oc get deployment -n helm --no-headers 2>/dev/null | grep -q .; then
      pass "Q14: deployment exists in project helm"; q_pass=$((q_pass+1))
    else
      fail "Q14: no deployment found in project helm"
    fi
  else
    fail "Q14: project helm missing"
  fi

  calculate_q_score "$q_pass" "$q_total" "$q_max"
}

# Q15 -------------------------------------------------------------------------
check_q15() {
  local q_max=15 q_pass=0 q_total=0
  section "Q15 - CronJob (Bobot: $q_max Poin)"

  if ! oc get cronjob test-cron -n tiger >/dev/null 2>&1; then
    fail "Q15: CronJob test-cron missing in tiger"
    calculate_q_score 0 1 "$q_max"
    return
  fi

  local yaml schedule
  yaml="$(oc get cronjob test-cron -n tiger -o yaml)"
  
  q_total=$((q_total+1)); pass "Q15: CronJob test-cron exists"; q_pass=$((q_pass+1))

  schedule="$(oc get cronjob test-cron -n tiger -o jsonpath='{.spec.schedule}' 2>/dev/null || true)"
  q_total=$((q_total+1))
  if [[ "$schedule" == "5 4 */2 * *" ]]; then
    pass "Q15: schedule is 04:05 every 2 days"; q_pass=$((q_pass+1))
  else
    fail "Q15: schedule is '$schedule' (task expected 04:05 every 2 days)"
  fi

  q_total=$((q_total+1))
  grep -q 'serviceAccountName: ex280-sa' <<<"$yaml" && { pass "Q15: serviceAccountName ex280-sa found"; q_pass=$((q_pass+1)); } || fail "Q15: ex280-sa not configured"

  q_total=$((q_total+1))
  grep -qE 'successfulJobsHistoryLimit: 14' <<<"$yaml" && { pass "Q15: successfulJobsHistoryLimit=14"; q_pass=$((q_pass+1)); } || fail "Q15: successfulJobsHistoryLimit is not 14"

  q_total=$((q_total+1))
  if grep -qE 'image:[[:space:]]*registry\.io/nginx' <<<"$yaml"; then
    pass "Q15: image registry.io/nginx found"; q_pass=$((q_pass+1))
  else
    fail "Q15: image registry.io/nginx not found"
  fi

  calculate_q_score "$q_pass" "$q_total" "$q_max"
}

# Q16 -------------------------------------------------------------------------
check_q16() {
  local q_max=15 q_pass=0 q_total=0
  section "Q16 - NetworkPolicy (Bobot: $q_max Poin)"

  if ! oc get networkpolicy allow-specific -n network-policy >/dev/null 2>&1; then
    fail "Q16: NetworkPolicy allow-specific missing"
    calculate_q_score 0 1 "$q_max"
    return
  fi

  local yaml nspace
  yaml="$(oc get networkpolicy allow-specific -n network-policy -o yaml)"
  nspace="$(oc get ns different-namespace -ojsonpath='{.metadata.labels.network}' 2>/dev/null || true)"
  
  q_total=$((q_total+1)); pass "Q16: allow-specific exists in network-policy"; q_pass=$((q_pass+1))

  q_total=$((q_total+1))
  grep -q 'different-namespace' <<<"$nspace" && { pass "Q16: namespace selector network=different-namespace found"; q_pass=$((q_pass+1)); } || fail "Q16: namespace selector network=different-namespace missing"

  q_total=$((q_total+1))
  grep -q 'env: production' <<<"$yaml" && { pass "Q16: pod selector env=production found"; q_pass=$((q_pass+1)); } || fail "Q16: pod selector env=production missing"

  q_total=$((q_total+1))
  grep -qE 'port: 8080' <<<"$yaml" && { pass "Q16: port 8080 found"; q_pass=$((q_pass+1)); } || fail "Q16: port 8080 missing"

  manual "Q16: verify actual connectivity from different-namespace pod"

  calculate_q_score "$q_pass" "$q_total" "$q_max"
}

# Q17 -------------------------------------------------------------------------
check_q17() {
  local q_max=20 q_pass=0 q_total=0
  section "Q17 - Project Template + LimitRange (Bobot: $q_max Poin)"

  local template cr
  cr="$(oc get projects.config.openshift.io cluster -o jsonpath='{.spec.projectRequestTemplate}' 2>/dev/null || true)"
  
  q_total=$((q_total+1))
  if [[ -n "$cr" ]]; then
    pass "Q17: OpenShift has projectRequestTemplate configured: $cr"; q_pass=$((q_pass+1))
  else
    fail "Q17: projectRequestTemplate is not configured"
  fi

  template="$(oc get template -A 2>/dev/null | grep -E 'template-limitrange|project.*template|template*|*request' | head -1 || true)"
  q_total=$((q_total+1))
  if [[ -n "$template" ]]; then
    pass "Q17: project template resource found"; q_pass=$((q_pass+1))
  else
    fail "Q17: template resource not found"
  fi

  if exists_ns template-limitrange; then
    q_total=$((q_total+1))
    if oc get limitrange -n template-limitrange >/dev/null 2>&1; then
      pass "Q17: LimitRange exists in template-limitrange"; q_pass=$((q_pass+1))
    else
      fail "Q17: no LimitRange in template-limitrange"
    fi
  else
    manual "Q17: namespace template-limitrange is not present"
  fi

  manual "Q17: test create project to confirm automatic LimitRange injection"

  calculate_q_score "$q_pass" "$q_total" "$q_max"
}

# Q18 -------------------------------------------------------------------------
check_q18() {
  local q_max=15 q_pass=0 q_total=0
  section "Q18 - Liveness Probe (Bobot: $q_max Poin)"

  local dep yaml
  dep="$(oc get deployment -n tuesday -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null | head -1 || true)"
  if [[ -z "$dep" ]]; then
    fail "Q18: no Deployment found in tuesday"
    calculate_q_score 0 1 "$q_max"
    return
  fi

  yaml="$(oc get deployment "$dep" -n tuesday -o yaml)"
  
  q_total=$((q_total+1))
  grep -q 'livenessProbe:' <<<"$yaml" && { pass "Q18: livenessProbe configured"; q_pass=$((q_pass+1)); } || fail "Q18: livenessProbe missing"

  q_total=$((q_total+1))
  grep -qE 'port: 8443' <<<"$yaml" && { pass "Q18: liveness probe port=8443"; q_pass=$((q_pass+1)); } || fail "Q18: liveness probe port 8443 missing"

  q_total=$((q_total+1))
  grep -qE 'initialDelaySeconds: 3' <<<"$yaml" && { pass "Q18: initialDelaySeconds=3"; q_pass=$((q_pass+1)); } || fail "Q18: initialDelaySeconds is not 3"

  q_total=$((q_total+1))
  grep -qE 'timeoutSeconds: 10' <<<"$yaml" && { pass "Q18: timeoutSeconds=10"; q_pass=$((q_pass+1)); } || fail "Q18: timeoutSeconds is not 10"

  manual "Q18: observe restartCount after 3 induced failures"

  calculate_q_score "$q_pass" "$q_total" "$q_max"
}

# Q19 -------------------------------------------------------------------------
check_q19() {
  local q_max=10 q_pass=0 q_total=0
  section "Q19 - Cluster Information Tarball (Bobot: $q_max Poin)"

  local cid expected file found=0
  cid="$(oc get clusterversion version -o jsonpath='{.spec.clusterID}' 2>/dev/null || true)"
  expected="student101-${cid}.tar.gz"

  q_total=$((q_total+1))
  for file in "$expected" "./$expected" "/tmp/$expected"; do
    if [[ -f "$file" ]]; then
      pass "Q19: expected tarball found: $file"; q_pass=$((q_pass+1))
      found=1
      break
    fi
  done

  if [[ "$found" -eq 0 ]]; then
    fail "Q19: expected tarball $expected not found in current dir or /tmp"
  fi

  manual "Q19: verify archive transmission to Red Hat Support separately"

  calculate_q_score "$q_pass" "$q_total" "$q_max"
}

# Main ------------------------------------------------------------------------
need_oc

echo "EX280 / DO280 LAB VERIFIER WITH AUTOMATED GRADING"
echo "Authenticated as: $(oc whoami)"
echo "Cluster ID: $(oc get clusterversion version -o jsonpath='{.spec.clusterID}' 2>/dev/null || echo unknown)"
echo "Started: $(date)"
echo

check_q1; pause
check_q2; pause
check_q3; pause
check_q4; pause
check_q5; pause
check_q6; pause
check_q7; pause
check_q8; pause
check_q9; pause
check_q10; pause
check_q11; pause
check_q12; pause
check_q13; pause
check_q14; pause
check_q15; pause
check_q16; pause
check_q17; pause
check_q18; pause
check_q19

echo
echo "============================================================"
echo "SUMMARY & FINAL GRADING"
echo "============================================================"
echo "TOTAL CHECKS PASSED  : $PASS"
echo "TOTAL CHECKS FAILED  : $FAIL"
echo "MANUAL CHECKS REQUIRED: $MANUAL"
echo "------------------------------------------------------------"
echo "FINAL SCORE          : $TOTAL_SCORE / $MAX_TOTAL_SCORE"
echo "PASSING SCORE        : $PASS_THRESHOLD"
echo "============================================================"

if (( TOTAL_SCORE >= PASS_THRESHOLD )); then
  echo "RESULT : PASS / LOLOS (Memenuhi Standar Kelulusan EX280)"
  exit 0
else
  echo "RESULT : FAILED / BELUM LOLOS (Silakan Perbaiki Modul Gagal)"
  exit 1
fi
