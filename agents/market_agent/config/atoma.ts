import { AtomaSDK } from "atoma-sdk";
import config from "./config";

let atomaSdk = new AtomaSDK({ bearerAuth: config.atoma.apiKey });
export default atomaSdk;
