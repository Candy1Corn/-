<script>
    import { goto } from '$app/navigation';
</script>

<h1>Hi doctors</h1>

<button onclick={() => goto('doctors/view_patients_info')}> 查看患者資料 </button>
<button onclick={() => goto('doctors/view_medications_info')}> 查看藥品資訊 </button>
<button onclick={() => goto('doctors/view_appointment_info')}> 查看預約掛號狀況 </button>
<button onclick={() => goto('doctors/check_price')}> 看診結果 </button>
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