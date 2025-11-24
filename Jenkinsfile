pipeline {
  agent any

  parameters {
    choice(
      name: 'ENV',
      choices: ['dev', 'stage', 'prod'],
      description: 'Choose environment to deploy'
    )
  }

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

          // Get AWS account ID
          env.ECR_ACCOUNT_ID = sh(
            script: "aws sts get-caller-identity --query Account --output text",
            returnStdout: true
          ).trim()

          // Construct ECR image name
          env.IMAGE_NAME = "${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"

          // Short commit tag
          env.GIT_COMMIT_SHORT = sh(
            script: "git rev-parse --short HEAD",
            returnStdout: true
          ).trim()

          // Pick branch based on ENV
          if (params.ENV == "dev") {
            env.HELM_BRANCH = "helm/dev"
            env.HELM_VALUES_FILE = "helm-chart/push-ecr-app/values-dev.yaml"
          }
          if (params.ENV == "stage") {
            env.HELM_BRANCH = "helm/stage"
            env.HELM_VALUES_FILE = "helm-chart/push-ecr-app/values-stage.yaml"
          }
          if (params.ENV == "prod") {
            env.HELM_BRANCH = "helm/prod"
            env.HELM_VALUES_FILE = "helm-chart/push-ecr-app/values-prod.yaml"
          }

          echo "Deploying to ENV = ${params.ENV}"
          echo "Using HELM BRANCH = ${env.HELM_BRANCH}"
          echo "Values file = ${env.HELM_VALUES_FILE}"
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
          echo "Building Docker image..."
          docker build -t ${IMAGE_NAME}:${GIT_COMMIT_SHORT} .
        '''
      }
    }

    stage('Security Scan - Trivy') {
      steps {
        sh '''
          echo "Running Trivy scan..."
          trivy image --severity CRITICAL --exit-code 1 --no-progress ${IMAGE_NAME}:${GIT_COMMIT_SHORT}
        '''
      }
    }

    stage('Push Image to ECR') {
      steps {
        sh '''
          echo "Pushing image to ECR..."
          docker push ${IMAGE_NAME}:${GIT_COMMIT_SHORT}
        '''
      }
    }

    stage('Update Helm Chart Values File') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'github-creds', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {

          sh '''
            echo "Updating Helm values file: $HELM_VALUES_FILE"
            sed -i "s/tag:.*/tag: \\"${GIT_COMMIT_SHORT}\\"/" $HELM_VALUES_FILE

            git config user.email "jenkins@automation.com"
            git config user.name "Jenkins"

            git add $HELM_VALUES_FILE
            git commit -m "CI: Updated ${ENV} image tag to ${GIT_COMMIT_SHORT}"

            echo "Pushing to branch $HELM_BRANCH"
            git push https://$GIT_USER:$GIT_PASS@github.com/studyvj97/push_ecr.git HEAD:$HELM_BRANCH
          '''
        }
      }
    }

  }

  post {
    success {
      echo "🚀 SUCCESS: New version deployed to ${params.ENV}"
      echo "Image Tag: ${GIT_COMMIT_SHORT}"
    }
    failure {
      echo "❌ FAILED: Check pipeline logs"
    }
  }
}

