import { produce } from "immer";
import { useState } from "react";

type Todo = {
  id: string;
  title: string;
  done: boolean;
};

function TodoList() {
  const [index, setIndex] = useState<number>(0)
  setIndex(index + 1)
  
  const [todos, setTodos] = useState<Todo[]>([
    {
      id: "React",
      title: "Learn React",
      done: true,
    },
    {
      id: "Immer",
      title: "Try Immer",
      done: false,
    },
  ]);

  // 定义handleToggle函数来切换待办事项的完成状态
  const handleToggle = (id: string) => {
    setTodos((draft) =>
      produce(draft, (draftTodos) => {
        const todo = draftTodos.find((todo) => todo.id === id);
        if (todo) {
          todo.done = !todo.done;
        }
      }),
    );
  };

  // 渲染待办事项列表
  return (
    <div>
      {todos.map((todo: Todo) => (
        <div
          key={todo.id}
          style={{ textDecoration: todo.done ? "line-through" : "none" }}
          onClick={() => handleToggle(todo.id)}
        >
          {todo.title}
        </div>
      ))}
    </div>
  );
}

export default TodoList;
