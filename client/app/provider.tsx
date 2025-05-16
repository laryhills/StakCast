"use client";
import React, { useEffect } from "react";
import { useConnect } from "@starknet-react/core";
import { useAppContext } from "./context/appContext";
import { SessionAccountInterface } from "@argent/invisible-sdk";

export function Providers({ children }: { children: React.ReactNode }) {
  const { status, connectionMode, setAccount } = useAppContext();
  const { connectors, connectAsync } = useConnect({});
  console.log(connectionMode)
  useEffect(() => {
    if (connectionMode === "wallet") {
      const LS_connector = localStorage.getItem("connector");

      if (LS_connector && status === "disconnected") {
        (async () => {
          const connector = connectors.find((con) => con.id === LS_connector);

          if (connector) {
            try {
              await connectAsync({ connector })
                .then(() => console.log("Wallet reconnected successfully"))
                .catch((err) => console.log("Reconnection error:", err));
            } catch (error) {
              console.log("Failed to reconnect wallet:", error);
              // Si falla la reconexión, limpiar el localStorage
              localStorage.removeItem("connector");
            }
          }
        })();
      }
    } else {
      console.log("connection", connectionMode);
      console.log("hhhhere");
      const LS_session = localStorage.getItem("sessionItem");
      if (!LS_session) return;
      const sessionItem: SessionAccountInterface = JSON.parse(LS_session);
      setAccount(sessionItem);
    }
  }, [status, connectAsync, connectors, connectionMode]);

  return <>{children}</>;
}
