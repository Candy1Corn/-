import { useCallback, useRef } from 'react';

function TextInputWithFocus() {
  const inputRef = useRef<HTMLInputElement>(null);

  const focusInput = () => {
    inputRef.current?.focus();
  };

  return (
    <div>
      <input ref={inputRef} type="text" />
      <button onClick={focusInput}>Focus</button>
    </div>
  );
}

export default TextInputWithFocus;

function Counter() {
  const count = useRef(0);

  const add = useCallback(() => {
    count.current += 1;
    console.log(count.current);
  }, [])

  return <button onClick={add}>{count.current} add</button>;
}

export Counter;