pipeline {
  agent any

  environment {
    AWS_REGION = "us-east-1"
    ECR_REPO   = "vijay_test"
    HELM_BRANCH = "helm"
    HELM_CHART_PATH = "helm-chart/push-ecr-app"   // CORRECT PATH
  }

  stages {

    stage('Checkout Code') {
      steps {
        checkout scm
      }
    }

    stage('Prepare Environment') {
      steps {
        script {
          env.ECR_ACCOUNT_ID = sh(
            script: "aws sts get-caller-identity --query Account --output text",
            returnStdout: true
          ).trim()

          env.IMAGE_NAME = "${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"

          env.GIT_COMMIT_SHORT = sh(
            script: "git rev-parse --short HEAD",
            returnStdout: true
          ).trim()

          echo "Building image: ${IMAGE_NAME}:${GIT_COMMIT_SHORT}"
        }
      }
    }

    stage('Login to ECR') {
      steps {
        sh '''
          aws ecr get-login-password --region $AWS_REGION \
            | docker login --username AWS --password-stdin ${IMAGE_NAME%/*}
        '''
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          docker build -t ${IMAGE_NAME}:${GIT_COMMIT_SHORT} .
        '''
      }
    }

    stage('Trivy Scan') {
      steps {
        sh '''
          trivy image --severity CRITICAL --exit-code 1 --no-progress ${IMAGE_NAME}:${GIT_COMMIT_SHORT}
        '''
      }
    }

    stage('Push to ECR') {
      steps {
        sh '''
          docker tag ${IMAGE_NAME}:${GIT_COMMIT_SHORT} ${IMAGE_NAME}:latest
          docker push ${IMAGE_NAME}:${GIT_COMMIT_SHORT}
          docker push ${IMAGE_NAME}:latest
        '''
      }
    }

    stage('Update Helm Chart Image Tag (GitOps)') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'github-creds', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {

          sh '''
            echo "Fetching helm branch..."
            git fetch origin

            echo "Switching to helm branch..."
            git checkout $HELM_BRANCH
            git pull origin $HELM_BRANCH

            echo "Updating image tag in values.yaml..."
            sed -i "s/tag: .*/tag: \\"${GIT_COMMIT_SHORT}\\"/" ${HELM_CHART_PATH}/values.yaml

            git config user.email "jenkins@example.com"
            git config user.name "Jenkins"

            git add ${HELM_CHART_PATH}/values.yaml
            git commit -m "Update image tag to ${GIT_COMMIT_SHORT}" || echo "No changes"

            echo "Updating Git remote URL with credentials..."
            git remote set-url origin https://$GIT_USERNAME:$GIT_PASSWORD@github.com/studyvj97/push_ecr.git

            echo "Pushing updated helm chart..."
            git push origin $HELM_BRANCH
          '''
        }
      }
    }

    stage('Cleanup') {
      steps {
        sh '''
          docker rmi ${IMAGE_NAME}:${GIT_COMMIT_SHORT} || true
          docker rmi ${IMAGE_NAME}:latest || true
        '''
      }
    }
  }

  post {
    success {
      echo "SUCCESS: New version pushed to ECR and ArgoCD will deploy it!"
    }
    failure {
      echo "FAILED: Check logs."
    }
  }
}

