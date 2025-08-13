#!/bin/bash
# Set up Amazon EKS cluster (optional)

set -e

CLUSTER_NAME="my-webapp-cluster"
REGION="us-east-1"
NODE_GROUP_NAME="my-webapp-nodes"

# Check for AWS CLI
if ! command -v aws &> /dev/null; then
  echo "Error: AWS CLI is not installed. Please install it and configure your credentials."
  exit 1
fi

# Check for kubectl
if ! command -v kubectl &> /dev/null; then
  echo "Error: kubectl is not installed. Please install it before running this script."
  exit 1
fi

echo "Setting up EKS cluster: $CLUSTER_NAME in $REGION"

# Check if eksctl is installed
if ! command -v eksctl &> /dev/null; then
    echo "Installing eksctl..."
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
fi

# Create EKS cluster
echo "Creating EKS cluster (this takes 15-20 minutes)..."

# Check if the cluster already exists
if eksctl get cluster --region "$REGION" | grep -qw "$CLUSTER_NAME"; then
  echo "EKS cluster '$CLUSTER_NAME' already exists in region '$REGION'."
  echo "If you want to recreate it, delete it first:"
  echo "  eksctl delete cluster --name $CLUSTER_NAME --region $REGION"
  exit 1
fi

eksctl create cluster \
    --name $CLUSTER_NAME \
    --region $REGION \
    --node-type t3.medium \
    --nodes 2 \
    --nodes-min 1 \
    --nodes-max 4 \
    --managed

echo "EKS cluster created successfully!"
echo "Updating kubeconfig..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

echo "Testing cluster connection..."
kubectl get nodes

echo ""
echo "🎉 EKS cluster is ready!"
echo "Use 'kubectl apply -f k8s/app.yaml' to deploy your app"
echo ""
echo "To delete the cluster later:"
echo "eksctl delete cluster --name $CLUSTER_NAME --region $REGION"

echo ""
echo "Next steps:"
echo "1. Create an ECR repository:"
echo "   aws ecr create-repository --repository-name <your-repo-name> --region $REGION"
echo "2. Build, tag, and push your Docker image to ECR (see README for details)."
echo "3. Update k8s/app.yaml with your ECR image URL."
echo "4. Deploy your app:"
echo "   kubectl apply -f k8s/app.yaml"
echo ""