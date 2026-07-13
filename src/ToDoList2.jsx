import React, { useState, useEffect } from 'react';
import ToDoLogo from '/ToDoLogo.png'
import './ToDoList2.css'

function TodoPage() {

    const [todos, setTodos] = useState([]);     // 先定義一個放入待辦的list
    const [input, setInput] = useState('');     // 抓輸入框

    useEffect(() => {       // 當組件加載時，從 localStorage 中讀取待辦事項
        const savedTodos = localStorage.getItem('todos');       // 存，可以用 savedTodos 呼叫
            if (savedTodos) {       // 如果代辦 list 裡面有東西
                setTodos(JSON.parse(savedTodos));       // 轉換JSON 內容，存入savedTodos
            }
    }, []);     // []表示在組件首次加載時執行一次，沒有 [] 會發現刪不掉待辦

    const addTodo = () => {
        if (input.trim() !== '') {      // 如果輸入框的內容不是空，trim用來去頭去尾留中間
            localStorage.setItem('todos', JSON.stringify([...todos, input.trim()]));    // 原 todos 加上輸入框內容，轉成 JSON，存，用 todos 呼叫
            setTodos([...todos, input.trim()]);     // 再把存的呼叫(todos)出來
            setInput('');       // 清空輸入框
    }
    };

    const deleteTodo = (index) => {
        const newTodos = todos.filter((_, i) => i !== index);
        console.log("這是普通的new", (newTodos));
        localStorage.setItem('todos', JSON.stringify([...newTodos]));
        console.log("這是存的newTodos", (localStorage.getItem("todos")));
        //setTodos(JSON.parse( localStorage.getItem('todos') ));
        setTodos([...newTodos]);    // 挖草我弄好了！快誇我！我從零開始 React 就做東西欸 (趴
    };

    return (
        <>
        <a href="ToDoList2.jsx" target="_blank">
            <img src={ToDoLogo} className="logo react" alt="React logo" />
        </a>
        <div >
            <ul>
            {todos.map((todo, index) => (
                <>
                <li key={index}>
                {todo}
                <button onClick={() => deleteTodo(index)}> ◀</button>
                </li>
                <p></p>
                </>
            ))}
            </ul>
            <input onKeyDown={
                (e) => {if (e.key === "Enter"){addTodo()}}} 
                type="text" value={input}
                onChange={(e) => setInput(e.target.value)} 
                placeholder="下一件待辦事項"/>
                
            <button onClick={addTodo}>▶</button>
            
        </div>
        </>
    );
};

export default TodoPage;
