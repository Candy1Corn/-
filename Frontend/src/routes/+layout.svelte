<script>
  // 不需要額外 import Router，SvelteKit 會自動處理路由
</script>

<nav>
  <a href="/"> ■ 首頁</a>
  <a href="/view_patients_info"> ▥ 查看病人資訊</a>
  <a href="/add_new_patient"> ± 新增病人</a>
</nav>

<main>
  <!-- 這個 slot 很重要，SvelteKit 會把對應 route 的內容插進來 -->
  <slot />
</main>

<style>
  nav {
    display: flex;
    gap: 1rem;
    padding: 1rem;
    background-color: #4161a6;
    border-radius: 10px;
    box-shadow: 0 0 10px rgb(0, 0, 0);
  }
  nav:hover {
    filter: drop-shadow(0 0 2em  #4161a6);
    transition: all 0.2s ease-in-out;
  }
  nav a {
    text-decoration: none;
    color: #ffffff;
    font-weight: bold;
  }

  nav a:hover {
    text-decoration: underline;
  }

  main {
    padding: 2rem;
  }
</style>
