import sys
import json
import os
from evolution_validator import EvolutionValidator

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"success": False, "error": "No action specified"}))
        return

    action = sys.argv[1]
    project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    validator = EvolutionValidator(project_root)

    if action == "benchmark":
        benchmarks = validator.load_benchmarks()
        results = {}
        
        for domain, tests in benchmarks.items():
            domain_score = 0
            count = 0
            for test in tests:
                # For baseline, we use the input as 'code' to see how the current version performs
                # In real training, 'code' would be the improved output from KALI
                res = validator.score_execution(test["input"], test["test_script"])
                domain_score += res.get("score", 0)
                count += 1
            
            results[domain] = {
                "score": domain_score / count if count > 0 else 0,
                "count": count
            }
        
        print(json.dumps({"success": True, "results": results}))

    elif action == "validate":
        # logic for before/after comparison
        if len(sys.argv) < 5:
            print(json.dumps({"success": False, "error": "Missing codes/script"}))
            return
            
        test_script = sys.argv[2]
        before_code = sys.argv[3]
        after_code = sys.argv[4]
        
        success, details = validator.compare_evolution(test_script, before_code, after_code)
        print(json.dumps({"success": success, "details": details}))

if __name__ == "__main__":
    main()
