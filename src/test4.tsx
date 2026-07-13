import { Button, Space } from "antd";
import { create } from "zustand";

// 定义状态和动作的接口
interface Store {
  bears: number;
  increasePopulation: () => void;
  removeAllBears: () => void;
  updateBears: (newBears: number) => void;
}

// 创建一个 zustand store 并为其提供类型
const useStore = create<Store>((set) => ({
  bears: 0,
  increasePopulation: () => set((state) => ({ bears: state.bears + 1 })),
  removeAllBears: () => set({ bears: 0 }),
  updateBears: (newBears) => set({ bears: newBears }),
}));

// BearCounter 组件
function BearCounter() {
  const bears = useStore((state) => state.bears);
  return <h1>{bears} around here ...</h1>;
}

// Controls 组件
function Controls() {
  const bears = useStore((state) => state.bears);
  const increasePopulation = useStore((state) => state.increasePopulation);
  const removeAllBears = useStore((state) => state.removeAllBears);

  return (
    <Space size="large">
      <Button type="primary" onClick={increasePopulation}>
        one up
      </Button>
      {bears > 0 && (
        <Button type="primary" danger onClick={removeAllBears}>
          clear
        </Button>
      )}
    </Space>
  );
}

// 导出默认组件
export default function App() {
  return (
    <>
      <BearCounter />
      <Controls />
    </>
  );
}
