"use client";
import {
  createContext,
  Dispatch,
  SetStateAction,
  useContext,
  useState,
  ReactNode,
  useEffect,
} from "react";
import { DummyMarketType } from "../types";

interface MarketContextType {
  markets: DummyMarketType[];
  selectedOption: string | null;
  units: number;
  pricePerUnit: number;
  numberOfUnits: number;
  optionPrice: number;
  setOptionPrice: Dispatch<SetStateAction<number>>;
  setNumberOfUnits: Dispatch<SetStateAction<number>>;
  setUnits: Dispatch<SetStateAction<number>>;
  handleOptionSelect: (
    optionName: string,
    odds: number,
    unitPrice: string
  ) => void;
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
  // number of unit to stake on
  const [numberOfUnits, setNumberOfUnits] = useState<number>(1);
  // unit price (option price)
  const [optionPrice, setOptionPrice] = useState<number>(0)
  useEffect(() => {
    setUnits(optionPrice * numberOfUnits);
  }, [optionPrice, numberOfUnits, numberOfUnits]);

  const handleOptionSelect = (optionName: string, odds: number, unitPrice: string) => {
    setSelectedOption(optionName);
    setPricePerUnit(odds);
    setOptionPrice(parseInt(unitPrice));
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
        setNumberOfUnits,
        optionPrice,
        setOptionPrice
      }}
    >
      {children}
    </MarketContext.Provider>
  );
};

export default MarketContext;
