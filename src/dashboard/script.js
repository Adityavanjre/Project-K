document.addEventListener('DOMContentLoaded', () => {
    const vaultData = [
        { platform: 'HackerOne', identity: 'adityavanjre', hasTotp: true },
        { platform: 'Google', identity: 'adityavanjre280@gmail.com', hasTotp: false },
        { platform: 'Bugcrowd', identity: 'adityavanjre280@gmail.com', hasTotp: false },
        { platform: 'Intigriti', identity: 'adityavanjre280@gmail.com', hasTotp: false },
        { platform: 'Google VRP', identity: 'adityavanjre280@gmail.com', hasTotp: false }
    ];

    const opsData = [
        { name: 'HackerOne Infrastructure Audit', status: 'active' },
        { name: 'Bugcrowd Registration', status: 'pending' },
        { name: 'Intigriti Registration', status: 'pending' },
        { name: 'Google VRP Recon', status: 'pending' }
    ];

    const vaultList = document.getElementById('vault-list');
    
    // Initial Render
    function renderVault() {
        vaultList.innerHTML = '';
        vaultData.forEach(item => {
            const div = document.createElement('div');
            div.className = 'vault-item';
            
            let totpHtml = '';
            if (item.hasTotp) {
                totpHtml = `
                    <div class="live-totp-display" id="totp-${item.platform}">
                        <span class="totp-digit">------</span>
                    </div>
                `;
            }

            div.innerHTML = `
                <div class="platform">
                    ${item.platform}
                    ${item.hasTotp ? '<span class="totp-badge">Live 2FA</span>' : ''}
                </div>
                <div class="identity">${item.identity}</div>
                ${totpHtml}
            `;
            vaultList.appendChild(div);
        });
    }

    renderVault();

    // Live TOTP Polling Logic
    async function fetchLiveTOTP() {
        try {
            const response = await fetch('/api/totp');
            const data = await response.json();
            
            for (const [platform, totpObj] of Object.entries(data)) {
                const element = document.getElementById(`totp-${platform}`);
                if (element) {
                    const timeClass = totpObj.time_remaining <= 5 ? 'danger' : 'success';
                    element.innerHTML = `
                        <span class="totp-digit">${totpObj.code}</span>
                        <div class="totp-timer">
                            <span class="timer-icon">⏱️</span> 
                            <span class="timer-text ${timeClass}">${totpObj.time_remaining}s</span>
                        </div>
                    `;
                }
            }
        } catch (error) {
            console.error("Failed to sync live TOTP from KALI Core:", error);
        }
    }

    // Start the 1-second polling loop
    setInterval(fetchLiveTOTP, 1000);
    fetchLiveTOTP(); // Initial fetch

    const opsList = document.getElementById('ops-list');
    opsData.forEach(item => {
        const div = document.createElement('div');
        div.className = 'op-item';
        div.innerHTML = `
            <div class="op-name">${item.name}</div>
            <div class="op-status ${item.status}">${item.status.toUpperCase()}</div>
        `;
        opsList.appendChild(div);
    });

    document.getElementById('btn-register').addEventListener('click', () => {
        const logBody = document.getElementById('log-body');
        const newLog = document.createElement('div');
        newLog.className = 'log-entry system';
        newLog.innerText = '[SYSTEM] Initiating autonomous cross-platform registration protocol...';
        logBody.appendChild(newLog);
        logBody.scrollTop = logBody.scrollHeight;
        
        setTimeout(() => {
            const successLog = document.createElement('div');
            successLog.className = 'log-entry success';
            successLog.innerText = '[AUTH] Spawning KALI Browser Subagent for Bugcrowd...';
            logBody.appendChild(successLog);
            logBody.scrollTop = logBody.scrollHeight;
        }, 1500);
    });
});
