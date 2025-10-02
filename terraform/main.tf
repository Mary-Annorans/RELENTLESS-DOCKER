provider "aws" {
  region = "us-east-1" # Change this to your preferred AWS region
}

# Security Group for Jenkins & Docker
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "Allow SSH, Jenkins, and Docker access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH (Change for security)
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow Jenkins Web UI access
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # HTTP access for GitHub Webhook
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance for Jenkins and Docker
resource "aws_instance" "jenkins_server" {
  ami           = "ami-0360c520857e3138f"  # Latest Ubuntu 22.04 LTS AMI
  instance_type = "t3.micro"
  key_name      = "Datadog-kp"  # Using existing AWS Key Pair
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt upgrade -y

    # Install Java, Git, and Docker
    sudo apt install -y openjdk-17-jdk git docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ubuntu

    # Install Jenkins
    wget -O - https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee \
        /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
        /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt update -y
    sudo apt install -y jenkins
    sudo systemctl start jenkins
    sudo systemctl enable jenkins

    # Clone your GitHub repository containing Jenkinsfile and Dockerfile
    cd /var/lib/jenkins
    git clone https://github.com/Mary-Annorans/RELENTLESS-DOCKER.git project

    # Change ownership to Jenkins
    sudo chown -R jenkins:jenkins /var/lib/jenkins/project

    # Restart Jenkins to detect the new job
    sudo systemctl restart jenkins
  EOF

  tags = {
    Name = "JenkinsDockerServer"
  }
}
