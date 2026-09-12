<script lang="ts">
    let doctorID = '';
    let reason = '';
    let patientID = '';

    let submitting = false;
    let message = '';
    let errorMsg = '';

    async function submitForm() {
        if (!doctorID || !patientID) {
            errorMsg = '請至少填寫病人 ID 與醫生 ID！';
            return;
        }

        submitting = true;
        message = '';
        errorMsg = '';

        try {
            const response = await fetch('http://localhost:7999/api/appointADocter', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    doctorID,
                    reason,
                    patientID
                })
            });

            const data = await response.json();
            if (response.ok) {
                message = `預約成功！${data.message}`;
                doctorID = '';
                reason = '';
                patientID = ''
            } else {
                errorMsg = data.message || '登記失敗，請檢查輸入資料';
            }
        } catch (err: any) {
            errorMsg = `連線失敗：${err.message}`;
        } finally {
            submitting = false;
        }
    }
</script>

<main>
    <h1>新增預約掛號</h1>

    <div class="form-container">
        <div class="field">
            <label for="doctorID">醫生 ID *</label>
            <input id="doctorID" type="text" bind:value={doctorID} placeholder="請輸入醫生 ID" required />
        </div>

        <div class="field">
            <label for="reason">看診原因</label>
            <input id="reason" type="text" bind:value={reason} />
        </div>

        <div class="field">
            <label for="patientID">病人 ID *</label>
            <input id="patientID" type="text" bind:value={patientID} placeholder="請輸入病人 ID" required />
        </div>

        <button on:click|preventDefault={submitForm} disabled={submitting}>
            {submitting ? '預約中...' : '預約成功'}
        </button>

        {#if message}
            <div class="success-msg">{message}</div>
        {/if}

        {#if errorMsg}
            <div class="error-msg">{errorMsg}</div>
        {/if}
    </div>
</main>

<style>
    main {
        max-width: 600px;
        margin: 2rem auto;
        padding: 1.5rem;
        font-family: sans-serif;
    }
    h1 {
        text-align: center;
        color: #333;
    }
    .form-container {
        display: flex;
        flex-direction: column;
        gap: 1rem;
        background: #fdfdfd;
        padding: 1.5rem;
        border-radius: 8px;
        box-shadow: 0 2px 10px rgba(0,0,0,0.08);
    }
    .field {
        display: flex;
        flex-direction: column;
        gap: 0.3rem;
    }
    label {
        font-weight: bold;
        color: #444;
        font-size: 0.9rem;
    }
    input, textarea {
        padding: 0.6rem;
        border: 1px solid #ccc;
        border-radius: 4px;
        font-size: 1rem;
    }
    button {
        padding: 0.8rem;
        background-color: #2e7d32;
        color: white;
        border: none;
        border-radius: 4px;
        font-size: 1rem;
        cursor: pointer;
        font-weight: bold;
        margin-top: 0.5rem;
    }
    button:disabled {
        opacity: 0.6;
        cursor: not-allowed;
    }
    .success-msg {
        padding: 0.8rem;
        background-color: #e8f5e9;
        color: #2e7d32;
        border: 1px solid #a5d6a7;
        border-radius: 4px;
        font-weight: bold;
    }
    .error-msg {
        padding: 0.8rem;
        background-color: #ffebee;
        color: #c62828;
        border: 1px solid #ef9a9a;
        border-radius: 4px;
        font-weight: bold;
    }
</style>