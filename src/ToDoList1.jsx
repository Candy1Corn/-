import { useRef, useState } from 'react'
import reactLogo from './assets/react.svg'
import viteLogo from '/vite.svg'
import './ToDoList1.css'

function ToDoList(){
    const [list,setList] = useState(["研究一下考核內容和學長教的", "寫 C 實驗報告",     //變數名稱 list, 可以用來對他操作的手段? setList, 後面就是list = []
                                    "體現量表增加手機端功能", "聽英文聽力"])

    const inputRef = useRef()      //用了一個ref, 可以導入輸入框內容
    
    const addtolist = ()=>{      //後面按鈕的 onclick 功能
        setList((state)=>{
            return [...state,inputRef.current.value]       // "..." 居然有換行的功能
        })
        //inputRef.current.value = '';      // 清空輸入框
    }

    const deleteTodo = (index) => {     // 刪除指定的待辦
        const state = todos.filter((_, i) => i !== index);
        setList(state);
    };

return (
    <>
    <div>
        <a href="https://vite.dev" target="_blank">
            <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev" target="_blank">
            <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
    </div>
    <p></p>
    <div className='list'>
        <div className='card'>
        <input ref={inputRef} defaultValue={"下一件待辦"}></input>
        <p><button onClick={addtolist}>確定</button></p>
        </div>

        <div className='table'>
        {list.map((item,index)=>{     //使用 map 走訪 list，為每個待辦事項創建一個 div
        return (
            <p>
            <button className='things' key={index}>
                {item}
                <hr></hr>
            </button>
            </p>
        )
        })}
        </div>
    </div>
    </>
    )
}
export default ToDoList

/*
寫英文課堂作業
寫 C 實驗報告
體現量表增加手機端功能
聽英文聽力
寫網課題目
台生代替課

思考午餐晚餐吃甚麼
思考明天穿甚麼
思考等一下要帶甚麼
思考自己還有甚麼沒做
思考如何安排時間表把新的事情加進去*/