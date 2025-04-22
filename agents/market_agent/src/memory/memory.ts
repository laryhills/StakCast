//contrubutors, this is agent context
// TODO: Switch from in-memory storage to a persistent solution
import prompt from "../prompts/prompt";
import { MemoryItem } from "../@types/interface";
export default class Memory {
  private static memory: MemoryItem[] = [];

  static initialize() {
    this.memory.push({ role: "system", content: prompt() });
  }
  static add(role: "user" | "assistant", content: string) {
    this.memory.push({ role, content });
  }
  static removeLast() {
    this.memory.pop();
  }

  static reset() {
    const systemPrompt = this.memory.find((item) => item.role === "system");
    this.memory.length = 0;
    if (systemPrompt) this.memory.push(systemPrompt);
  }

  static getMessages(): MemoryItem[] {
    return [...this.memory];
  }
}
