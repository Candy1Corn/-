import { useEffect, useState } from "react";

function Test() {
  const [count, setCount] = useState(0)

  useEffect(() => {
    console.log("useEffect");
    return () => {
      console.log("useEffect return");
    }
  }, [count])

  return (
    <div>
      {count}
      <button onClick={() => setCount(count + 1)}>add</button>
    </div>
  );
}

export default Test;