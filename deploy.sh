#!/bin/bash

# Google Cloud Run Deployment Script for UC Davis Library Domain Redirect Service
# Usage: ./deploy.sh [PROJECT_ID] [REGION]

set -e  # Exit on any error

# Configuration
PROJECT_ID=${1:-"digital-ucdavis-edu"}
REGION=${2:-"us-west1"}
SERVICE_NAME="ucdlib-domain-redirect-service"
ARTIFACT_REGISTRY="us-west1-docker.pkg.dev/digital-ucdavis-edu/pub"
IMAGE_NAME="$ARTIFACT_REGISTRY/$SERVICE_NAME"

echo "🚀 Deploying UC Davis Library Domain Redirect Service to Google Cloud Run"
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Service Name: $SERVICE_NAME"
echo "Image: $IMAGE_NAME"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ Error: gcloud CLI is not installed or not in PATH"
    echo "Please install the Google Cloud SDK: https://cloud.google.com/sdk/docs/install"
    exit 1
fi


# Build and push using Cloud Build
echo "🏗️  Building and pushing image using Google Cloud Build..."
echo "📦 Target image: $IMAGE_NAME"
gcloud builds submit \
  --project $PROJECT_ID \
  --config cloudbuild.yaml \
  --substitutions _IMAGE_NAME=$IMAGE_NAME .

# Deploy to Cloud Run
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
    --image $IMAGE_NAME \
    --project $PROJECT_ID \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --port 3000 \
    --memory 512Mi \
    --cpu 1 \
    --max-instances 10 \
    --set-env-vars "NODE_ENV=production" \
    --timeout 300

# Get the service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format 'value(status.url)')

echo ""
echo "✅ Deployment successful!"
echo "🌐 Service URL: $SERVICE_URL"
echo "🔍 Health Check: $SERVICE_URL/health"
echo ""
echo "📝 Next steps:"
echo "1. Test the health check: curl $SERVICE_URL/health"
echo "2. Configure your domain DNS to point to the Cloud Run service"
echo "3. Set up custom domains in the Google Cloud Console"
echo "4. Update the redirects.json file and redeploy as needed"
echo ""
echo "📊 To view logs: gcloud logs tail /projects/$PROJECT_ID/logs/run.googleapis.com%2Fstdout --format=json"
echo "📈 To view in Cloud Console: https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME/metrics?project=$PROJECT_ID"
echo "🏗️  To view builds: https://console.cloud.google.com/cloud-build/builds?project=$PROJECT_ID"
echo "📦 To view images: https://console.cloud.google.com/artifacts/docker/$PROJECT_ID/us-west1/pub?project=$PROJECT_ID"
