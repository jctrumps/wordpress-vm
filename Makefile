infra-init:
	cd opentofu && tofu init

infra-plan:
	cd opentofu && tofu plan

infra-apply:
	cd opentofu && tofu apply

app:
	cd ansible && ansible-playbook site.yml
