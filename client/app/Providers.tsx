"use client";

import { ReactNode } from "react";
import { MarketProvider } from "./context/marketContext";
import { ThemeProvider } from "./context/ThemeContext";
import { AppProvider } from "./context/appContext";

interface ProvidersProps {
  children: ReactNode;
}

export default function Providers({ children }: ProvidersProps) {
  return (
    <AppProvider>
      <MarketProvider>
        <ThemeProvider>{children}</ThemeProvider>
      </MarketProvider>
    </AppProvider>
  );
}
