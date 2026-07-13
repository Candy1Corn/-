const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('pet', {
  mouseIgnore: (v)    => ipcRenderer.send('mouse-ignore', v),
  moveBy:      (dx,dy)=> ipcRenderer.send('move-by', dx, dy),
  moveTo:      (x,y)  => ipcRenderer.send('move-to', x, y),
  getState:    ()     => ipcRenderer.invoke('get-state'),
});
