# UC Davis Library Domain Redirect Service

A simple Express.js web application that handles domain redirections for retired domains. The service reads from a configuration file to map old domains to new URLs and performs 301 (permanent) redirects.

## Adding a Redirect

## Configure App and Redeploy
Add your redirect to the `redirects.json` file:

```json
{
  "old-domain.example.com": "https://new-domain.example.com",
  "legacy-site.example.com": "https://main-site.example.com/legacy"
}
```

Next, redeploy the container:  `./deploy.sh`

## Map the domain in Cloud Run and Update DNS
1. In Google Cloud Console, go to the `Networking` tab in the service details
2. Click `Manage` next to `Custom Domains` in the `Endpoints` panel
3. Select the `ucdlib-domain-redirect-service` service, and either verify a new domain or selected a verified domain. If you are verifying a new domain, follow the onscreen instructions and send the verification code to James to add to the DNS record.
4. Send James the DNS record

## Features

- **Simple Configuration**: Uses a JSON file to map domains to redirect URLs
- **Health Checks**: Built-in health check endpoint for monitoring
- **Docker Support**: Ready for containerization and cloud deployment
- **Google Cloud Run Ready**: Optimized for Google Cloud Run deployment
- **Logging**: Request logging for monitoring and debugging

## Local Development

### Prerequisites
- Node.js 18+ 
- npm

### Setup
```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Or start production server
npm start
```

The service will be available at `http://localhost:3000`

### Testing
You can test redirects by modifying your `/etc/hosts` file to point test domains to localhost:
```
127.0.0.1 old-library-site.ucdavis.edu
```

Then visit `http://old-library-site.ucdavis.edu:3000` in your browser.

## API Endpoints

### Health Check
- **GET** `/health` - Returns service health status

### Redirect Handler
- **ALL** `/*` - Handles all other requests and performs redirects based on hostname

## Docker

### Build Image
```bash
docker build -t ucdlib-domain-redirect-service .
```

### Run Container
```bash
docker run -p 3000:3000 ucdlib-domain-redirect-service
```

### Run with Custom Redirects File
```bash
docker run -p 3000:3000 -v /path/to/your/redirects.json:/app/redirects.json ucdlib-domain-redirect-service
```

## Google Cloud Run Deployment

### Prerequisites
- Google Cloud SDK installed and configured
- A Google Cloud project with required APIs enabled
- Artifact Registry repository created

### Deployment Steps

1. **Deploy using the automated script:**
```bash
./deploy.sh [PROJECT_ID] [REGION]
```

The script will automatically:
- Enable required Google Cloud APIs (Cloud Build, Artifact Registry, Cloud Run)
- Build the Docker image using Google Cloud Build
- Push to Artifact Registry: `us-west1-docker.pkg.dev/digital-ucdavis-edu/pub`
- Deploy to Cloud Run

2. **Manual deployment (if needed):**
```bash
# Enable APIs
gcloud services enable cloudbuild.googleapis.com artifactregistry.googleapis.com run.googleapis.com

# Build and push using Cloud Build
gcloud builds submit --config cloudbuild.yaml --substitutions _IMAGE_NAME=us-west1-docker.pkg.dev/digital-ucdavis-edu/pub/ucdlib-domain-redirect-service .

# Deploy to Cloud Run
gcloud run deploy ucdlib-domain-redirect-service \
  --image us-west1-docker.pkg.dev/digital-ucdavis-edu/pub/ucdlib-domain-redirect-service \
  --platform managed \
  --region us-west1 \
  --allow-unauthenticated
```

3. **Custom Domain Setup:**
   - In the Google Cloud Console, go to Cloud Run
   - Select your service
   - Go to the "Manage Custom Domains" tab
   - Add your retired domains and point their DNS to the Cloud Run service

### Environment Variables

You can set environment variables in Cloud Run:

- `PORT` - Port to run the service (default: 3000, Cloud Run sets this automatically)
- `REDIRECTS_FILE` - Path to redirects configuration file (default: ./redirects.json)

### Updating Redirects

To update redirects in production:

1. Update your `redirects.json` file
2. Rebuild and redeploy the container, OR
3. Use the `/admin/reload` endpoint if you've mounted the file as a volume

## Security Considerations

- The admin endpoints (`/admin/*`) should be protected in production
- Consider implementing authentication for admin endpoints
- Use HTTPS in production (Cloud Run provides this automatically)
- Regular monitoring of redirect logs for abuse

## Monitoring

The service provides structured logging and health checks suitable for:
- Google Cloud Monitoring
- Application performance monitoring tools
- Log aggregation services

## License

MIT License
