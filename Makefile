init:
	terraform init
deploy: init
	terraform apply --auto-approve
destroy:
	terraform destroy --auto-approve
	rm -rf .terraform* & rm -rf terraform*