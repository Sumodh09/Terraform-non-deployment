def installTerraform() {
    // Check if terraform is already installed
    def terraformExists = sh(script: 'which terraform', returnStatus: true)
    if (terraformExists != 0) {
        // Install terraform
        sh '''
            echo "Installing Terraform..."
            wget https://releases.hashicorp.com/terraform/1.0.0/terraform_1.0.0_linux_amd64.zip
            unzip terraform_1.0.0_linux_amd64.zip
            sudo mv terraform /usr/local/bin/
            rm -f terraform_1.0.0_linux_amd64.zip
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
                // Pull the git repo
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
                script {
                    // CD into deployment folder and run terraform commands
                    dir('Non-Deployment/EC2') {
                        sh '''
                            #!/bin/bash
                            
                            # Load JSON file
                            terraform init
                            terraform plan 
                            terraform apply -auto-approve
                            terraform output -raw ec2_instance_details_json > ec2_data.json
                            
                            INPUT_FILE="ec2_data.json"
                            
                            # Check if file exists
                            if [ ! -f "$INPUT_FILE" ]; then
                              echo "Error: $INPUT_FILE not found!"
                              exit 1
                            fi
                            
                            echo "Instance Compliance Report:"
                            echo "---------------------------"
                            
                            # Loop through all instances and check compliance
                            jq -r '
                              to_entries[] |
                              .key as $id |
                              .value.availability_zone as $az |
                              if ($az | startswith("us-east-1")) then
                                "\\($id): \\($az) -> Compliant"
                              else
                                "\\($id): \\($az) -> Non-Compliant"
                              end
                            ' "$INPUT_FILE"
                        '''
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
                            terraform output -raw lambda_functions_config_json > lambda_detailss.json
                            #!/bin/bash
                            
                            # File to read
                            INPUT_FILE="lambda_detailss.json"
                            
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

		stage('Terraform Deployment for Security Group') {
            steps {
                script {
                    // CD into deployment folder and run terraform commands
                    dir('Non-Deployment/Security-Group') {
                        sh '''
                            #!/bin/bash
                            
                            # Load JSON file
			                terraform init
                            terraform plan
                            terraform apply -auto-approve
                            terraform output -json security_group_details > sg_details.json

							VPC_ID_TO_CHECK="vpc-0ba50349bcd767084"
							JSON_FILE="sg_details.json"
							
							jq -r --arg vpc_id "$VPC_ID_TO_CHECK" '
							  to_entries[] |
							  "\(.key): " + 
							  (if .value.vpc_id == $vpc_id then "COMPLIANT" else "NON-COMPLIANT" end)
							' "$JSON_FILE"
                    }
                }
            }
        }
    }
}
