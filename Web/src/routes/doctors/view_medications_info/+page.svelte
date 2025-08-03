<script lang="ts">
    import { onMount } from 'svelte';

    type MedicationsInfo = {
        stock: number;
        threshold: number;
    };

    // 使用 Record<string, DoctorsInfo> 來儲存以病歷號為鍵的病患物件
    let medications: Record<string, MedicationsInfo> = {};
    let loading = true;
    let error: string | null = null;

    // onMount 會在元件掛載到畫面後執行
    onMount(async () => {
        try {
            // 呼叫後端 API，注意要使用完整的 URL
            const response = await fetch('http://localhost:7999/api/checkMedicationsInfo');

            if (!response.ok) {
                throw new Error(`伺服器錯誤: ${response.status}`);
            }

            // 將回應的 JSON 資料直接存入 patients 物件
            medications = await response.json();
        } catch (err) {
            if (err instanceof Error) {
                error = `無法載入病患資料：${err.message}`;
            } else {
                error = '發生未知錯誤';
            }
            console.error('獲取病患資料失敗:', err);
        } finally {
            loading = false;
        }
    });
</script>

<main>
    <h1>藥物庫存列表</h1>

    {#if loading}
        <p>正在從伺服器載入資料...</p>
    {:else if error}
        <p style="color: red;">{error}</p>
    {:else if Object.keys(medications).length === 0}
        <p>目前沒有藥物資料。</p>
    {:else}
        <div class="big-table-container">
            <table border="1">
                <thead>
                    <tr>
                        <th>藥品名稱</th>
                        <th>庫存</th>
                        <th>臨界值</th>
                    </tr>
                </thead>
                <tbody>
                    <!-- 
                        使用 Object.entries 來遍歷物件的鍵和值
                        [pid, info] 透過解構賦值，分別取得病歷號和對應的病患資訊
                    -->
                    {#each Object.entries(medications) as [mid, info]}
                    <tr>
                        <td>{mid}</td>
                        <td>{info.stock}</td>
                        <td>{info.threshold}</td>
                    </tr>
                    {/each}
                </tbody>
            </table>
        </div>

    {/if}
</main>

<style>
    main {
        padding: 2em;
        font-family: 'Helvetica Neue', Arial, sans-serif;
        text-align: center;
    }
    table {
        width: 100%;
        border-collapse: collapse;
        margin-top: 20px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    th, td {
        border: 1px solid #ddd;
        padding: 12px;
        text-align: left;
    }
    th {
        background-color: #f2f2f2;
        font-weight: bold;
    }
    tr:nth-child(even) {
        background-color: #f9f9f9;
    }
    tr:hover {
        background-color: #f1f1f1;
    }
    h1 {
        color: #333;
    }

    .big-table-container {
        padding: 10px;
    }
</style>
