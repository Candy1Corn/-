import { useState } from "react";

function Father() {
  const [count, setCount] = useState(0);

  const handleSonClick = () => {
    setCount(count + 1);
  };

  return (
    <div>
      <Child1 count={count} />
      <Child2 onClick={handleSonClick} />
    </div>
  );
}

function Child1({ count }: { count: number }) {
  return <div>{count}</div>;
}

function Child2({ onClick }: { onClick: () => void }) {
  return <button onClick={onClick}>+1</button>;
}

export default Father;
