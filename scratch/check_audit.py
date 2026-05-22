from src.core.self_auditor import SelfAuditor
import json
auditor = SelfAuditor()
report = auditor.run_audit()
print(f"PURIFICATION STATUS: {len(report['issues'])} issues remaining.")
