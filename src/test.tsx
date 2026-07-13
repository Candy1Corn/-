import { useState } from "react";

function Father() {
  const [count, setCount] = useState(0);

  const handleSonClick = (add: number) => {
    setCount(count + add);
  };

  return (
    <div>
      <h1>我是父组件</h1>
      <p>{count}</p>
      <Child onClick={handleSonClick} />
    </div>
  );
}

type ChildProps = {
  onClick: (add: number) => void;
};

function Child(props: ChildProps) {
  return (
    <button
      onClick={() => {
        props.onClick(1);
      }}
    >
      +1
    </button>
  );
}

// 父组件

export default Father;
