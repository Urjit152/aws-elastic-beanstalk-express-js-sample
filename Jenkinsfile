// Jenkins declarative pipeline for Node.js CI/CD
// This pipeline installs dependencies, runs tests, scans vulnerabilities,
// builds a Docker image, and pushes it to a container registry.

pipeline {

      // Use Node.js 16 Docker image as build environment
      agent { docker { image 'node-docker'; args '-v jenkins-data:/var/jenkins_home' } }

      environment {
        APP_IMAGE = "myapp:${env.BUILD_NUMBER}"
      }

      stages {

        // ------------------------------
        stage('Install Dependencies') {
            steps {
                // Install all project dependencies from package.json
                // The flag --save ensures packages are added to dependencies list if needed
                sh 'npm install --save'
            }
        }
        // ------------------------------

        // ------------------------------
        stage('Run Tests') {
            steps {
                // Run test scripts defined in package.json
                // If tests are missing, print "No tests" instead of failing
                sh 'npm test || (echo \"Tests failed\" && exit 1)'
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
            steps {
                script {
                    echo "Building Docker image using DinD..."
                    sh '''
                    docker info
                    docker build -t myapp:latest .
                    docker images | grep myapp
                    '''
                }
            }
	}

        // ------------------------------

        // ------------------------------
        stage('Push Image') {
	    steps {
                withCredentials([usernamePassword(credentialsId: 'DOCKER_CREDENTIALS', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    // Push built image to DockerHub or private registry
                    // Jenkins environment should store DOCKER_USER and DOCKER_PASS
                    // securely in credentials before running this step
                    sh '''
                    echo "Logging in and pushing image..."
                    docker login -u $DOCKER_USER -p $DOCKER_PASS
                    docker tag myapp:latest $DOCKER_USER/myapp:latest
                    docker push $DOCKER_USER/myapp:latest
                    '''
                }
            }
        }
        // ------------------------------
        // ------------------------------
	stage('Archive Logs') {
          steps {
            archiveArtifacts artifacts: '/build.log', allowEmptyArchive: true
          }
        }
      }

      post {
        always {
          sh 'docker images --format \"{{.Repository}}:{{.Tag}} {{.ID}}\" || true'
        }
      }
    }
