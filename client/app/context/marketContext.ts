"use client"
import { createContext, Dispatch, SetStateAction, useContext } from "react";
import { DummyMarketType } from "../types";
interface MarketContextType {
  markets: DummyMarketType[];
  selectedOption: string | null;
  units: number;
  pricePerUnit: number;
  setUnits: Dispatch<SetStateAction<number>>;
  handleOptionSelect: (optionName: string, odds: number) => void;
}

const MarketContext = createContext<MarketContextType | undefined>(undefined);
export const useMarketContext = () => {
  const context = useContext(MarketContext);
  if (!context) {
    throw new Error(
      "useMarketContext must be used within a MarketContext.Provider"
    );
  }
  return context;
};
export default MarketContext;
