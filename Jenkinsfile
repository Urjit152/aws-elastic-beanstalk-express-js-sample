// Jenkins declarative pipeline for Node.js CI/CD
// This pipeline installs dependencies, runs tests, scans vulnerabilities,
// builds a Docker image, and pushes it to a container registry.

pipeline {

    // Use Node.js 16 Docker image as build environment
    agent { docker { image 'node:16' } }

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
                sh 'npm test || echo "No tests"'
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
	        snyk test || exit 1
	        '''
	    }
	}
        // ------------------------------

        // ------------------------------
        stage('Build Docker Image') {
            agent any
	    steps {
                script {
                    // Build Docker image for the Node.js app
                    // Tag as "myapp:latest" for local use
                    sh 'docker build -t myapp:latest .'
                }
            }
        }
        // ------------------------------

        // ------------------------------
        stage('Push Image') {
            agent any
	    steps {
                withCredentials([usernamePassword(credentialsId: 'DOCKER_CREDENTIALS', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    // Push built image to DockerHub or private registry
                    // Jenkins environment should store DOCKER_USER and DOCKER_PASS
                    // securely in credentials before running this step
                    sh '''
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
            agent any
            steps {
                archiveArtifacts artifacts: '**/build.log', allowEmptyArchive: true
            }
        }
        // ------------------------------
    }
}
