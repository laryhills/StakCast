import { AtomaSDK } from "atoma-sdk";
import config from "./config";
import prompt from "../prompts/prompt";
import Memory from "../memory/memory";
Memory;

const atomaSdk = new AtomaSDK({ bearerAuth: config.atoma.apiKey });
Memory.initialize();
async function atomaChat(userMessage: string) {
  try {
    const response = await atomaSdk.chat.create({
      messages: Memory.getMessages(),
      model: config.atoma.model || "meta-llama/Llama-3.3-70B-Instruct",
    });

    return response;
  } catch (error) {
    console.error("Error during Atoma chat request:", error);
    throw error;
  }
}
export default atomaSdk;
export { atomaChat };
