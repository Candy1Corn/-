<script lang="ts">

    let name = '';
    let birth = '';
    let phone = '';
    let address = '';
    let department_id = '';

    let submitting = false;
    let message = '';
    let errorMsg = '';

    async function submitForm() {
        if (!name || !phone || !department_id) {
            errorMsg = '請至少填寫護士姓名、電話號碼與所屬科室！';
            return;
        }

        submitting = true;
        message = '';
        errorMsg = '';

        try {
            const response = await fetch('http://localhost:7999/api/newNurse', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    name,
                    birth,
                    phone: parseInt(phone) || phone,
                    address,
                    department_id: parseInt(department_id) || department_id
                })
            });

            const data = await response.json();
            if (response.ok) {
                message = `護士資料登記成功！護士編號：${data.nurse_id}`;
                name = '';
                birth = '';
                phone = '';
                address = '';
                department_id = ''
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
    <h1>新增護士資料</h1>

    <div class="form-container">
        <div class="field">
            <label for="name">護士姓名 *</label>
            <input id="name" type="text" bind:value={name} placeholder="請輸入護士姓名" required />
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

        <div class="department_id">
            <label for="department_id">所屬科室</label>
            <input id="department_id" type="number" bind:value={department_id} required />
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