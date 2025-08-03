<script lang="ts">
    import { onMount } from 'svelte';

    type DoctorsInfo = {
        patientID: number;
        time: string;
        type: string;
    };

    // 使用 Record<string, DoctorsInfo> 來儲存以病歷號為鍵的病患物件
    let doctors: Record<string, DoctorsInfo> = {};
    let loading = true;
    let error: string | null = null;

    // onMount 會在元件掛載到畫面後執行
    onMount(async () => {
        try {
            // 呼叫後端 API，注意要使用完整的 URL
            const response = await fetch('http://localhost:7999/api/checkAppointmentInfo');

            if (!response.ok) {
                throw new Error(`伺服器錯誤: ${response.status}`);
            }

            // 將回應的 JSON 資料直接存入 patients 物件
            doctors = await response.json();
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
    <h1>預約掛號狀態列表</h1>

    {#if loading}
        <p>正在從伺服器載入資料...</p>
    {:else if error}
        <p style="color: red;">{error}</p>
    {:else if Object.keys(doctors).length === 0}
        <p>目前沒有資料。</p>
    {:else}
        <div class="big-table-container">
            <table border="1">
                <thead>
                    <tr>
                        <th>醫生 ID</th>
                        <th>病人姓名</th>
                        <th>時間</th>
                        <th>預約內容</th>
                    </tr>
                </thead>
                <tbody>
                    <!-- 
                        使用 Object.entries 來遍歷物件的鍵和值
                        [pid, info] 透過解構賦值，分別取得病歷號和對應的病患資訊
                    -->
                    {#each Object.entries(doctors) as [did, info]}
                    <tr>
                        <td>{did}</td>
                        <td>{info.patientID}</td>
                        <td>{info.time}</td>
                        <td>{info.type}</td>
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
