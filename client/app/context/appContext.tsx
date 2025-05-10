"use client";
import {
  createContext,
  useContext,
  useState,
  ReactNode,
  SetStateAction,
  Dispatch,
} from "react";
import { useAccount, useBalance } from "@starknet-react/core";
import { SessionAccountInterface } from "@argent/invisible-sdk";
interface AppContextType {
  balance: string;
  address: `0x${string}` | undefined;
  sessionAccount: SessionAccountInterface | undefined;
  status: string;
  setAccount: Dispatch<SetStateAction<SessionAccountInterface | undefined>>;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export function AppProvider({ children }: { children: ReactNode }) {
  let { address } = useAccount();
  //const { status } = useAccount();

  const [sessionAccount, setAccount] = useState<
    SessionAccountInterface | undefined
  >();

  address = sessionAccount ? sessionAccount.address : address;
  sessionAccount?.getSessionStatus();
  const { data, isFetching } = useBalance({
    token: "0x04718f5a0Fc34cC1AF16A1cdee98fFB20C31f5cD61D6Ab07201858f4287c938D",
    address: address as "0x",
  });

  const balance = isFetching
    ? "loading..."
    : data?.formatted
    ? `${parseFloat(data.formatted).toFixed(2)} ${data.symbol}`
    : "";
  const status = address ? "connected" : "disconnected";
  return (
    <AppContext.Provider
      value={{
        address,
        status,
        sessionAccount,
        balance,
        setAccount,
      }}
    >
      {children}
    </AppContext.Provider>
  );
}

export function useAppContext() {
  const context = useContext(AppContext);
  if (context === undefined) {
    throw new Error("useAppContext must be used within an AppProvider");
  }
  return context;
}
