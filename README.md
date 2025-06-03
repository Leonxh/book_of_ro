# 🌟 DSi Slot Machine – BOOK OF RO

A fully functional **slot machine** game made for the **Nintendo DS** using MicroLua DS. Spin the reels, trigger bonus rounds, and chase massive wins with expanding bonus symbols and fun animations including sounds.

<p align="center">
  <img src="assets/sprites/Cover.png" width="600"/>
  <img src="assets/sprites/Cover_lower.png" width="600"/>
</p>

---

## 🎮 Gameplay Overview

- 5×3 reel slot machine
- 10 paylines with classic and themed symbols
- Trigger **Bonus Games** by landing **3+ Book symbols**
- During bonus rounds, a **random symbol is chosen to expand vertically** on reels for more winning potential

---

## 🕹 Controls

| Button             | Action                    |
|--------------------|---------------------------|
| `Stylo tap`/`A`    | Spin the reels            |
| `B`                | Toggle Auto Spin mode     |
| `START`            | Exit the game             |

Bonus scenes are triggered and handled automatically and cannot be forced.

---

## 💥 Features

- Smooth reel animations
- Highlighted winning paylines
- Expanding symbols with visual feedback
- Bonus symbol picker with suspense animation
- Retriggerable bonus spins when landing 3+ Books during bonus rounds
- Score tracking for each spin and total session

---

## 🎨 Game Assets Overview

This slot machine game includes a variety of iconic symbols and animated hit effects. Below you'll find a visual reference of all the graphics used for reels and paylines.

### 🧩 Symbol Set


<table align="center">
  <tr>
    <th align="center">Low-Tier</th>
    <th align="center">High-Tier</th>
  </tr>
  <tr>
    <td align="center">
      <img src="assets/symbols/Ten.png" width="128" title="Ten"/><br/>
      Ten<br/>
      <sub>3x: 5 | 4x: 25 | 5x: 100</sub>
    </td>
    <td align="center">
      <img src="assets/symbols/Scarab.png" width="128" title="Scarab"/><br/>
      Scarab<br/>
      <sub>2x: 5 | 3x: 30 | 4x: 100 | 5x: 750</sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="assets/symbols/J.png" width="128" title="J"/><br/>
      J<br/>
      <sub>3x: 5 | 4x: 25 | 5x: 100</sub>
    </td>
    <td align="center">
      <img src="assets/symbols/Sungod.png" width="128" title="Sungod"/><br/>
      Sungod<br/>
      <sub>2x: 5 | 3x: 30 | 4x: 100 | 5x: 750</sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="assets/symbols/Q.png" width="128" title="Q"/><br/>
      Q<br/>
      <sub>3x: 5 | 4x: 25 | 5x: 100</sub>
    </td>
    <td align="center">
      <img src="assets/symbols/Explorer.png" width="128" title="Explorer"/><br/>
      Explorer<br/>
      <sub>2x: 10 | 3x: 100 | 4x: 1000 | 5x: 5000</sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="assets/symbols/K.png" width="128" title="K"/><br/>
      K<br/>
      <sub>3x: 5 | 4x: 40 | 5x: 150</sub>
    </td>
    <td align="center" rowspan="2">
      <img src="assets/symbols/Book.png" width="128" title="Book"/><br/>
      Book (Bonus & Wild)<br/>
      <sub>2x: 0 | 3x: 20 | 4x: 200 | 5x: 250</sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="assets/symbols/A.png" width="128" title="A"/><br/>
      A<br/>
      <sub>3x: 5 | 4x: 40 | 5x: 150</sub>
    </td>
  </tr>
</table>


### 💥 Hit Effect Animations
Each payline that was hit is marked with a unique overlay from 1 to 10. Only the symbols that actually score will be hightlighted like this.

<p align="center"> 
<img src="assets/symbols/crosses/1.png" width="50"  title="Line 1"/> 
<img src="assets/symbols/crosses/2.png" width="50" title="Line 2"/> 
<img src="assets/symbols/crosses/3.png" width="50" title="Line 3"/> 
<img src="assets/symbols/crosses/4.png" width="50" title="Line 4"/> 
<img src="assets/symbols/crosses/5.png" width="50" title="Line 5"/> 
<img src="assets/symbols/crosses/6.png" width="50" title="Line 6"/> 
<img src="assets/symbols/crosses/7.png" width="50" title="Line 7"/> 
<img src="assets/symbols/crosses/8.png" width="50" title="Line 8"/> 
<img src="assets/symbols/crosses/9.png" width="50" title="Line 9"/> 
<img src="assets/symbols/crosses/10.png" width="50" title="Line 10"/> 
</p>

---

## 🎮 Usage

This game is built using [MicroLua DS](https://sourceforge.net/projects/microlua/), a lightweight Lua framework for the Nintendo DS.

### 📦 Requirements

- A Nintendo DS or DS emulator (e.g., DeSmuME)
- A flashcard or emulator setup that supports `.nds` homebrew
- [MicroLua DS](https://sourceforge.net/projects/microlua/)

### 🚀 Running the Game

1. Clone or download this repository to your computer.
2. Copy the game folder to your flashcart or launch it through your emulator with MicroLua DS.
3. **Literally profit**

---

## ⚠️ Disclaimer

This project is a **joke game** made for fun and experimentation — don't take it too seriously! 🎰🧪

While the gameplay mechanics are inspired by slot machines and there's effort put into polish, you might still encounter **bugs or janky behavior** here and there. It's a **work in progress**, and development is ongoing. 🐛🚧

Thanks for understanding, and feel free to report any issues — or even better, contribute fixes!
