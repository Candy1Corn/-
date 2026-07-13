import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import ToDoList1 from './ToDoList1.jsx'
import ToDoList2 from './ToDoList2.jsx'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <ToDoList2/>   
  </StrictMode>,
)
