$target = 10000
$file = "d:\code\doubt-clearing-ai\data\training_data.jsonl"
$startTime = Get-Date

Write-Host "`n--- KALI SOVEREIGNTY LIVE MONITOR (ROBUST) ---" -ForegroundColor Yellow

while ($true) {
    try {
        if (Test-Path $file) {
            # Robust count: Open for reading with shared access to avoid lock conflicts
            $fs = New-Object System.IO.FileStream($file, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
            $sr = New-Object System.IO.StreamReader($fs)
            $count = 0
            while ($sr.ReadLine() -ne $null) { $count++ }
            $sr.Close()
            $fs.Close()

            $elapsed = (Get-Date) - $startTime
            $velocity = if ($elapsed.TotalSeconds -gt 5) { $count / $elapsed.TotalSeconds } else { 0 }
            $remaining = $target - $count
            $etaSeconds = if ($velocity -gt 0) { $remaining / $velocity } else { 0 }
            $eta = (Get-Date).AddSeconds($etaSeconds)
            
            $percent = [math]::Round(($count / $target) * 100, 2)
            
            # Use backticks for a clean overwrite or just clear
            # Clear-Host is safer if we just handle the error
            try { Clear-Host } catch {}
            
            Write-Host "--- KALI SOVEREIGNTY LIVE MONITOR ---" -ForegroundColor Yellow
            Write-Host "Progress: $count / $target ($percent%)" -ForegroundColor Cyan
            Write-Host "Velocity: $([math]::Round($velocity, 2)) interactions/sec"
            Write-Host "Elapsed:  $([math]::Round($elapsed.TotalMinutes, 2)) minutes"
            
            if ($count -lt $target) {
                Write-Host "ETA:      $($eta.ToString('HH:mm:ss')) (in $([math]::Round($etaSeconds / 60, 1)) mins)" -ForegroundColor Yellow
            } else {
                Write-Host "`n[!!!] THRESHOLD MET! KALI IS READY FOR WEIGHT-BAKE." -ForegroundColor Green
                break
            }
        }
    } catch {
        Write-Host "[!] Waiting for file access..." -ForegroundColor Red
    }
    Start-Sleep -Seconds 2
}
