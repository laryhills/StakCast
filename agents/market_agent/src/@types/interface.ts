//we will define all our types and interfaces here
export type MemoryItem = {
  role: "system" | "user" | "assistant";
  content: string;
};