# =============================================================================
# Force-delete ECR repositories (workaround for Terraform AWS provider bug)
# =============================================================================
# The aws_ecr_repository force_delete attribute often fails during terraform destroy.
# This script deletes the repos via AWS CLI, then removes them from Terraform state.
#
# Prerequisites: AWS CLI installed and configured (aws configure)
# Usage: From repo root, run: .\terraform\scripts\destroy-ecr.ps1
# =============================================================================

$ErrorActionPreference = "Stop"
$ProjectName = "terraform-ansible-webapp"
$Region      = "eu-west-1"
$Repos       = @("backend", "frontend", "proxy")

$TerraformDir = Join-Path $PSScriptRoot ".."

Write-Host "Force-deleting ECR repositories via AWS CLI..." -ForegroundColor Cyan
foreach ($r in $Repos) {
    $name = "${ProjectName}-${r}"
    try {
        aws ecr delete-repository --repository-name $name --region $Region --force 2>&1 | Out-Null
        Write-Host "  Deleted: $name" -ForegroundColor Green
    } catch {
        Write-Host "  Skip/failed: $name ($_)" -ForegroundColor Yellow
    }
}

Write-Host "`nRemoving ECR resources from Terraform state..." -ForegroundColor Cyan
Set-Location $TerraformDir
foreach ($r in $Repos) {
    $addr = 'module.ecr.aws_ecr_repository.main["' + $r + '"]'
    terraform state rm $addr 2>&1
    Write-Host "  Removed from state: $r"
}

Write-Host "`nRunning terraform destroy..." -ForegroundColor Cyan
terraform destroy -auto-approve


