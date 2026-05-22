export class Counter {
  private _value = 0;
  private history: number[] = [0];
  private historyIndex = 0;

  get value(): number {
    return this._value;
  }

  increment(): void {
    this._value++;
    this.pushHistory();
  }

  decrement(): void {
    this._value--;
    this.pushHistory();
  }

  undo(): void {
    if (this.historyIndex > 0) {
      this.historyIndex--;
      this._value = this.history[this.historyIndex];
    }
  }

  redo(): void {
    if (this.historyIndex < this.history.length - 1) {
      this.historyIndex++;
      this._value = this.history[this.historyIndex];
    }
  }

  reset(): void {
    this._value = 0;
    this.pushHistory();
  }

  private pushHistory(): void {
    this.history = this.history.slice(0, this.historyIndex + 1);
    this.history.push(this._value);
    this.historyIndex = this.history.length - 1;
  }
}
