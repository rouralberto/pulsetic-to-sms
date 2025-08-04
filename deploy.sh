#!/bin/bash

# Deployment script for Pulsetic to SMS Lambda function

set -e

echo "🚀 Deploying Pulsetic to SMS Lambda function..."

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ Error: terraform.tfvars not found!"
    echo "Please copy terraform.tfvars.example to terraform.tfvars and fill in your values."
    exit 1
fi

# Install Node.js dependencies
echo "📦 Installing Node.js dependencies..."
npm install

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan the deployment
echo "📋 Planning Terraform deployment..."
terraform plan

# Apply the deployment
echo "🚀 Applying Terraform deployment..."
terraform apply -auto-approve

# Get the function URL
echo "✅ Deployment complete!"
echo ""
echo "Lambda Function URL:"
terraform output -raw lambda_function_url
echo ""
echo "Configure this URL in your Pulsetic webhook settings."
