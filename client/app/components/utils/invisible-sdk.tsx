"use client";
import { useState, useEffect } from "react";
//import type { SessionAccountInterface } from "@argent/invisible-sdk";
import { useAppContext } from "@/app/context/appContext";
export const useArgentSdk = () => {
  //const [account, setAccount] = useState<SessionAccountInterface | undefined>();
  const { sessionAccount: account, setAccount } = useAppContext();
  const [isConnecting, setIsConnecting] = useState(false);

  const initWallet = async () => {
    const { ArgentWebWallet } = await import("@argent/invisible-sdk");
    return ArgentWebWallet.init({
      appName: "Stakcast",
      environment: "sepolia",
      sessionParams: {
        allowedMethods: [
          {
            contract:
              "0x047b1867577b88f63fd38ce0565881c27eeddf757af437a599cea7a1e8bf79f8",
            selector: "init_game",
          },
          {
            contract:
              "0x047b1867577b88f63fd38ce0565881c27eeddf757af437a599cea7a1e8bf79f8",
            selector: "reveal",
          },
        ],
      },
    });
  };

  const connect = async () => {
    setIsConnecting(true);
    try {
      const argentWebWallet = await initWallet();
      if (!argentWebWallet) {
        throw new Error("Argent Web Wallet failed to initialize");
      }
      const response = await argentWebWallet.requestConnection({
        callbackData: "stakcast_connection",
        approvalRequests: [],
      });

      if (!response || response.account.getSessionStatus() !== "VALID") {
        throw new Error("Invalid session");
      }

      setAccount(response.account);
      return response.account;
    } catch (error) {
      console.error("Failed to connect:", error);
      throw error;
    } finally {
      console.log(account);
      setIsConnecting(false);
    }
  };

  const disconnect = async () => {
    const argentWebWallet = await initWallet();
    await argentWebWallet.clearSession();
    setAccount(undefined);
  };

  useEffect(() => {
    (async () => {
      try {
        const argentWebWallet = await initWallet();
        const response = await argentWebWallet.connect();
        if (response && response.account.getSessionStatus() === "VALID") {
          setAccount(response.account);
        }
      } catch (err) {
        console.error("Check existing session error", err);
      }
    })();
  }, []);

  return {
    account,
    isConnecting,
    connect,
    disconnect,
    isConnected: !!account,
  };
};
