.PHONY: help check-deps fmt fmt-check validate lint test security docs clean all ci

MODULES := $(shell find modules -mindepth 2 -maxdepth 2 -type d)
PATTERNS := $(shell find patterns -mindepth 1 -maxdepth 1 -type d)

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

check-deps: ## Check installed dependencies
	@echo "Checking dependencies..."
	@command -v terraform >/dev/null 2>&1 || { echo "ERROR: terraform is not installed"; exit 1; }
	@command -v tflint >/dev/null 2>&1 || { echo "WARNING: tflint is not installed"; }
	@command -v terraform-docs >/dev/null 2>&1 || { echo "WARNING: terraform-docs is not installed"; }
	@command -v checkov >/dev/null 2>&1 || { echo "WARNING: checkov is not installed"; }
	@echo "Dependency check completed."

fmt: ## Format Terraform code
	@echo "Formatting Terraform code..."
	@terraform fmt -recursive modules/
	@terraform fmt -recursive patterns/
	@echo "Formatting completed."

fmt-check: ## Check formatting without modifying files
	@echo "Checking Terraform formatting..."
	@terraform fmt -check -recursive modules/
	@terraform fmt -check -recursive patterns/

validate: ## Validate all implemented modules
	@echo "Validating modules..."
	@for dir in $(MODULES); do \
		if [ -f "$$dir/main.tf" ]; then \
			echo "Validating $$dir..."; \
			cd $$dir && terraform init -backend=false -input=false >/dev/null 2>&1 && terraform validate && cd - >/dev/null; \
		fi \
	done
	@echo "Validation completed."

lint: check-deps ## Run TFLint for all implemented modules
	@echo "Running TFLint..."
	@for dir in $(MODULES); do \
		if [ -f "$$dir/main.tf" ]; then \
			echo "Linting $$dir..."; \
			tflint --chdir=$$dir --init >/dev/null 2>&1; \
			tflint --chdir=$$dir; \
		fi \
	done
	@echo "Linting completed."

test: ## Run Terraform tests
	@echo "Running Terraform tests..."
	@for dir in $(MODULES); do \
		if [ -d "$$dir/tests" ]; then \
			echo "Testing $$dir..."; \
			cd $$dir && terraform init -backend=false >/dev/null 2>&1 && terraform test && cd - >/dev/null; \
		fi \
	done
	@echo "Tests completed."

security: check-deps ## Run Checkov security scanning
	@command -v checkov >/dev/null 2>&1 || { echo "ERROR: checkov is required for the security target"; exit 1; }
	@echo "Running Checkov..."
	@checkov -d modules/ --framework terraform --quiet --compact
	@echo "Security scan completed."

docs: check-deps ## Generate documentation with terraform-docs
	@command -v terraform-docs >/dev/null 2>&1 || { echo "ERROR: terraform-docs is required for the docs target"; exit 1; }
	@echo "Generating module documentation..."
	@for dir in $(MODULES); do \
		if [ -f "$$dir/main.tf" ]; then \
			echo "Documenting $$dir..."; \
			terraform-docs markdown table $$dir > $$dir/README.md; \
		fi \
	done
	@echo "Documentation generated."

clean: ## Remove Terraform temporary files
	@echo "Cleaning generated Terraform files..."
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@find . -type f -name "*.tfplan" -delete 2>/dev/null || true
	@echo "Cleanup completed."

all: fmt-check validate lint security ## Run all static validations

ci: check-deps fmt-check validate lint security ## Run the complete CI validation set
	@echo "CI validation completed successfully."
