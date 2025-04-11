//this is responsible for giving the agent context

import prompt from "../prompts/prompt";

const memory: any[] = [];
const initializeMemory = (formattedContext: any) => {
  memory.push({ role: "system", content: "You are a helpful assistant." });
  memory.push({ role: "user", content: prompt() });
};
const addToMemory = (role: "user" | "assistant", content: string) => {
  memory.push({ role, content });
};

export { initializeMemory, addToMemory };
export default memory;
