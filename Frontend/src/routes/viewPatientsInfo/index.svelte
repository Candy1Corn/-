<script lang="ts">
    // +page.svelte 是 SvelteKit 的保留字
    import { onMount } from 'svelte';   // onMount 是 Svelte 的生命週期函式，它會在元件被掛載到畫面上後執行一次

    type PatientInfo = {
        name: string;
        dob: string;
        contact: string;
        address: string;
        description: string;
        diagnosis: string;
        prescription: string | null;
    };

    let patients: Record<string, PatientInfo> = {};   // 用來儲存從 API 獲取的病患資料


    onMount(async () => {   // async 是甚麼
        try {
            const response = await fetch('http://localhost:8000/api/checkPatientsInfo');
            if (!response.ok) {
                throw new Error('Network response was not ok')
            }
            patients = await response.json();
        } catch (error) {
            console.error('獲取病患資料失敗:', error);
        }
    })

</script>


<main>
    <h1>牙醫診所管理系統</h1>

    {#if Object.keys(patients).length == 0}
        <p>正在從伺服器載入資料</p>
    {:else}
        <table border="1">      <!-- 這是甚麼? -->
            <thead>      <!-- 這是甚麼? -->
                <tr>
                    <th>病歷號碼</th>
                    <th>病人姓名</th>
                    <th>生日</th>
                    <th>連絡電話</th>
                </tr>
            </thead>
        
            <tbody>
                <!-- #each 是 Svelte 的迴圈語法 -->
                {#each Object.entries(patients) as [pid, info]}      <!-- 為甚麼 as [pid, info] 有兩項在括號裡面? -->
                <tr>
                    <td>{pid}</td>
                    <td>{info.name}</td>
                    <td>{info.dob}</td>
                    <td>{info.contact}</td>
                </tr>
                {/each}
            </tbody>

        </table>
    {/if}

</main>