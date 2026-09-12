<script lang="ts">

    let medicationsName = '';
    let quantity = '';
    let threshold = '';

    let submitting = false;
    let message = '';
    let errorMsg = '';

    async function submitForm() {
        if (!medicationsName || !threshold) {
            errorMsg = '請填寫完整資訊！';
            return;
        }

        submitting = true;
        message = '';
        errorMsg = '';

        try {
            const response = await fetch('http://localhost:7999/api/newMedications', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    medicationsName,
                    quantity: parseInt(quantity) || quantity,
                    threshold: parseInt(threshold) || threshold,
                })
            });

            const data = await response.json();
            if (response.ok) {
                message = `藥品成功入庫！${data.message}`;
                medicationsName = '';
                quantity = '';
                threshold = ''
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
    <h1>藥品入庫</h1>

    <div class="form-container">
        <div class="field">
            <label for="name">藥品名稱 *</label>
            <input id="med_name" type="text" bind:value={medicationsName} placeholder="請輸入藥品名稱" required />
        </div>

        <div class="field">
            <label for="quantity">存入數量</label>
            <input id="qty" type="number" bind:value={quantity} />
        </div>

        <div class="field">
            <label for="number">警戒值 *</label>
            <input id="threshold" type="tel" bind:value={threshold} placeholder="填入警戒值" required />
        </div>

        <button on:click|preventDefault={submitForm} disabled={submitting}>
            {submitting ? '入庫中...' : '入庫成功'}
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