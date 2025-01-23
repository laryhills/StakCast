export interface MarketOption {
  name: string;
  odds: number;
}

export interface DummyMarketType {
  id: number;
  name: string;
  image: string;
  options: MarketOption[];
  totalRevenue: string;
  categories: string[];
  status: 'active' | 'inactive';
  startTime: number;
  endTime: number;
  createdBy: string;
}

export type BaseProps = {
  className?: string;
};
