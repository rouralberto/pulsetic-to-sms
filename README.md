# Pulsetic to SMS
AWS Lambda function that receives Pulsetic alerts and sends SMS notifications via Twilio.

## Overview
This project creates an AWS Lambda function with a public function URL that can receive webhook notifications from Pulsetic monitoring service. When an alert is received, it automatically sends an SMS notification using Twilio.

## Features
- 🚨 Receives Pulsetic webhook alerts
- 📱 Sends SMS notifications via Twilio
- ☁️ Serverless AWS Lambda deployment
- 🔧 Infrastructure as Code with Terraform
- 🌐 Public function URL (no API Gateway needed)

## Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform installed (>= 1.0)
- Node.js and npm installed
- Twilio account with phone number

## Setup
1. **Clone and navigate to the project:**
   ```bash
   cd pulsetic-to-sms
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Configure Twilio and AWS settings:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

   Edit `terraform.tfvars` with your actual values:
   - `twilio_account_sid`: Your Twilio Account SID
   - `twilio_auth_token`: Your Twilio Auth Token
   - `twilio_from_number`: Your Twilio phone number
   - `to_number`: Phone number to receive alerts

4. **Deploy the infrastructure:**
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

5. **Configure Pulsetic webhook:**
   - Copy the Lambda Function URL from the deployment output
   - Add it as a [webhook URL in your Pulsetic dashboard](https://app.pulsetic.com/account/general-alerts/webhook)

## Usage
Once deployed, the Lambda function will automatically:

1. Receive POST requests from Pulsetic with alert data
2. Parse the alert information (title, description, status)
3. Send an SMS notification to the configured phone number
4. Return a success/error response to Pulsetic

### Expected Pulsetic Payload
The function expects Pulsetic alerts in this format:

```json
{
  "embeds": [
    {
      "title": "Pulsetic notification",
      "description": "<url> became online! \n It was down for <downtime> \n For more information visit <url>",
      "color": "7506394"
    }
  ]
}
```

## Architecture
- **AWS Lambda**: Serverless function to process webhooks
- **Lambda Function URL**: Direct HTTP endpoint (no API Gateway needed)
- **Twilio**: SMS service provider
- **Terraform**: Infrastructure as Code for deployment

## Environment Variables
The Lambda function uses these environment variables (set via Terraform):
- `TWILIO_ACCOUNT_SID`: Twilio Account SID
- `TWILIO_AUTH_TOKEN`: Twilio Auth Token
- `TWILIO_FROM_NUMBER`: Twilio phone number to send from
- `TO_NUMBER`: Phone number to receive notifications

## Monitoring
CloudWatch logs are automatically created for the Lambda function at:
`/aws/lambda/pulsetic-to-sms`

## Cleanup
To destroy all resources:

```bash
terraform destroy
```

## Security Notes
- The function URL is public but only accepts POST requests
- Twilio credentials are stored as environment variables
- CloudWatch logs retention is set to 14 days
- All sensitive variables are marked as sensitive in Terraform

## Cost
This solution uses AWS Lambda's free tier (1M requests/month) and minimal CloudWatch logging. Costs are primarily from:
- Lambda execution time (very minimal)
- Twilio SMS charges
- Minimal CloudWatch storage

