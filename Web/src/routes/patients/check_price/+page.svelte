<script lang="ts">
    import { onMount } from 'svelte';

    type PriceEntry = {
        patientID: string;
        name: string;
        cost: number;
        type: string;
        date: string;
        paid: string;
    };

    let prices: PriceEntry[] = [];
    let isLoading = true;
    let error: string | null = null;

    onMount(async () => {
        try {
            // 您的 Flask 伺服器運行在 7999 port
            const response = await fetch('http://127.0.0.1:7999/api/checkPrice');
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            prices = await response.json();
        } catch (e: any) {
            error = "無法載入價格資訊：" + e.message;
        } finally {
            isLoading = false;
        }
    });
</script>

<svelte:head>
    <title>費用查詢</title>
</svelte:head>

<div class="container">
    <h1>費用總覽</h1>

    {#if isLoading}
        <p>正在載入資料...</p>
    {:else if error}
        <p class="error">{error}</p>
    {:else if prices.length === 0}
        <p>目前沒有任何費用紀錄。</p>
    {:else}
        <table>
            <thead>
                <tr>
                    <th>病歷號</th>
                    <th>姓名</th>
                    <th>項目類型</th>
                    <th>費用</th>
                    <th>狀態</th>
                    <th>日期</th>
                </tr>
            </thead>
            <tbody>
                {#each prices as entry (entry.patientID + entry.date)}
                    <tr>
                        <td>{entry.patientID}</td>
                        <td>{entry.name}</td>
                        <td>{entry.type}</td>
                        <td>${entry.cost.toLocaleString()}</td>
                        <td class:paid={entry.paid === '已繳費'} class:unpaid={entry.paid !== '已繳費'}>
                            {entry.paid}
                        </td>
                        <td>{entry.date}</td>
                    </tr>
                {/each}
            </tbody>
        </table>
    {/if}
</div>

<style>
    .container {
        max-width: 960px;
        margin: 2rem auto;
        padding: 1rem;
        font-family: sans-serif;
    }
    h1 {
        color: #333;
        text-align: center;
    }
    table {
        width: 100%;
        border-collapse: collapse;
        margin-top: 1.5rem;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    th, td {
        padding: 12px 15px;
        text-align: left;
        border-bottom: 1px solid #ddd;
    }
    thead th {
        background-color: #4CAF50;
        color: white;
    }
    tbody tr:nth-child(even) {
        background-color: #f2f2f2;
    }
    tbody tr:hover {
        background-color: #ddd;
    }
    .error {
        color: red;
        text-align: center;
    }
    .paid {
        color: green;
        font-weight: bold;
    }
    .unpaid {
        color: #c0392b;
        font-weight: bold;
    }
</style>
