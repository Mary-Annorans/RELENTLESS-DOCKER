pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'mary-ann-portfolio'
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKER_REGISTRY = 'maryann123456789'
        CONTAINER_NAME = 'portfolio-website'
        EC2_HOST = 'your-ec2-public-ip' // Replace with your EC2 public IP
        SSH_KEY = credentials('ec2-ssh-key')
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }
        
        stage('Validate Dockerfile') {
            steps {
                echo 'Validating Dockerfile syntax...'
                script {
                    // Check if Dockerfile exists
                    if (!fileExists('Dockerfile')) {
                        error 'Dockerfile not found!'
                    }
                    
                    // Basic Dockerfile validation
                    sh '''
                        if ! grep -q "FROM" Dockerfile; then
                            echo "ERROR: Dockerfile missing FROM instruction"
                            exit 1
                        fi
                        
                        if ! grep -q "COPY" Dockerfile; then
                            echo "ERROR: Dockerfile missing COPY instruction"
                            exit 1
                        fi
                        
                        echo "Dockerfile validation passed"
                    '''
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                script {
                    def image = docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                    docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").inside {
                        sh 'echo "Image built successfully"'
                    }
                }
            }
        }
        
        stage('Test Docker Image') {
            steps {
                echo 'Testing Docker image...'
                script {
                    // Test 1: Check if image starts successfully
                    sh """
                        docker run -d --name test-container-${BUILD_NUMBER} -p 8081:80 ${DOCKER_IMAGE}:${DOCKER_TAG}
                        sleep 10
                        
                        # Test if container is running
                        if ! docker ps | grep -q test-container-${BUILD_NUMBER}; then
                            echo "ERROR: Container failed to start"
                            exit 1
                        fi
                        
                        # Test HTTP response
                        response=\$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081)
                        if [ "\$response" != "200" ]; then
                            echo "ERROR: HTTP response code is \$response, expected 200"
                            exit 1
                        fi
                        
                        echo "HTTP test passed - Status code: \$response"
                        
                        # Cleanup test container
                        docker stop test-container-${BUILD_NUMBER}
                        docker rm test-container-${BUILD_NUMBER}
                    """
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                echo 'Running security scan on Docker image...'
                script {
                    // Note: This requires trivy or similar security scanning tool
                    // Uncomment and configure if you have trivy installed
                    /*
                    sh """
                        trivy image --exit-code 1 --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${DOCKER_TAG}
                    """
                    */
                    
                    // For now, just echo a placeholder
                    echo 'Security scan placeholder - configure trivy or similar tool for actual scanning'
                }
            }
        }
        
        stage('Push to Registry') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    branch 'production'
                }
            }
            steps {
                echo 'Pushing Docker image to registry...'
                script {
                    // Tag for registry
                    sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}"
                    sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:latest"
                    
                    // Push to registry (configure credentials in Jenkins)
                    // docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-registry-credentials') {
                    //     docker.image("${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}").push()
                    //     docker.image("${DOCKER_REGISTRY}/${DOCKER_IMAGE}:latest").push()
                    // }
                    
                    echo "Image would be pushed to ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'staging'
                }
            }
            steps {
                echo 'Deploying to staging environment...'
                script {
                    sh """
                        # Stop existing staging container
                        docker stop ${CONTAINER_NAME}-staging || true
                        docker rm ${CONTAINER_NAME}-staging || true
                        
                        # Run new staging container
                        docker run -d --name ${CONTAINER_NAME}-staging -p 8080:80 ${DOCKER_IMAGE}:${DOCKER_TAG}
                        
                        echo "Staging deployment completed"
                        echo "Access staging at: http://localhost:8080"
                    """
                }
            }
        }
        
        stage('Deploy to EC2 Production') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    branch 'production'
                }
            }
            steps {
                echo 'Deploying to EC2 production environment...'
                script {
                    sh """
                        # Deploy to EC2 instance
                        ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ec2-user@${EC2_HOST} "
                            # Pull latest image
                            docker pull ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}
                            
                            # Stop existing container
                            docker stop ${CONTAINER_NAME} || true
                            docker rm ${CONTAINER_NAME} || true
                            
                            # Run new container
                            docker run -d \\
                                --name ${CONTAINER_NAME} \\
                                --restart unless-stopped \\
                                -p 80:80 \\
                                ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}
                            
                            # Verify deployment
                            sleep 10
                            docker ps | grep ${CONTAINER_NAME}
                            
                            echo 'EC2 deployment completed successfully!'
                        "
                        
                        echo "Production deployment completed"
                        echo "Access production at: http://${EC2_HOST}"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline execution completed'
            // Clean up any test containers
            sh 'docker ps -a --filter "name=test-container-${BUILD_NUMBER}" --format "{{.ID}}" | xargs -r docker rm -f'
        }
        
        success {
            echo 'Pipeline succeeded!'
            // You can add notifications here (email, Slack, etc.)
        }
        
        failure {
            echo 'Pipeline failed!'
            // You can add failure notifications here
        }
        
        cleanup {
            // Clean up workspace
            cleanWs()
        }
    }
}
