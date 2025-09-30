# Portfolio Website - EC2 Deployment Guide

This guide will help you deploy your portfolio website to AWS EC2 using Jenkins CI/CD pipeline.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed locally
- SSH key pair for EC2 access
- Docker Hub account with your image pushed

## Step 1: Generate SSH Key Pair

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f jenkins-key -N ""

# This creates:
# - jenkins-key (private key)
# - jenkins-key.pub (public key)
```

## Step 2: Deploy Infrastructure with Terraform

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the infrastructure
terraform apply
```

This will create:
- EC2 instance (t3.medium) with Jenkins pre-installed
- Security groups with required ports
- IAM roles and policies
- Elastic IP for the instance

## Step 3: Access Jenkins

After Terraform completes:

1. **Get Jenkins URL and initial password:**
   ```bash
   # SSH into the EC2 instance
   ssh -i jenkins-key ec2-user@<EC2_PUBLIC_IP>
   
   # Run welcome script
   ./welcome.sh
   
   # Get Jenkins initial admin password
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

2. **Access Jenkins Web Interface:**
   - URL: `http://<EC2_PUBLIC_IP>:8080`
   - Use the initial admin password from step above

## Step 4: Configure Jenkins

1. **Install Suggested Plugins** during initial setup
2. **Create Admin User** with your credentials
3. **Configure SSH Credentials:**
   - Go to `Manage Jenkins` → `Manage Credentials`
   - Add new credentials:
     - Kind: `SSH Username with private key`
     - ID: `ec2-ssh-key`
     - Username: `ec2-user`
     - Private Key: Upload your `jenkins-key` file

4. **Configure Docker Hub Credentials:**
   - Add Docker Hub credentials for pushing images
   - ID: `docker-hub-credentials`

## Step 5: Create Jenkins Pipeline

1. **Create New Item:**
   - Choose `Pipeline`
   - Name: `portfolio-pipeline`

2. **Configure Pipeline:**
   - Pipeline script from SCM
   - SCM: Git
   - Repository URL: Your GitHub repository
   - Credentials: Add your GitHub credentials
   - Branch: `*/main` (or your default branch)
   - Script Path: `Jenkinsfile`

3. **Update Jenkinsfile Environment Variables:**
   - Replace `your-ec2-public-ip` with your actual EC2 public IP
   - Ensure `DOCKER_REGISTRY` is set to `maryann123456789`

## Step 6: Run the Pipeline

1. **Trigger Pipeline:**
   - Click `Build Now` on your pipeline
   - Or push changes to your repository to trigger automatic builds

2. **Monitor Deployment:**
   - Watch the pipeline progress in Jenkins console
   - Check EC2 instance for running containers:
     ```bash
     ssh -i jenkins-key ec2-user@<EC2_PUBLIC_IP>
     docker ps
     ```

## Step 7: Access Your Portfolio

Once deployment completes:
- **Portfolio URL:** `http://<EC2_PUBLIC_IP>`
- **Jenkins URL:** `http://<EC2_PUBLIC_IP>:8080`

## Pipeline Stages

The Jenkins pipeline includes:

1. **Checkout** - Gets source code from repository
2. **Validate Dockerfile** - Ensures Dockerfile syntax is correct
3. **Build Docker Image** - Builds the portfolio container
4. **Test Docker Image** - Tests container startup and HTTP response
5. **Security Scan** - Placeholder for security scanning
6. **Push to Registry** - Pushes to Docker Hub (main/master branches)
7. **Deploy to EC2 Production** - Deploys to EC2 instance (main/master branches)

## Troubleshooting

### Common Issues:

1. **SSH Connection Failed:**
   ```bash
   # Check security group allows SSH (port 22)
   # Verify SSH key permissions
   chmod 600 jenkins-key
   ```

2. **Docker Permission Denied:**
   ```bash
   # On EC2 instance, add jenkins user to docker group
   sudo usermod -a -G docker jenkins
   sudo systemctl restart jenkins
   ```

3. **Portfolio Not Accessible:**
   ```bash
   # Check if container is running
   docker ps
   
   # Check container logs
   docker logs portfolio-website
   
   # Verify security group allows HTTP (port 80)
   ```

### Useful Commands:

```bash
# Check Jenkins status
sudo systemctl status jenkins

# View Jenkins logs
sudo journalctl -u jenkins -f

# Restart Jenkins
sudo systemctl restart jenkins

# Manual deployment
sudo /opt/portfolio-deployment/deploy.sh

# Check portfolio container
docker ps | grep portfolio-website
docker logs portfolio-website
```

## Cleanup

To destroy the infrastructure:

```bash
cd terraform
terraform destroy
```

## Security Notes

- The current setup opens ports 22, 80, 443, and 8080 to all IPs (0.0.0.0/0)
- For production, consider restricting access to specific IP ranges
- Enable HTTPS with SSL certificates for secure communication
- Regularly update Jenkins and Docker images for security patches

## Next Steps

- Set up GitHub webhooks for automatic builds
- Configure SSL certificates with Let's Encrypt
- Set up monitoring and logging
- Implement blue-green deployments
- Add automated testing stages
