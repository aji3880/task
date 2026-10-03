#!/bin/bash
# ==============================================================================
# EX280 EXAM AUTOMATED GRADING SCRIPT
# Total Points: 300 | Passing Score: 210 (70%)
# ==============================================================================

SCORE=0
MAX_SCORE=300
PASSING_SCORE=210

echo -e "\n\033[1;36m====================================================\033[0m"
echo -e "\033[1;36m       STARTING EX280 AUTOMATED EVALUATION          \033[0m"
echo -e "\033[1;36m====================================================\033[0m\n"

# Helper function
check_item() {
    local task_num="$1"
    local desc="$2"
    local points="$3"
    local condition="$4"

    if eval "$condition"; then
        echo -e "[ \033[1;32mPASS\033[0m ] Task $task_num: $desc (+$points pts)"
        SCORE=$((SCORE + points))
    else
        echo -e "[ \033[1;31mFAIL\033[0m ] Task $task_num: $desc (0/$points pts)"
    fi
}

# --- Task 1: Identity Provider (25 pts) ---
T1_COND="oc get oauth cluster -o jsonpath='{.spec.identityProviders[*].name}' 2>/dev/null | grep -q 'ex280-htpasswd' && oc get secret ex280-idp-secret -n openshift-config &>/dev/null"
check_item "1" "Configure HTPasswd Identity Provider and Secret" 25 "$T1_COND"

# --- Task 2: Cluster Permissions & Kubeadmin (20 pts) ---
T2_COND="oc get clusterrolebinding -o jsonpath='{.items[*].subjects[*].name}' 2>/dev/null | grep -q 'jobs' && ! oc get secret kubeadmin -n kube-system &>/dev/null"
check_item "2" "Configure Cluster Permissions & Kubeadmin Absence" 20 "$T2_COND"

# --- Task 3: Project Permissions (15 pts) ---
T3_COND="oc get project apollo manhattan gemini bluebook titan &>/dev/null && oc get rolebindings -n apollo -o jsonpath='{.items[*].subjects[*].name}' | grep -q 'armstrong'"
check_item "3" "Configure Projects and Project Level Permissions" 15 "$T3_COND"

# --- Task 4: Groups (15 pts) ---
T4_COND="oc get group commander pilot &>/dev/null && oc get group commander -o jsonpath='{.users}' | grep -q 'armstrong'"
check_item "4" "Configure User Groups and RoleBindings" 15 "$T4_COND"

# --- Task 5: ResourceQuota (20 pts) ---
T5_COND="oc get resourcequota ex280-quota -n manhattan &>/dev/null"
check_item "5" "Configure ResourceQuota in manhattan" 20 "$T5_COND"

# --- Task 6: LimitRange (20 pts) ---
T6_COND="oc get limitrange ex280-limits -n bluebook &>/dev/null"
check_item "6" "Configure LimitRange in bluebook" 20 "$T6_COND"

# --- Task 7: Deploy Application rocky (15 pts) ---
T7_COND="oc get route rocky -n bullwinkle &>/dev/null && [ \$(oc get pods -n bullwinkle -l app=rocky --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l) -ge 1 ]"
check_item "7" "Deploy Application & Expose Route rocky" 15 "$T7_COND"

# --- Task 8: Manual Scaling (10 pts) ---
T8_COND="[ \$(oc get pods -n gru -l app=minion --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l) -eq 5 ]"
check_item "8" "Scale Application minion to 5 Replicas" 10 "$T8_COND"

# --- Task 9: Autoscaling HPA (20 pts) ---
T9_COND="oc get hpa -n lerna 2>/dev/null | grep -q 'hydra'"
check_item "9" "Configure HPA for hydra in lerna" 20 "$T9_COND"

# --- Task 10: Secure TLS Route (25 pts) ---
T10_COND="oc get route oxcart -n area51 -o jsonpath='{.spec.tls.termination}' 2>/dev/null | grep -E -q 'edge|reencrypt|passthrough'"
check_item "10" "Configure Secure TLS Route oxcart" 25 "$T10_COND"

# --- Task 11: Configure Secret (10 pts) ---
T11_COND="oc get secret magic -n math -o jsonpath='{.data.decoder_ring}' &>/dev/null"
check_item "11" "Create Secret magic in math" 10 "$T11_COND"

# --- Task 12: Inject Secret into Application (15 pts) ---
T12_COND="[ \$(oc get pods -n math -l app=qed --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l) -ge 1 ] && ! oc logs -l app=qed -n math 2>/dev/null | grep -q 'Sorry, application is not configured correctly.'"
check_item "12" "Inject Secret to qed & Verify Running Output" 15 "$T12_COND"

# --- Task 13: Service Account & SCC (20 pts) ---
# --- Task 13: Service Account & SCC (20 pts) ---
T13_COND="oc get sa ex280sa -n apples &>/dev/null && (oc adm policy who-can use scc anyuid -n apples 2>/dev/null | grep ex280sa || oc describe scc anyuid | grep -q 'ex280sa')"
check_item "13" "Create ServiceAccount ex280sa & Grant anyuid SCC" 20 "$T13_COND"

# --- Task 14: Deploy Application with SA (20 pts) ---
T14_COND="[ \$(oc get pods -n apples -l app=oranges --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l) -ge 1 ]"
check_item "14" "Deploy oranges using ex280sa" 20 "$T14_COND"

# --- Task 15: Troubleshoot voyager (25 pts) ---
T15_COND="[ \$(oc get pods -n pathfinder -l app=voyager --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l) -ge 1 ]"
check_item "15" "Troubleshoot & Fix Application voyager" 25 "$T15_COND"

# --- Task 16: Troubleshoot atlas (25 pts) ---
T16_COND="[ \$(oc get pods -n mercury -l app=atlas --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l) -ge 1 ]"
check_item "16" "Troubleshoot & Fix Application atlas" 25 "$T16_COND"

# ==============================================================================
# FINAL SCORE SUMMARY
# ==============================================================================
echo -e "\n\033[1;36m====================================================\033[0m"
echo -e "                 FINAL EVALUATION RESULT            "
echo -e "\033[1;36m====================================================\033[0m"
echo -e "TOTAL SCORE   : \033[1;33m$SCORE\033[0m / $MAX_SCORE"
echo -e "PASSING SCORE : $PASSING_SCORE"

if [ "$SCORE" -ge "$PASSING_SCORE" ]; then
    echo -e "FINAL STATUS  : \033[1;32mPASSED (LULUS)\033[0m 🎉"
else
    echo -e "FINAL STATUS  : \033[1;31mFAILED (BELUM LULUS)\033[0m ❌"
fi
echo -e "\033[1;36m====================================================\033[0m\n"