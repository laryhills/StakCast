"use client";
import React, { useEffect, useState } from "react";
import { useSearchParams, useRouter } from "next/navigation";

import { MarketCard } from "./components/ui";
import { SearchX } from "lucide-react";
import { DummyMarketType } from "./types";
import axios from "axios";

export default function Home() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const currentCategory = searchParams.get("category") || "All";
  const [allMarkets,setAllMarkets]=useState<DummyMarketType|[]>([])
  // Safely handle undefined or empty markets

  useEffect(() => {
   
      (async()=>{
        try {
          const res=await axios.get('/api/dummy_data/')
          console.log(res);
          setAllMarkets(res.data)
        } catch (error) {
          console.log(error)
        }
       
        
      })()
      
  }, []);
  const markets: DummyMarketType[] = Array.isArray(allMarkets)
    ? allMarkets
    : [];


  const filteredMarkets =
    currentCategory === "All"
      ? markets
      : markets.filter((market) =>
          market?.categories?.includes(currentCategory)
        );

  return (
    <main className="p-4">
      {filteredMarkets.length > 0 ? (
        <div className="md:flex flex-wrap md:grid-cols-2 gap-3 p-4">
          {filteredMarkets.map((market, index) => (
            <MarketCard
              key={index}
              name={market?.name || "Untitled Market"}
              image={market?.image || "/default-image.jpg"}
              options={market?.options || []}
              totalRevenue={market?.totalRevenue || "$0"}
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
            {currentCategory === "All"
              ? "There are currently no markets available."
              : `No markets found in the "${currentCategory}" category.`}
          </p>
        </div>
      )}
    </main>
  );
}
