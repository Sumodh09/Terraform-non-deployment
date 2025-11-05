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
                            set -e  # Exit immediately on any failure
                            echo "Initializing Terraform..."
                            terraform init 
                            echo "Planning Terraform deployment..."
                            terraform plan 
                            echo "Applying Terraform..."
                            terraform apply -auto-approve 
                            echo "Exporting EC2 instance details..."
                            terraform output -json ec2_instance_details_json | jq -r '.' > ec2_detail.json

                            INPUT_FILE="ec2_detail.json"
                            OUTPUT_FILE="ec2_compliance_report.csv"

                            if [ ! -f "$INPUT_FILE" ]; then
                                echo "------ Error: $INPUT_FILE not found! ------"
                                exit 1
                            fi

                            echo "Generating EC2 Compliance Report..."

                            # Write CSV header
                            echo "Instance_ID,Availability_Zone,Compliance_Status,Reason" > "$OUTPUT_FILE"

                            # Parse JSON and append compliance results
                            jq -r '
                              to_entries[] |
                              [
                                .key,
                                .value.availability_zone,
                                (if (.value.availability_zone | startswith("us-east-1")) 
                                  then "Compliant" 
                                  else "Non-Compliant" 
                                 end),
                                (if (.value.availability_zone | startswith("us-east-1")) 
                                  then "Availability zone is us-east-1" 
                                  else "Availability zone is not us-east-1" 
                                 end)
                              ] | @csv
                            ' "$INPUT_FILE" >> "$OUTPUT_FILE"

                            echo "✅ EC2 Compliance Report generated at: $OUTPUT_FILE"
                            echo "Report Preview:"
                            cat "$OUTPUT_FILE"
                        '''
                    }
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
