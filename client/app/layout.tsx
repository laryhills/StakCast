"use client"
// import type { Metadata } from "next";
import { Manrope } from "next/font/google";
// import Header from "./components/layout/Header";
import "./globals.css";
import "primereact/resources/themes/lara-light-cyan/theme.css";

// import { StarknetProvider } from "./components/utils/Provider";
// import { AppProvider } from "./context/appContext";
import { Suspense } from "react";
import { StarknetConfig, publicProvider } from "@starknet-react/core";
import { mainnet, sepolia } from "@starknet-react/chains";
// import { connectors } from "@/components/utils/connectors";
import "./globals.css";
import { connectors } from "./components/utils/connectors";


const manrope = Manrope({
  variable: "--font-manrope",
  subsets: ["latin"],
});



export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const chains = [mainnet, sepolia];
  const providers = publicProvider();
  
  return (
    <html lang="en">
      <body className={`${manrope.className} antialiased bg-[white] text-gray-600`}>
        <Suspense>
       <StarknetConfig chains={chains} provider={providers} connectors={connectors}>
          {children}
        </StarknetConfig>
           
        </Suspense>
      </body>
    </html>
  );
}