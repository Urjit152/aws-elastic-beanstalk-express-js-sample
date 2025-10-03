// Jenkins declarative pipeline for Node.js CI/CD
// Stages: install deps, run tests, security scan, build & push Docker image, archive logs

pipeline {
  // Default agent: Node.js 16 container for npm and snyk
  // Mount jenkins-data volume so agent container sees Jenkins workspace
  agent {
    docker {
      image 'node:16'
      args '-v jenkins-data:/var/jenkins_home'
    }
  }

  environment {
    APP_IMAGE = "myapp:${env.BUILD_NUMBER}" // Tag image with build number
  }

  stages {
    // ------------------------------
    stage('Install Dependencies') {
      steps {
        sh 'npm install --save'
      }
    }

    // ------------------------------
    stage('Run Tests') {
      steps {
        sh 'npm test || (echo "Tests failed" && exit 1)'
      }
    }

    // ------------------------------
    stage('Security Scan') {
      environment {
        SNYK_TOKEN = credentials('SNYK_TOKEN')
      }
      steps {
        sh '''
          npm install -g snyk
          snyk auth $SNYK_TOKEN
          snyk test --severity-threshold=high || (echo "Snyk found high/critical issues" && exit 1)
        '''
      }
    }

    // ------------------------------
    stage('Build Docker Image') {
      agent any // Run on Jenkins controller (Docker CLI available)
      steps {
        sh "docker build -t ${APP_IMAGE} ."
      }
    }

    // ------------------------------
    stage('Push Image') {
      agent any
      steps {
        withCredentials([usernamePassword(credentialsId: 'DOCKER_CREDENTIALS', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
            docker tag ${APP_IMAGE} $DOCKER_USER/myapp:latest
            docker push $DOCKER_USER/myapp:latest
          '''
        }
      }
    }

    // ------------------------------
    stage('Archive Logs') {
      steps {
        archiveArtifacts artifacts: '/build.log', allowEmptyArchive: true
      }
    }
  }

  post {
    always {
      // List images after build
      sh 'docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" || true'
    }
  }
}
