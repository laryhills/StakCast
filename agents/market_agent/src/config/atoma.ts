import { AtomaSDK } from "atoma-sdk";
import config from "./config";
import prompt from "../prompts/prompt";
const atomaSdk = new AtomaSDK({ bearerAuth: config.atoma.apiKey });
async function atomaChat(userMessage: string) {
  try {
    const response = await atomaSdk.chat.create({
      messages: [
        { role: "assistant", content: prompt() },
        {
          role: "user",
          content: userMessage,
        },
      ],
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
