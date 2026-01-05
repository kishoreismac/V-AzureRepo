#!/usr/bin/env python3
"""
Bicep Policy Compliance Tests
"""
import json
import subprocess
import sys
from pathlib import Path

class BicepComplianceChecker:
    def __init__(self, bicep_file):
        self.bicep_file = bicep_file
        self.compiled_json = None
        
    def compile_bicep(self):
        """Compile Bicep to ARM JSON"""
        print(f"Compiling {self.bicep_file}...")
        result = subprocess.run(
            ["az", "bicep", "build", "--file", self.bicep_file, "--stdout"],
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            print(f"Compilation failed: {result.stderr}")
            sys.exit(1)
            
        self.compiled_json = json.loads(result.stdout)
        return self.compiled_json
    
    def check_naming_conventions(self):
        """Check resource naming conventions"""
        print("\n=== Checking Naming Conventions ===")
        
        issues = []
        
        # Check abbreviations
        abbreviations = {}
        if Path("abbreviations.json").exists():
            with open("abbreviations.json") as f:
                abbreviations = json.load(f)
        
        # Check each resource
        for resource in self.compiled_json.get("resources", []):
            name = resource.get("name", "")
            resource_type = resource.get("type", "")
            
            # Check for allowed abbreviations
            for abbr, full in abbreviations.items():
                if abbr in name and full not in name:
                    issues.append(f"Resource '{name}': Use '{full}' instead of '{abbr}'")
        
        return issues
    
    def check_security_policies(self):
        """Check security-related policies"""
        print("\n=== Checking Security Policies ===")
        
        issues = []
        
        for resource in self.compiled_json.get("resources", []):
            resource_type = resource.get("type", "")
            properties = resource.get("properties", {})
            
            # Storage account checks
            if "Microsoft.Storage/storageAccounts" in resource_type:
                if properties.get("supportsHttpsTrafficOnly") != True:
                    issues.append(f"Storage account should enforce HTTPS")
                
                if not properties.get("encryption", {}).get("services", {}).get("blob", {}).get("enabled"):
                    issues.append(f"Storage account blob encryption not enabled")
            
            # SQL Server checks
            elif "Microsoft.Sql/servers" in resource_type:
                if properties.get("publicNetworkAccess") == "Enabled":
                    issues.append(f"SQL Server has public network access enabled")
        
        return issues
    
    def check_cost_optimization(self):
        """Check for cost optimization opportunities"""
        print("\n=== Checking Cost Optimization ===")
        
        issues = []
        
        for resource in self.compiled_json.get("resources", []):
            resource_type = resource.get("type", "")
            sku = resource.get("sku", {})
            
            # Check for oversized SKUs
            oversized_skus = {
                "Standard_D4s_v3": "Consider Standard_D2s_v3 for non-production",
                "Standard_D8s_v3": "Consider Standard_D4s_v3 for non-production",
                "P1V2": "Consider P1V1 for non-production app service plans"
            }
            
            current_sku = sku.get("name", "")
            if current_sku in oversized_skus:
                issues.append(f"Resource {resource_type}: {oversized_skus[current_sku]}")
        
        return issues

def main():
    checker = BicepComplianceChecker("main.bicep")
    checker.compile_bicep()
    
    # Run all checks
    all_issues = []
    
    naming_issues = checker.check_naming_conventions()
    security_issues = checker.check_security_policies()
    cost_issues = checker.check_cost_optimization()
    
    all_issues.extend(naming_issues)
    all_issues.extend(security_issues)
    all_issues.extend(cost_issues)
    
    # Print results
    if all_issues:
        print("\n❌ Compliance Issues Found:")
        for i, issue in enumerate(all_issues, 1):
            print(f"{i}. {issue}")
        sys.exit(1)
    else:
        print("\n✅ All compliance checks passed!")
        sys.exit(0)

if __name__ == "__main__":
    main()