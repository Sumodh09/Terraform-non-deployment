def installTerraform() {
    def terraformExists = sh(script: 'which terraform', returnStatus: true)
    if (terraformExists != 0) {
        sh '''
            echo "Installing Terraform and jq..."

            TERRAFORM_VERSION="1.0.0"
            DOWNLOAD_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

            wget -q $DOWNLOAD_URL -O terraform.zip
            unzip terraform.zip
            sudo mv terraform /usr/local/bin/
            rm -f terraform.zip

            sudo yum install -y jq
        '''
    } else {
        echo "Terraform already installed!"
    }
}

pipeline {
    agent any

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Install Terraform') {
            steps {
                script {
                    installTerraform()
                }
            }
        }

        stage('Terraform Deployment for EC2') {
            steps {
                dir('Non-Deployment/EC2') {
                    script {
                        sh '''
                            
                            echo "Initializing Terraform..."
                            terraform init 
                            echo "Planning Terraform deployment..."
                            terraform plan 
                            echo "Applying Terraform..."
                            terraform apply -auto-approve 
                            echo "Exporting EC2 instance details..."
                            #terraform output -json ec2_instance_details_json | jq -r '.' > ec2_detail.json

                            INPUT_FILE="ec2_detail.json"
                            #OUTPUT_FILE="ec2_compliance_report.csv"

                            if [ ! -f "$INPUT_FILE" ]; then
                                echo "------ Error: $INPUT_FILE not found! ------"
                                exit 1
                            fi

                            echo "Generating EC2 Compliance Report..."

                           

                        '''
                    }
                }
            }
        }
    }

     stage('Terraform Deployment for Lambda') {
            steps {
                script {
                    // CD into deployment folder and run terraform commands
                    dir('Non-Deployment/Lambda') {
                        sh '''
                            #!/bin/bash
                            
                            # Load JSON file
			                terraform init
                            terraform plan
                            terraform apply -auto-approve
                            terraform output -raw lambda_functions_config_json > lambda_details.json
                            #!/bin/bash
                            
                            # File to read
                            INPUT_FILE="lambda_details.json"
                            
                            # Check if file exists
                            if [[ ! -f "$INPUT_FILE" ]]; then
                              echo "File $INPUT_FILE not found!"
                              exit 1
                            fi
                            
                            # Loop through each function and evaluate runtime
                            jq -c '.[]' "$INPUT_FILE" | while read -r lambda; do
                              function_name=$(echo "$lambda" | jq -r '.function_name')
                              runtime=$(echo "$lambda" | jq -r '.runtime')
                            
                              if [[ "$runtime" == "python3.13" ]]; then
                                echo "$function_name - lambda-compliant"
                              else
                                echo "$function_name - lambda-non-compliant"
                              fi
                            done
                        '''
                    }
                }
            }
        }


    post {
        always {
            echo "Pipeline execution completed."
        }
        failure {
            echo "Pipeline failed. Check the logs above."
        }
    }
}
