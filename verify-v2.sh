#!/bin/bash
# ==============================================================================
# SCRIPT EVALUASI & GRADING EX280 (SKALA 300 POIN - PASS 210)
# ==============================================================================

SCORE=0
TOTAL_MAX_SCORE=300
PASS_SCORE=210

echo "========================================================================"
echo "          MEMULAI EVALUASI UJIAN EX280 (SKALA NILAI MAX 300)"
echo "========================================================================"

# Q1 (10 Poin)
echo -n "Checking Q1 (Project Creation - 10 pts)... "
if oc get ns quart &>/dev/null; then
    echo -e "\e[32m[PASS]\e[0m +10 Poin"
    SCORE=$((SCORE + 10))
else
    echo -e "\e[31m[FAIL]\e[0m 0 Poin"
fi

# Q2 (15 Poin)
echo -n "Checking Q2 (Application Deployment - 15 pts)... "
if oc get deployment todo-http -n quart &>/dev/null; then
    echo -e "\e[32m[PASS]\e[0m +15 Poin"
    SCORE=$((SCORE + 15))
else
    echo -e "\e[31m[FAIL]\e[0m 0 Poin"
fi

# Q3 (10 Poin)
echo -n "Checking Q3 (Environment Variables - 10 pts)... "
ENV_CHECK=$(oc get deployment todo-http -n quart -o jsonpath='{.spec.template.spec.containers[0].env}' 2>/dev/null)
if [ -n "$ENV_CHECK" ]; then
    echo -e "\e[32m[PASS]\e[0m +10 Poin"
    SCORE=$((SCORE + 10))
else
    echo -e "\e[31m[FAIL]\e[0m 0 Poin"
fi

# Q4 (20 Poin)
echo -n "Checking Q4 (TLS Route - 20 pts)... "
if oc get ns quart &>/dev/null; then
    Q4_HOST=$(oc get route todo-http -n quart -o jsonpath='{.spec.host}' 2>/dev/null)
    if [ -n "$Q4_HOST" ]; then
        CERT_SUBJECT=$(echo | openssl s_client -connect "${Q4_HOST}:443" -servername "$Q4_HOST" 2>/dev/null | openssl x509 -noout -subject 2>/dev/null)
        HTTP_CODE=$(curl -s -o /dev/null -k -w "%{http_code}" "https://${Q4_HOST}")
        if [ -n "$CERT_SUBJECT" ] && [ "$HTTP_CODE" -eq 200 ]; then
            echo -e "\e[32m[PASS]\e[0m +20 Poin"
            SCORE=$((SCORE + 20))
        else
            echo -e "\e[31m[FAIL]\e[0m 0 Poin"
        fi
    else
        echo -e "\e[31m[FAIL]\e[0m 0 Poin"
    fi
else
    echo -e "\e[31m[FAIL]\e[0m 0 Poin"
fi

# Q5 (15 Poin)
echo -n "Checking Q5 (App Output in red - 15 pts)... "
if oc get ns red &>/dev/null; then
    RED_POD_STATUS=$(oc get pods -n red -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
    RED_LOGS=$(oc logs deployment/red-app -n red --tail=50 2>/dev/null)
    if [ "$RED_POD_STATUS" == "Running" ] && [ -n "$RED_LOGS" ]; then
        echo -e "\e[32m[PASS]\e[0m +15 Poin"
        SCORE=$((SCORE + 15))
    else
        echo -e "\e[31m[FAIL]\e[0m 0 Poin"
    fi
else
    echo -e "\e[31m[FAIL]\e[0m 0 Poin"
fi

# Q6 (15 Poin)
echo -n "Checking Q6 (ServiceAccount ex280-sa - 15 pts)... "
if oc get sa ex280-sa -n alpha &>/dev/null; then
    echo -e "\e[32m[PASS]\e[0m +15 Poin"
    SCORE=$((SCORE + 15))
else
    echo -e "\e[31m[FAIL]\e[0m 0 Poin"
fi

# Q7 (15 Poin)
echo -n "Checking Q7 (Deployment uses ex280-sa - 15 pts)... "
if oc get ns alpha &>/dev/null; then
    SA_NAME=$(oc get deployment gitlab -n alpha -o jsonpath='{.spec.template.spec.serviceAccountName}' 2>/dev/null)
    if [ "$SA_NAME" == "ex280-sa" ]; then
        echo -e "\e[32m[PASS]\e[0m +15 Poin"
        SCORE=$((SCORE + 15))
    else
        echo -e "\e[31m[FAIL]\e[0m 0 Poin"
    fi
else
    echo -e "\e[31m[FAIL]\e[0m 0 Poin"
fi

# Q8 (15 Poin)
echo -n "Checking Q8 (ConfigMap Usage - 15 pts)... "
if oc get configmap -n alpha &>/dev/null; then
    echo -e "\e[32m[PASS]\e[0m +15 Poin"
    SCORE=$((SCORE + 15))
else
    echo -e "\e[31m[FAIL]\e[0m 0 Poin"
fi

# Q9 (15 Poin)
echo -n "Checking Q9 (Pod consumes ex280-secret - 15 pts)... "
if oc get ns cloud &>/dev/null; then
    SECRET_CONSUMED=$(oc get deployment -n cloud -o yaml 2>/dev/null | grep -i "ex280-secret")
    CLOUD_POD_STATUS=$(oc get pods -n cloud -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
    if [ -n "$SECRET_CONSUMED" ] && [ "$CLOUD_POD_STATUS" == "Running" ]; then
        echo -e "\e[32m[PASS]\e[0m +15 Poin"
        SCORE=$((SCORE + 15))
    else
        echo -e "\e[31m[FAIL]\e[0m 0 Poin"
    fi
else
    echo -e "\e[31m[FAIL]\e[0m 0 Poin"
fi

# Q10 (15 Poin)
echo -n "Checking Q10 (Persistent Volume Claim - 15 pts)... "
if oc get pvc -n cloud &>/dev/null; then
    echo -e "\e[32m[PASS]\e[0m +15 Poin"
    SCORE=$((SCORE + 15))
else
    echo -e "\e[31m[FAIL]\e[0m 0 Poin"
fi

# Q11 (10 Poin)
echo -n "Checking Q11 (Scaling Replicas - 10 pts)... "
REPLICAS=$(oc get deployment -n scalling -o jsonpath='{.items[0].spec.replicas}' 2>/dev/null)
if [ "$REPLICAS" -gt 1 ] 2>/dev/null; then
    echo -e "\e[32m[PASS]\e[0m +10 Poin"
    SCORE=$((SCORE + 10))
else
    echo -e "\e[31m[FAIL]\e[0m 0 Poin"
fi

# Q12 (15 Poin)
echo -n "Checking Q12 (Resource Requests & Limits - 15 pts)... "
RES_CHECK=$(oc get deployment -n scalling -o jsonpath='{.items[0].spec.template.spec.containers[0].resources}' 2>/dev/null)
if [ -n "$RES_CHECK" ]; then
    echo -e "\e[32m[PASS]\e[0m +15 Poin"
    SCORE=$((SCORE + 15))
else
    echo -e "\e[31m[FAIL]\e[0m 0 Poin"
fi

# Q13 (20 Poin)
echo -n "Checking Q13 (Requests/Limits + HPA - 20 pts)... "
if oc get ns scalling &>/dev/null; then
    HPA_MIN=$(oc get hpa hello -n scalling -o jsonpath='{.spec.minReplicas}' 2>/dev/null)
    HPA_MAX=$(oc get hpa hello -n scalling -o jsonpath='{.spec.maxReplicas}' 2>/dev/null)
    MEM_LIMIT=$(oc get deployment hello -n scalling -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null)
    if [ "$HPA_MIN" -eq 2 ] && [ "$HPA_MAX" -eq 5 ] && [ "$MEM_LIMIT" == "100Mi" ]; then
        echo -e "\e[32m[PASS]\e[0m +20 Poin"
        SCORE=$((SCORE + 20))
    else
        echo -e "\e[31m[FAIL]\e[0m 0 Poin"
    fi
else
    echo -e "\e[31m[FAIL]\e[0m 0 Poin"
fi

# Q14 (15 Poin)
echo -n "Checking Q14 (Node Selector - 15 pts)... "
NODE_SEL=$(oc get deployment -n tuesday -o jsonpath='{.items[0].spec.template.spec.nodeSelector}' 2>/dev/null)
if [ -n "$NODE_SEL" ]; then
    echo -e "\e[32m[PASS]\e[0m +15 Poin"
    SCORE=$((SCORE + 15))
else
    echo -e "\e[31m[FAIL]\e[0m 0 Poin"
fi

# Q15 (15 Poin)
echo -n "Checking Q15 (Exposed Service - 15 pts)... "
if oc get route -n network-policy &>/dev/null; then
    echo -e "\e[32m[PASS]\e[0m +15 Poin"
    SCORE=$((SCORE + 15))
else
    echo -e "\e[31m[FAIL]\e[0m 0 Poin"
fi

# Q16 (20 Poin)
echo -n "Checking Q16 (NetworkPolicy Connectivity - 20 pts)... "
if oc get ns network-policy &>/dev/null && oc get ns different-namespace &>/dev/null; then
    TEST_POD=$(oc get pods -n different-namespace -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -n "$TEST_POD" ]; then
        CURL_TEST=$(oc exec "$TEST_POD" -n different-namespace -- curl -s -o /dev/null -w "%{http_code}" -m 3 http://hello.network-policy.svc.cluster.local:8080 2>/dev/null)
        if [ "$CURL_TEST" -eq 200 ]; then
            echo -e "\e[32m[PASS]\e[0m +20 Poin"
            SCORE=$((SCORE + 20))
        else
            echo -e "\e[31m[FAIL]\e[0m 0 Poin"
        fi
    else
        echo -e "\e[31m[FAIL]\e[0m 0 Poin"
    fi
else
    echo -e "\e[31m[FAIL]\e[0m 0 Poin"
fi

# Q17 (20 Poin)
echo -n "Checking Q17 (Project Template + LimitRange - 20 pts)... "
TEMP_PROJECT="test-eval-limitrange-$$"
oc new-project "$TEMP_PROJECT" &>/dev/null
if oc get limitrange -n "$TEMP_PROJECT" 2>/dev/null | grep -q -v "NAME"; then
    echo -e "\e[32m[PASS]\e[0m +20 Poin"
    SCORE=$((SCORE + 20))
else
    echo -e "\e[31m[FAIL]\e[0m 0 Poin"
fi
oc delete project "$TEMP_PROJECT" &>/dev/null

# Q18 (15 Poin)
echo -n "Checking Q18 (Liveness Probe - 15 pts)... "
if oc get ns tuesday &>/dev/null; then
    PROBE_PORT=$(oc get deployment -n tuesday -o jsonpath='{.items[0].spec.template.spec.containers[0].livenessProbe.httpGet.port}' 2>/dev/null)
    PROBE_DELAY=$(oc get deployment -n tuesday -o jsonpath='{.items[0].spec.template.spec.containers[0].livenessProbe.initialDelaySeconds}' 2>/dev/null)
    PROBE_TIMEOUT=$(oc get deployment -n tuesday -o jsonpath='{.items[0].spec.template.spec.containers[0].livenessProbe.timeoutSeconds}' 2>/dev/null)
    if [ "$PROBE_PORT" -eq 8443 ] && [ "$PROBE_DELAY" -eq 3 ] && [ "$PROBE_TIMEOUT" -eq 10 ]; then
        echo -e "\e[32m[PASS]\e[0m +15 Poin"
        SCORE=$((SCORE + 15))
    else
        echo -e "\e[31m[FAIL]\e[0m 0 Poin"
    fi
else
    echo -e "\e[31m[FAIL]\e[0m 0 Poin"
fi

# Q19 (15 Poin)
echo -n "Checking Q19 (Cluster Info Tarball - 15 pts)... "
CLUSTER_ID=$(oc get clusterversion version -o jsonpath='{.spec.clusterID}' 2>/dev/null)
TARBALL_FILE=$(find /tmp /root . -maxdepth 2 -name "student101-${CLUSTER_ID}.tar.gz" 2>/dev/null | head -n 1)
if [ -n "$TARBALL_FILE" ] && [ -f "$TARBALL_FILE" ]; then
    if tar -ztvf "$TARBALL_FILE" &>/dev/null; then
        echo -e "\e[32m[PASS]\e[0m +15 Poin"
        SCORE=$((SCORE + 15))
    else
        echo -e "\e[31m[FAIL]\e[0m 0 Poin"
    fi
else
    echo -e "\e[31m[FAIL]\e[0m 0 Poin"
fi

# --- SUMMARY EVALUASI ---
echo "========================================================================"
echo "                   RINGKASAN SKOR EVALUASI UJIAN"
echo "========================================================================"
echo "Total Skor Diperoleh : $SCORE / $TOTAL_MAX_SCORE Poin"
PERCENTAGE=$(( SCORE * 100 / TOTAL_MAX_SCORE ))
echo "Persentase Nilai     : $PERCENTAGE%"

if [ "$SCORE" -ge "$PASS_SCORE" ]; then
    echo -e "\e[32mSTATUS: LULUS (PASSED - Skor >= 210)\e[0m"
else
    echo -e "\e[31mSTATUS: TIDAK LULUS (FAILED - Skor < 210)\e[0m"
fi
echo "========================================================================"
