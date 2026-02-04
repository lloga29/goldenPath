.PHONY: help fmt validate lint test docs clean all

MODULES := $(shell find modules -mindepth 2 -maxdepth 2 -type d)
PATTERNS := $(shell find patterns -mindepth 1 -maxdepth 1 -type d)

help: ## Mostrar esta ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

check-deps: ## Verificar dependencias instaladas
	@echo "Verificando dependencias..."
	@command -v terraform >/dev/null 2>&1 || { echo "ERROR: terraform no instalado"; exit 1; }
	@command -v tflint >/dev/null 2>&1 || { echo "WARNING: tflint no instalado"; }
	@command -v terraform-docs >/dev/null 2>&1 || { echo "WARNING: terraform-docs no instalado"; }
	@command -v checkov >/dev/null 2>&1 || { echo "WARNING: checkov no instalado"; }
	@echo "Dependencias verificadas."

fmt: ## Formatear código Terraform
	@echo "Formateando código..."
	@terraform fmt -recursive modules/
	@terraform fmt -recursive patterns/
	@echo "Formateo completado."

fmt-check: ## Verificar formato sin modificar
	@echo "Verificando formato..."
	@terraform fmt -check -recursive modules/
	@terraform fmt -check -recursive patterns/

validate: ## Validar sintaxis de todos los módulos
	@echo "Validando módulos..."
	@for dir in $(MODULES); do \
		if [ -f "$$dir/main.tf" ]; then \
			echo "Validando $$dir..."; \
			cd $$dir && terraform init -backend=false -input=false >/dev/null 2>&1 && terraform validate && cd - >/dev/null; \
		fi \
	done
	@echo "Validación completada."

lint: check-deps ## Ejecutar tflint en todos los módulos
	@echo "Ejecutando tflint..."
	@for dir in $(MODULES); do \
		if [ -f "$$dir/main.tf" ]; then \
			echo "Linting $$dir..."; \
			tflint --chdir=$$dir --init >/dev/null 2>&1 || true; \
			tflint --chdir=$$dir || true; \
		fi \
	done
	@echo "Linting completado."

test: ## Ejecutar tests de Terraform
	@echo "Ejecutando tests..."
	@for dir in $(MODULES); do \
		if [ -d "$$dir/tests" ]; then \
			echo "Testing $$dir..."; \
			cd $$dir && terraform init -backend=false >/dev/null 2>&1 && terraform test && cd - >/dev/null; \
		fi \
	done
	@echo "Tests completados."

security: ## Ejecutar escaneo de seguridad con checkov
	@echo "Ejecutando checkov..."
	@checkov -d modules/ --framework terraform --quiet --compact || true
	@echo "Escaneo de seguridad completado."

docs: ## Generar documentación con terraform-docs
	@echo "Generando documentación..."
	@for dir in $(MODULES); do \
		if [ -f "$$dir/main.tf" ]; then \
			echo "Documentando $$dir..."; \
			terraform-docs markdown table $$dir > $$dir/README.md 2>/dev/null || true; \
		fi \
	done
	@echo "Documentación generada."

clean: ## Limpiar archivos temporales
	@echo "Limpiando..."
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@find . -type f -name "*.tfplan" -delete 2>/dev/null || true
	@echo "Limpieza completada."

all: fmt-check validate lint security ## Ejecutar todas las validaciones

ci: check-deps fmt-check validate lint security ## Pipeline CI completo
	@echo "Pipeline CI completado exitosamente."
