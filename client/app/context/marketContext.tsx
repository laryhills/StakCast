"use client";
import {
  createContext,
  Dispatch,
  SetStateAction,
  useContext,
  useState,
  ReactNode,
} from "react";
import { DummyMarketType } from "../types";

interface MarketContextType {
  markets: DummyMarketType[];
  selectedOption: string | null;
  units: number;
  pricePerUnit: number;
  numberOfUnits: number;
  setNumberOfUnits: Dispatch<SetStateAction<number>>;
  setUnits: Dispatch<SetStateAction<number>>;
  handleOptionSelect: (optionName: string, odds: number) => void;
  setMarkets: Dispatch<SetStateAction<DummyMarketType[]>>;
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

export const MarketProvider = ({
  children,
  initialMarkets = [],
}: {
  children: ReactNode;
  initialMarkets?: DummyMarketType[];
}) => {
  const [markets, setMarkets] = useState<DummyMarketType[]>(initialMarkets);
  const [selectedOption, setSelectedOption] = useState<string | null>(null);
  const [units, setUnits] = useState<number>(1);
  const [pricePerUnit, setPricePerUnit] = useState<number>(0);
  const [numberOfUnits, setNumberOfUnits] = useState<number>(1);

  const handleOptionSelect = (optionName: string, odds: number) => {
    setSelectedOption(optionName);
    setPricePerUnit(odds);
  };

  return (
    <MarketContext.Provider
      value={{
        markets,
        selectedOption,
        units,
        pricePerUnit,
        setUnits,
        handleOptionSelect,
        setMarkets,
        numberOfUnits,
        setNumberOfUnits
      }}
    >
      {children}
    </MarketContext.Provider>
  );
};

export default MarketContext;
