
import { create } from "zustand";// 定义状态和动作的接口
interface BearStore {
  bears: number;
  increasePopulation: () => void;
  removeAllBears: () => void;
  updateBears: (newBears: number) => void;
}


// 创建一个 zustand store 并为其提供类型
const useBearStore = create<BearStore>((set) => ({
  bears: 0,
  increasePopulation: () => set((state) => ({ bears: state.bears + 1 })),
  removeAllBears: () => set({ bears: 0 }),
  updateBears: (newBears) => set({ bears: newBears }),
}));

interface DogStore {
  dogs: number;
  increasePopulation: () => void;
  removeAllBears: () => void;
  updateBears: (newDogs: number) => void;
}


// 创建一个 zustand store 并为其提供类型
const useDogStore = create<DogStore>((set) => ({
  dogs: 0,
  increasePopulation: () => set((state) => ({ dogs: state.dogs + 1 })),
  removeAllBears: () => set({ dogs: 0 }),
  updateBears: (newDogs) => set({ dogs: newDogs }),
}));

//export default useBearStore;

export { useBearStore, useDogStore };