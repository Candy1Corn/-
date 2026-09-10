<script>
    import { goto } from '$app/navigation';
</script>

<h1>Hi patients</h1>

<button onclick={() => goto('nurses/view_patientself')}> 查看病人資料 </button>
<button onclick={() => goto('nurses/view_appointment_info')}> 查看預約掛號狀況 </button>
<button onclick={() => goto('nurses/pay')}> 收費、繳費 </button>
<button onclick={() => goto('nurses/check_price')}> 查看付款資訊 </button>
<button onclick={() => goto('nurses/add_new_patient')}> 新增患者病歷 </button>
<button onclick={() => goto('doctors/add_new_appointment')}> 新增預約掛號 </button>

<style>
    a {
        text-decoration: none;
        color: rgb(255, 255, 255);
    }
    button {
        margin: 10px;
    }
    button:hover{
        cursor: pointer;
        filter: drop-shadow(0 0 1em  #6291f7);
        transition: all 0.2s ease-in-out
    }
</style>