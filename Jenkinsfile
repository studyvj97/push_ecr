pipeline {
  agent any

  environment {
    AWS_REGION = "us-east-1"
    ECR_REPO   = "vijay_test"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Prepare Environment') {
      steps {
        script {
          // Get AWS Account ID dynamically from EC2 IAM role
          env.ECR_ACCOUNT_ID = sh(
            script: "aws sts get-caller-identity --query Account --output text",
            returnStdout: true
          ).trim()

          // Full ECR image path
          env.IMAGE_NAME = "${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"

          // Short git commit tag for image versioning
          env.GIT_COMMIT_SHORT = sh(
            script: "git rev-parse --short HEAD",
            returnStdout: true
          ).trim()

          echo "Using image: ${env.IMAGE_NAME}:${GIT_COMMIT_SHORT}"
        }
      }
    }

    stage('Login to ECR') {
      steps {
        sh '''
          echo "Logging into ECR..."
          aws ecr get-login-password --region $AWS_REGION \
            | docker login --username AWS --password-stdin ${IMAGE_NAME%/*}
        '''
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          echo "Building Docker image..."
          docker build -t ${IMAGE_NAME}:${GIT_COMMIT_SHORT} .
        '''
      }
    }

    stage('Trivy Security Scan') {
      steps {
        sh '''
          echo "Running Trivy scan..."
          trivy image --severity CRITICAL --exit-code 1 --no-progress ${IMAGE_NAME}:${GIT_COMMIT_SHORT}
        '''
      }
    }

    stage('Tag & Push Image to ECR') {
      steps {
        sh '''
          echo "Tagging image..."
          docker tag ${IMAGE_NAME}:${GIT_COMMIT_SHORT} ${IMAGE_NAME}:latest

          echo "Pushing images to ECR..."
          docker push ${IMAGE_NAME}:${GIT_COMMIT_SHORT}
          docker push ${IMAGE_NAME}:latest
        '''
      }
    }

    stage('Cleanup') {
      steps {
        sh '''
          echo "Cleaning up..."
          docker rmi ${IMAGE_NAME}:${GIT_COMMIT_SHORT} || true
          docker rmi ${IMAGE_NAME}:latest || true
        '''
      }
    }
  }

  post {
    success {
      echo "SUCCESS: Image pushed to ECR as ${IMAGE_NAME}:${GIT_COMMIT_SHORT}"
    }
    failure {
      echo "FAILED: Pipeline failed. Check above logs."
    }
  }
}

