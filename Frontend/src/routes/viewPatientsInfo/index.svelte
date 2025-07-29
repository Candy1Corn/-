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


    onMount(async () => {   // async 是甚麼：是 JavaScript 的異步函數關鍵字，讓函數能夠處理非同步操作（如 API 請求）
        try {
            // 修正 API 端點 - 改為與後端匹配的路徑
            const response = await fetch('http://localhost:8000/viewPatientsInfo');

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
        <table border="1" style="border-collapse: collapse; width: 100%;">      <!-- table?這是甚麼?是 HTML 表格標籤，border="1" 設定邊框寬度 -->
            <thead>      <!-- threads?這是甚麼? -->
                <tr style="background-color: #f0f0f0;">
                    <th style="padding: 10px; text-align: left;">病歷號碼</th>
                    <th style="padding: 10px; text-align: left;">病人姓名</th>
                    <th style="padding: 10px; text-align: left;">生日</th>
                    <th style="padding: 10px; text-align: left;">連絡電話</th>
                    <th style="padding: 10px; text-align: left;">地址</th>
                    <th style="padding: 10px; text-align: left;">病史描述</th>
                </tr>
            </thead>
            <tbody>     <!-- <thead> 和 <tbody> 是 HTML 表格的標頭和內容區塊 -->
                {#each Object.entries(patients) as [pid, info]}     <!-- #each 是 Svelte 的迴圈語法 -->
                <!-- 為甚麼 as [pid, info] 有兩項在括號裡面?是解構賦值，將 Object.entries() 返回的陣列元素分別賦值給 pid 和 info 變數 -->
                <tr>
                    <td style="padding: 8px; border: 1px solid #ddd;">{pid}</td>
                    <td style="padding: 8px; border: 1px solid #ddd;">{info.name}</td>
                    <td style="padding: 8px; border: 1px solid #ddd;">{info.dob}</td>
                    <td style="padding: 8px; border: 1px solid #ddd;">{info.contact}</td>
                    <td style="padding: 8px; border: 1px solid #ddd;">{info.address}</td>
                    <td style="padding: 8px; border: 1px solid #ddd;">{info.description}</td>
                </tr>
                {/each}
            </tbody>
        </table>
    {/if}

</main>