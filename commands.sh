aws sts get-caller-identity # Check AWS credentials
aws secretsmanager delete-secret --secret-id {SECRET_ID} --force-delete-without-recovery --region {AWS_REGION} # WARNING: Delete immediately a secret in AWS Secrets Manager


docker builder prune # Remove unused build cache


git reset --soft HEAD^ # Undo last commit but keep changes staged


.venv/bin/activate # Python uv virtual environment activation
deactivate # Python uv virtual environment deactivation
