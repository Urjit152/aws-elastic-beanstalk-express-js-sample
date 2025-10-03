// Jenkins declarative pipeline for Node.js CI/CD
// Uses Node:16 as build agent (shared jenkins-data volume).
// Runs Docker build/push from Jenkins with DinD (TLS).

pipeline {

  // Build agent: Node.js + shared Jenkins workspace
  agent {
    docker {
      image 'node:16'
      args '-v jenkins-data:/var/jenkins_home'
    }
  }

  // Image tag + DinD env for any stage that runs Docker
  environment {
    APP_IMAGE = "myapp:${env.BUILD_NUMBER}"
    DOCKER_HOST = "tcp://docker:2376"
    DOCKER_CERT_PATH = "/certs/client"
    DOCKER_TLS_VERIFY = "1"
  }

  stages {

    // ------------------------------
    stage('Install Dependencies') {
      steps {
        sh 'npm install --save'
      }
    }
    // ------------------------------

    // ------------------------------
    stage('Run Tests') {
      steps {
        sh 'npm test || (echo "Tests failed" && exit 1)'
      }
    }
    // ------------------------------

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

    // ------------------------------
    stage('Build Docker Image') {
      agent none // run on Jenkins (not inside node:16 agent)
      steps {
        script {
          // Use absolute docker path to avoid PATH issues inside Jenkins
          sh "/usr/bin/docker info"
          sh "/usr/bin/docker build -t ${APP_IMAGE} ."
          sh "/usr/bin/docker images | grep myapp || true"
        }
      }
    }
    // ------------------------------

    // ------------------------------
    stage('Push Image') {
      agent none // run on Jenkins
      steps {
        withCredentials([usernamePassword(credentialsId: 'DOCKER_CREDENTIALS', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo $DOCKER_PASS | /usr/bin/docker login -u $DOCKER_USER --password-stdin
            /usr/bin/docker tag '"${APP_IMAGE}"' $DOCKER_USER/myapp:latest
            /usr/bin/docker push $DOCKER_USER/myapp:latest
          '''
        }
      }
    }
    // ------------------------------

    // ------------------------------
    stage('Archive Logs') {
      steps {
        // archive optional build log for submission
        archiveArtifacts artifacts: '/build.log', allowEmptyArchive: true
      }
    }
    // ------------------------------
  }

  post {
    always {
      // List images for verification (use absolute docker path)
      sh '/usr/bin/docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" || true'
    }
  }
}
