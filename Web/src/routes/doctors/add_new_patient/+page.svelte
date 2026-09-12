<script lang="ts">

    let name = '';
    let birth = '';
    let phone = '';
    let address = '';
    let description = '';

    let submitting = false;
    let message = '';
    let errorMsg = '';

    async function submitForm() {
        if (!name || !phone) {
            errorMsg = '請至少填寫病人姓名與電話號碼！';
            return;
        }

        submitting = true;
        message = '';
        errorMsg = '';

        try {
            const response = await fetch('http://localhost:7999/api/newPatient', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    name,
                    birth,
                    phone: parseInt(phone) || phone,
                    address,
                    description
                })
            });

            const data = await response.json();
            if (response.ok) {
                message = `病患登記成功！病歷號碼：${data.patient_id}`;
                name = '';
                birth = '';
                phone = '';
                address = '';
                description = '';
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
    <h1>新增患者病歷</h1>

    <div class="form-container">
        <div class="field">
            <label for="name">病人姓名 *</label>
            <input id="name" type="text" bind:value={name} placeholder="請輸入病人姓名" required />
        </div>

        <div class="field">
            <label for="birth">出生日期</label>
            <input id="birth" type="date" bind:value={birth} />
        </div>

        <div class="field">
            <label for="phone">電話號碼 *</label>
            <input id="phone" type="tel" bind:value={phone} placeholder="例如：0912345678" required />
        </div>

        <div class="field">
            <label for="address">通訊地址</label>
            <input id="address" type="text" bind:value={address} placeholder="請輸入地址" />
        </div>

        <div class="field">
            <label for="description">病史與過敏史摘要</label>
            <textarea id="description" rows="3" bind:value={description} placeholder="是否有過敏史、家族史等等（直接填入或填無）"></textarea>
        </div>

        <button on:click|preventDefault={submitForm} disabled={submitting}>
            {submitting ? '登記中...' : '確認登記'}
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