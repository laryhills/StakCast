
"use client"
import React, { useEffect, useState } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import axios from 'axios';
import Spinner from './components/ui/loading/Spinner';
import { MarketCard } from './components/ui';
import { SearchX } from 'lucide-react';
import { DummyMarketType } from './types';


// Starknet integration imports
// import {  publicProvider } from '@starknet-react/core';
// import { mainnet, sepolia } from '@starknet-react/chains';
import Header from './components/layout/Header';
import { Providers } from './provider';
// import { connectors } from './components/utils/connectors/index';

// Define chains and provider for StarknetConfig
// const chains = [mainnet, sepolia];
// const providers = publicProvider();

const Home = () => {
  const router = useRouter();
  const searchParams = useSearchParams();
  const currentCategory = searchParams.get('category') || 'All';
  const [allMarkets, setAllMarkets] = useState<DummyMarketType[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchMarkets = async () => {
      try {
        const res = await axios.get('/api/dummy_data/');
        setAllMarkets(res.data);
      } catch (error) {
        console.error(error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchMarkets();
  }, []);

  const markets: DummyMarketType[] = Array.isArray(allMarkets)
    ? allMarkets
    : [];

  const filteredMarkets =
    currentCategory === 'All'
      ? markets
      : markets.filter((market) =>
          market?.categories?.includes(currentCategory)
        );

  return (


    // <StarknetConfig chains={chains} provider={providers} connectors={connectors}>
        <main className="p-4">
      <Providers>
      
         <Header />
          {isLoading ? (
            <Spinner />
          ) : filteredMarkets.length > 0 ? (
            <div className="md:flex flex-wrap md:grid-cols-2 gap-3 p-4">
              {filteredMarkets.map((market, index) => (
                <MarketCard
                  key={index}
                  name={market?.name || 'Untitled Market'}
                  image={market?.image || '/default-image.jpg'}
                  options={market?.options || []}
                  totalRevenue={market?.totalRevenue || '$0'}
                  onClick={() => router.push(`/market/${market?.id}`)}
                />
              ))}
            </div>
          ) : (
            <div className="flex flex-col items-center justify-center min-h-[50vh] text-center">
              <SearchX className="w-16 h-16 text-gray-400 mb-4" />
              <h3 className="text-xl font-semibold text-gray-700 mb-2">
                No Markets Found
              </h3>
              <p className="text-gray-500 max-w-md">
                {currentCategory === 'All'
                  ? 'There are currently no markets available.'
                  : `No markets found in the "${currentCategory}" category.`}
              </p>
            </div>
          )}
      </Providers>
        </main>
    // </StarknetConfig>

  );
};

export default Home;

