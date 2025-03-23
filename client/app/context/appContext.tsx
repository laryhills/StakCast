// "use client";

// import React, { createContext, useContext, useRef } from "react";
// import { Toast } from "primereact/toast";
// import { sepolia } from "@starknet-react/chains";
// import { useConnect, useDisconnect, useAccount, useBalance } from "@starknet-react/core";
// import type { Connector } from "@starknet-react/core";
// import {constants} from "starknet"
// // Import connectors from StarknetKit
// import { ArgentMobileConnector } from "starknetkit/argentMobile";
// import { InjectedConnector } from "starknetkit/injected";

// interface AppContextType {
//   showToast: (
//     severity: "success" | "error" | "info",
//     summary: string,
//     detail: string
//   ) => void;
//   connectWallet: (connector: Connector) => Promise<void>;
//   disconnectWallet: () => Promise<void>;
//   address?: string;
//   status: string;
//   balance?: string;
// }

// const AppContext = createContext<AppContextType | undefined>(undefined);
// const SN_GOERLI = "4retkstkes"
// // Helper: Detect mobile devices using userAgent
// const isMobileDevice = (): boolean => {
//   if (typeof navigator === "undefined") return false;
//   return /Mobi|Android/i.test(navigator.userAgent);
// };

// export function AppProvider({ children }: { children: React.ReactNode }) {
//   const toast = useRef<Toast>(null);
//   const { connectAsync } = useConnect();
//   const { disconnectAsync } = useDisconnect();
//   const { address, status } = useAccount();
//   const { data } = useBalance({ address: address || undefined });
//   const balance = data?.formatted ? `${data.formatted} ${data.symbol}` : "";

//   const showToast = (
//     severity: "success" | "error" | "info",
//     summary: string,
//     detail: string
//   ) => {
//     toast.current?.show({ severity, summary, detail });
//   };

//   // connectWallet: if on mobile, use Argent Mobile connector with built-in modal; otherwise, use an injected connector.
//   const connectWallet = async (connector: Connector) => {
//     try {
//       let usedConnector: Connector = connector;

//       if (isMobileDevice()) {
//         usedConnector = ArgentMobileConnector.init({
//           options: {
//             dappName: "Your Dapp Name",       // Your dApp's name
//             projectId: "YOUR_PROJECT_ID",      // Required for WalletConnect v2 (if applicable)
//             chainId:  process.env.NEXT_PUBLIC_CHAIN_ID === constants.NetworkName.SN_MAIN
//             ? constants.NetworkName.SN_MAIN
//             : constants.NetworkName.SN_SEPOLIA,
//             url: window.location.hostname,     // Current hostname
//             icons: ["https://your-icon-url.com"], // Your dApp's icon URL
//             rpcUrl: "YOUR_RPC_URL",            // Your RPC endpoint for Starknet
//           },
//           inAppBrowserOptions: {
//             // 'id': "fdfs",
//             // modalDescription:
//             //   "Scan the QR code with your Argent app or connect directly on mobile.",
//           },
//         }) as Connector;
//       } else {
//         // For desktop, ensure you use an injected connector (e.g., ArgentX)
//         usedConnector = new InjectedConnector({ options: { id: "argentX" } });
//       }

//       await connectAsync({ connector: usedConnector });
//       localStorage.setItem("connector", usedConnector.id);
//       showToast("success", "Success", "Wallet connected successfully");
//     } catch (error: unknown) {
//       localStorage.removeItem("connector");
//       let errorMessage = "Failed to connect wallet.";
//       if (error instanceof Error) {
//         if (error.message.includes("rejected")) {
//           errorMessage =
//             "Connection rejected. Please approve the connection request.";
//         } else if (error.message.includes("Connector not found")) {
//           errorMessage = `${connector.name} is not installed.`;
//         } else {
//           errorMessage = "Connection Failed";
//         }
//       }
//       showToast("error", "Connection Failed", errorMessage);
//     }
//   };

//   const disconnectWallet = async () => {
//     try {
//       await disconnectAsync();
//       localStorage.removeItem("connector");
//       showToast("success", "Success", "Wallet disconnected successfully");
//     } catch (error) {
//       console.log(error);
//       showToast("error", "Error", "Failed to disconnect wallet");
//     }
//   };

//   return (
//     <AppContext.Provider
//       value={{ showToast, connectWallet, disconnectWallet, address, status, balance }}
//     >
//       <Toast ref={toast} />
//       {children}
//     </AppContext.Provider>
//   );
// }

// export const useAppContext = () => {
//   const context = useContext(AppContext);
//   if (!context) {
//     throw new Error("useAppContext must be used within an AppProvider");
//   }
//   return context;
// };
