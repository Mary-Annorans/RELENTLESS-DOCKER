#!/bin/bash

# Portfolio Website - EC2 Deployment Setup Script
# This script helps you set up the complete infrastructure and deployment pipeline

set -e

echo "🚀 Portfolio Website EC2 Deployment Setup"
echo "=========================================="

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    echo "   Visit: https://aws.amazon.com/cli/"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install it first."
    echo "   Visit: https://terraform.io/downloads"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install it first."
    exit 1
fi

echo "✅ All prerequisites are installed!"

# Check AWS credentials
echo "🔐 Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure'"
    exit 1
fi

echo "✅ AWS credentials are configured!"

# Generate SSH key if it doesn't exist
if [ ! -f "terraform/jenkins-key" ]; then
    echo "🔑 Generating SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f terraform/jenkins-key -N "" -q
    echo "✅ SSH key pair generated!"
else
    echo "✅ SSH key pair already exists!"
fi

# Check if Docker image is pushed
echo "🐳 Checking Docker image..."
if ! docker images | grep -q "maryann123456789/mary-ann-portfolio"; then
    echo "⚠️  Docker image not found locally. Make sure to push your image first:"
    echo "   docker push maryann123456789/mary-ann-portfolio:latest"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "✅ Docker image check completed!"

# Deploy infrastructure
echo "🏗️  Deploying infrastructure with Terraform..."
cd terraform

# Initialize Terraform
terraform init

# Plan deployment
echo "📋 Planning deployment..."
terraform plan

# Ask for confirmation
read -p "Deploy infrastructure? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    terraform apply -auto-approve
    
    # Get outputs
    echo ""
    echo "🎉 Infrastructure deployed successfully!"
    echo "=========================================="
    
    JENKINS_IP=$(terraform output -raw jenkins_server_ip)
    JENKINS_URL=$(terraform output -raw jenkins_url)
    PORTFOLIO_URL=$(terraform output -raw portfolio_url)
    
    echo "Jenkins Server IP: $JENKINS_IP"
    echo "Jenkins URL: $JENKINS_URL"
    echo "Portfolio URL: $PORTFOLIO_URL"
    echo ""
    
    # Wait for Jenkins to be ready
    echo "⏳ Waiting for Jenkins to be ready (this may take a few minutes)..."
    
    # Try to connect to Jenkins with retries
    for i in {1..30}; do
        if curl -s http://$JENKINS_IP:8080 > /dev/null 2>&1; then
            echo "✅ Jenkins is ready!"
            break
        fi
        echo "Attempt $i/30: Jenkins not ready yet, waiting 10 seconds..."
        sleep 10
    done
    
    # Get Jenkins initial password
    echo ""
    echo "🔑 Getting Jenkins initial admin password..."
    INITIAL_PASSWORD=$(ssh -i jenkins-key -o StrictHostKeyChecking=no ec2-user@$JENKINS_IP 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword' 2>/dev/null || echo "Could not retrieve password")
    
    echo ""
    echo "🎯 Next Steps:"
    echo "=============="
    echo "1. Access Jenkins: $JENKINS_URL"
    echo "2. Initial admin password: $INITIAL_PASSWORD"
    echo "3. Install suggested plugins"
    echo "4. Create admin user"
    echo "5. Configure credentials:"
    echo "   - SSH Key ID: ec2-ssh-key"
    echo "   - Docker Hub ID: docker-hub-credentials"
    echo "6. Create pipeline job pointing to your repository"
    echo "7. Update EC2_HOST in Jenkinsfile with: $JENKINS_IP"
    echo ""
    echo "📖 For detailed instructions, see DEPLOYMENT.md"
    echo ""
    echo "🔗 Quick links:"
    echo "   Jenkins: $JENKINS_URL"
    echo "   Portfolio: $PORTFOLIO_URL (after deployment)"
    echo ""
    echo "SSH to server: ssh -i terraform/jenkins-key ec2-user@$JENKINS_IP"
    
else
    echo "❌ Deployment cancelled."
    exit 1
fi

cd ..
echo ""
echo "🎉 Setup completed successfully!"
echo "Happy deploying! 🚀"
