#!/bin/bash

set -e

# ============================================
# Certificate Testing Script
# ============================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

NAMESPACE=${1:-default}
ISSUER=${2:-dev-ca-issuer}

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Certificate Creation Test${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  • Namespace: ${NAMESPACE}"
echo "  • Issuer:    ${ISSUER}"
echo ""

# Check if issuer exists
if ! kubectl get clusterissuer ${ISSUER} &> /dev/null; then
    echo -e "${RED}Error: ClusterIssuer '${ISSUER}' not found!${NC}"
    echo ""
    echo "Available ClusterIssuers:"
    kubectl get clusterissuer
    exit 1
fi

# Check if namespace exists
if ! kubectl get namespace ${NAMESPACE} &> /dev/null; then
    echo -e "${YELLOW}Creating namespace ${NAMESPACE}...${NC}"
    kubectl create namespace ${NAMESPACE}
fi

# Generate unique name
TIMESTAMP=$(date +%s)
CERT_NAME="test-cert-${TIMESTAMP}"
SECRET_NAME="test-tls-${TIMESTAMP}"

echo -e "${GREEN}Creating test certificate...${NC}"
echo "  • Name:   ${CERT_NAME}"
echo "  • Secret: ${SECRET_NAME}"
echo ""

# Create test certificate
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${CERT_NAME}
  namespace: ${NAMESPACE}
  labels:
    test: "true"
    created-by: test-script
spec:
  secretName: ${SECRET_NAME}
  issuerRef:
    name: ${ISSUER}
    kind: ClusterIssuer
  dnsNames:
  - test-${TIMESTAMP}.example.local
  - "*.test-${TIMESTAMP}.example.local"
  duration: 2160h  # 90 days
  renewBefore: 360h  # 15 days
  privateKey:
    algorithm: RSA
    size: 2048
  usages:
  - digital signature
  - key encipherment
  - server auth
  - client auth
EOF

echo ""
echo -e "${YELLOW}Waiting for certificate to be ready (timeout: 60s)...${NC}"
echo ""

# Wait for certificate
if kubectl wait --for=condition=ready certificate/${CERT_NAME} -n ${NAMESPACE} --timeout=60s; then
    echo ""
    echo -e "${GREEN}✓ Certificate created successfully!${NC}"
else
    echo ""
    echo -e "${RED}✗ Certificate creation failed or timed out${NC}"
    echo ""
    echo "Checking certificate status..."
    kubectl describe certificate ${CERT_NAME} -n ${NAMESPACE}
    exit 1
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Certificate Details${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

kubectl get certificate ${CERT_NAME} -n ${NAMESPACE} -o wide

echo ""
echo -e "${YELLOW}Certificate Description:${NC}"
kubectl describe certificate ${CERT_NAME} -n ${NAMESPACE}

echo ""
echo -e "${YELLOW}Secret Details:${NC}"
kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o yaml

echo ""
echo -e "${YELLOW}Certificate Content (Base64 decoded):${NC}"
kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout | head -30

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Test Completed Successfully!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Cleanup commands:${NC}"
echo "  kubectl delete certificate ${CERT_NAME} -n ${NAMESPACE}"
echo "  kubectl delete secret ${SECRET_NAME} -n ${NAMESPACE}"
echo ""
