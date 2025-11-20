#!/bin/bash

# ============================================
# Cert-Manager Status Check Script
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

NAMESPACE="cert-manager"

# Functions
log_section() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
}

check_mark() {
    echo -e "${GREEN}✓${NC}"
}

cross_mark() {
    echo -e "${RED}✗${NC}"
}

warning_mark() {
    echo -e "${YELLOW}⚠${NC}"
}

# Main checks
main() {
    clear
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        CERT-MANAGER STATUS CHECK REPORT              ║${NC}"
    echo -e "${BLUE}║        $(date +'%Y-%m-%d %H:%M:%S')                           ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
    
    # 1. Check namespace
    log_section "1️⃣  NAMESPACE CHECK"
    if kubectl get namespace ${NAMESPACE} &> /dev/null; then
        echo -e "$(check_mark) Namespace '${NAMESPACE}' exists"
        kubectl get namespace ${NAMESPACE} -o wide
    else
        echo -e "$(cross_mark) Namespace '${NAMESPACE}' NOT FOUND!"
        return 1
    fi
    
    # 2. Check Helm release
    log_section "2️⃣  HELM RELEASE"
    if helm list -n ${NAMESPACE} | grep -q cert-manager; then
        echo -e "$(check_mark) Helm release found"
        helm list -n ${NAMESPACE}
    else
        echo -e "$(cross_mark) Helm release NOT FOUND!"
    fi
    
    # 3. Check pods
    log_section "3️⃣  PODS STATUS"
    kubectl get pods -n ${NAMESPACE} -o wide
    echo ""
    
    # Count ready pods
    TOTAL_PODS=$(kubectl get pods -n ${NAMESPACE} --no-headers 2>/dev/null | wc -l)
    READY_PODS=$(kubectl get pods -n ${NAMESPACE} --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    
    if [ "$TOTAL_PODS" -eq "$READY_PODS" ] && [ "$TOTAL_PODS" -gt 0 ]; then
        echo -e "$(check_mark) All pods running: ${READY_PODS}/${TOTAL_PODS}"
    else
        echo -e "$(warning_mark) Pods status: ${READY_PODS}/${TOTAL_PODS} running"
    fi
    
    # 4. Check CRDs
    log_section "4️⃣  CUSTOM RESOURCE DEFINITIONS (CRDs)"
    CRDS=(
        "certificates.cert-manager.io"
        "certificaterequests.cert-manager.io"
        "challenges.acme.cert-manager.io"
        "clusterissuers.cert-manager.io"
        "issuers.cert-manager.io"
        "orders.acme.cert-manager.io"
    )
    
    CRD_COUNT=0
    for crd in "${CRDS[@]}"; do
        if kubectl get crd "$crd" &> /dev/null; then
            echo -e "$(check_mark) $crd"
            ((CRD_COUNT++))
        else
            echo -e "$(cross_mark) $crd NOT FOUND"
        fi
    done
    echo ""
    echo -e "CRDs installed: ${CRD_COUNT}/${#CRDS[@]}"
    
    # 5. Check ClusterIssuers
    log_section "5️⃣  CLUSTERISSUERS"
    if kubectl get clusterissuer &> /dev/null; then
        kubectl get clusterissuer -o wide
        echo ""
        
        # Check each issuer status
        ISSUERS=$(kubectl get clusterissuer -o jsonpath='{.items[*].metadata.name}')
        for issuer in $ISSUERS; do
            STATUS=$(kubectl get clusterissuer $issuer -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
            REASON=$(kubectl get clusterissuer $issuer -o jsonpath='{.status.conditions[0].reason}' 2>/dev/null)
            
            if [ "$STATUS" == "True" ]; then
                echo -e "$(check_mark) ${issuer}: ${GREEN}Ready${NC}"
            else
                echo -e "$(warning_mark) ${issuer}: ${YELLOW}${REASON}${NC}"
            fi
        done
    else
        echo -e "$(cross_mark) No ClusterIssuers found"
    fi
    
    # 6. Check Certificates
    log_section "6️⃣  CERTIFICATES"
    CERT_COUNT=$(kubectl get certificate -n ${NAMESPACE} --no-headers 2>/dev/null | wc -l)
    
    if [ "$CERT_COUNT" -gt 0 ]; then
        kubectl get certificate -n ${NAMESPACE} -o wide
        echo ""
        
        # Check CA certificates
        echo "CA Certificates status:"
        for cert in "dev-root-ca" "dev-intermediate-ca"; do
            if kubectl get certificate $cert -n ${NAMESPACE} &> /dev/null; then
                STATUS=$(kubectl get certificate $cert -n ${NAMESPACE} -o jsonpath='{.status.conditions[0].status}')
                if [ "$STATUS" == "True" ]; then
                    echo -e "  $(check_mark) ${cert}: ${GREEN}Ready${NC}"
                else
                    echo -e "  $(warning_mark) ${cert}: ${YELLOW}Not Ready${NC}"
                fi
            fi
        done
    else
        echo -e "$(warning_mark) No certificates found in ${NAMESPACE} namespace"
        echo "  This is normal if ClusterIssuers were just created."
    fi
    
    # 7. Check all certificates in cluster
    log_section "7️⃣  ALL CERTIFICATES (Cluster-wide)"
    ALL_CERTS=$(kubectl get certificate -A --no-headers 2>/dev/null | wc -l)
    if [ "$ALL_CERTS" -gt 0 ]; then
        kubectl get certificate -A -o wide
    else
        echo "No certificates found in any namespace"
    fi
    
    # 8. Check PVCs
    log_section "8️⃣  PERSISTENT VOLUME CLAIMS"
    kubectl get pvc -n ${NAMESPACE} -o wide
    echo ""
    
    # Check PVC status
    for pvc in "cert-manager-storage" "cert-manager-backup"; do
        if kubectl get pvc $pvc -n ${NAMESPACE} &> /dev/null; then
            STATUS=$(kubectl get pvc $pvc -n ${NAMESPACE} -o jsonpath='{.status.phase}')
            if [ "$STATUS" == "Bound" ]; then
                echo -e "$(check_mark) ${pvc}: ${GREEN}Bound${NC}"
            else
                echo -e "$(warning_mark) ${pvc}: ${YELLOW}${STATUS}${NC}"
            fi
        else
            echo -e "$(cross_mark) ${pvc}: Not found"
        fi
    done
    
    # 9. Check Secrets
    log_section "9️⃣  TLS SECRETS"
    SECRET_COUNT=$(kubectl get secrets -A -l controller.cert-manager.io/fao=true --no-headers 2>/dev/null | wc -l)
    if [ "$SECRET_COUNT" -gt 0 ]; then
        kubectl get secrets -A -l controller.cert-manager.io/fao=true -o wide
    else
        echo "No TLS secrets managed by cert-manager found yet"
    fi
    
    # 10. Check Services
    log_section "🔟 SERVICES"
    kubectl get svc -n ${NAMESPACE} -o wide
    
    # 11. Check Recent Events
    log_section "1️⃣1️⃣  RECENT EVENTS (Last 10)"
    kubectl get events -n ${NAMESPACE} --sort-by='.lastTimestamp' | tail -10
    
    # 12. Check CertificateRequests
    log_section "1️⃣2️⃣  CERTIFICATE REQUESTS"
    CERT_REQ_COUNT=$(kubectl get certificaterequest -A --no-headers 2>/dev/null | wc -l)
    if [ "$CERT_REQ_COUNT" -gt 0 ]; then
        kubectl get certificaterequest -A -o wide
    else
        echo "No certificate requests found"
    fi
    
    # 13. Check Challenges (ACME)
    log_section "1️⃣3️⃣  ACME CHALLENGES"
    CHALLENGE_COUNT=$(kubectl get challenge -A --no-headers 2>/dev/null | wc -l)
    if [ "$CHALLENGE_COUNT" -gt 0 ]; then
        kubectl get challenge -A -o wide
        echo ""
        echo -e "${YELLOW}Note: Active challenges indicate Let's Encrypt validation in progress${NC}"
    else
        echo "No active ACME challenges"
    fi
    
    # 14. Resource Usage
    log_section "1️⃣4️⃣  RESOURCE USAGE"
    kubectl top pods -n ${NAMESPACE} 2>/dev/null || echo "Metrics server not available or pods not ready"
    
    # 15. Controller Logs Preview
    log_section "1️⃣5️⃣  CONTROLLER LOGS (Last 10 lines)"
    kubectl logs -n ${NAMESPACE} deployment/cert-manager --tail=10 2>/dev/null || echo "Cannot retrieve logs"
    
    # Summary
    log_section "📊 SUMMARY"
    
    echo "Component Status:"
    echo "  • Namespace:        $([ $(kubectl get namespace ${NAMESPACE} &>/dev/null; echo $?) -eq 0 ] && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}")"
    echo "  • Helm Release:     $([ $(helm list -n ${NAMESPACE} | grep -q cert-manager; echo $?) -eq 0 ] && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}")"
    echo "  • Pods Running:     ${READY_PODS}/${TOTAL_PODS}"
    echo "  • CRDs Installed:   ${CRD_COUNT}/${#CRDS[@]}"
    echo "  • ClusterIssuers:   $(kubectl get clusterissuer --no-headers 2>/dev/null | wc -l)"
    echo "  • Certificates:     ${CERT_COUNT} (in ${NAMESPACE})"
    echo "  • All Certificates: ${ALL_CERTS} (cluster-wide)"
    echo "  • TLS Secrets:      ${SECRET_COUNT}"
    
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Check completed at $(date +'%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo ""
}

main
