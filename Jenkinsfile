pipeline {
  agent none   // don’t set a global agent

  environment {
    APP_IMAGE = "myapp:${env.BUILD_NUMBER}"
  }

  stages {
    stage('Install Dependencies') {
      agent {
        docker {
          image 'node:16'
          args '-v jenkins-data:/var/jenkins_home'
        }
      }
      steps {
        sh 'npm install --save'
      }
    }

    stage('Run Tests') {
      agent {
        docker {
          image 'node:16'
          args '-v jenkins-data:/var/jenkins_home'
        }
      }
      steps {
        sh 'npm test'
      }
    }

    stage('Security Scan') {
      agent {
        docker {
          image 'node:16'
          args '-v jenkins-data:/var/jenkins_home'
        }
      }
      environment {
        SNYK_TOKEN = credentials('SNYK_TOKEN')
      }
      steps {
        sh '''
          npm install -g snyk
          snyk auth $SNYK_TOKEN
          snyk test --severity-threshold=high
        '''
      }
    }

    stage('Build Docker Image') {
      agent any   // run on controller where docker CLI/socket are mounted
      steps {
        sh "docker build -t ${APP_IMAGE} ."
      }
    }

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

    stage('Archive Logs') {
      agent any
      steps {
        archiveArtifacts artifacts: 'build.log', allowEmptyArchive: true
      }
    }
  }

  post {
    always {
      sh 'docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" || true'
    }
  }
}
