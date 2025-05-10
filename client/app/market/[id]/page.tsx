"use client";
import React, { useEffect, useState } from "react";

import { DummyMarketType } from "@/app/types";
import { useParams, useRouter } from "next/navigation";
import Image from "next/image";
import { ArrowLeft, TrendingUp, MessageSquare, Activity } from "lucide-react";
import CommentSection from "@/app/components/sections/CommentSection";
import RecentActivity from "@/app/components/sections/RecentActivity";
import ChartSection from "@/app/components/sections/ChartSection";
import PurchaseSection from "@/app/components/sections/PurchaseSection";
import { Button } from "@/components/ui/button";
import axios from "axios";
import { useMarketContext } from "@/app/context/marketContext";
const Page = () => {
  const params = useParams();
  const router = useRouter();
  const [market, setMarket] = useState<DummyMarketType | undefined>(undefined);

  const [allMarkets, setAllMarkets] = useState<DummyMarketType[]>([]);
  const { units, pricePerUnit,selectedOption } = useMarketContext();
  useEffect(() => {
    (async () => {
      try {
        const res = await axios.get("/api/dummy_data/");
        console.log(res);
        setAllMarkets(res.data);
      } catch (error) {
        console.log(error);
      }
    })();
  }, []);

  

  const [activeTab, setActiveTab] = useState("chart");

  useEffect(() => {
    if (Array.isArray(allMarkets)) {
      if (allMarkets.length > 0) {
        const fetchedMarket = allMarkets.find(
          (market: Partial<DummyMarketType> | undefined) =>
            market?.id === Number(params.id)
        );

        if (fetchedMarket) {
          setMarket(fetchedMarket as DummyMarketType);
        } else {
          setMarket(undefined);
        }
      } else {
        setMarket(undefined);
      }
    } else {
      console.error("dummyMarkets is not an array");
    }
  }, [params.id, allMarkets]);

  const handlePurchase = () => {
    if (selectedOption && units > 0) {
      const totalPrice = units * pricePerUnit;
      console.log(
        `Purchased ${units} units of ${selectedOption} for $${totalPrice.toFixed(
          2
        )}`
      );
    } else {
      console.log("Please select an option and enter a valid number of units.");
    }
  };
  console.log(handlePurchase);
  if (!market) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  const tabs = [
    { id: "chart", label: "Chart", icon: TrendingUp },
    { id: "activity", label: "Activity", icon: Activity },
    { id: "comments", label: "Comments", icon: MessageSquare },
  ];

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-slate-950">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="flex items-center space-x-4 mb-8">
          <Button
            onClick={() => router.push("/")}
            className="p-2 hover:bg-gray-100 rounded-full transition-colors"
          >
            <ArrowLeft className="w-6 h-6 text-gray-600 dark:text-white" />
          </Button>
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
              {market.name}
            </h1>
            <p className="text-gray-500 dark:text-white text-sm">
              Market ID: {market.id}
            </p>
          </div>
        </div>

        {/* Main Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left Column */}
          <div className="lg:col-span-2 space-y-6">
            {/* Market Image */}
            <div className="bg-white dark:bg-slate-950 rounded-2xl shadow-sm overflow-hidden">
              <div className="relative h-64 w-full">
                <Image
                  src={market.image}
                  alt={market.name}
                  fill
                  className="object-cover"
                />
              </div>
            </div>

            {/* Tabs Navigation */}
            <div className="bg-white dark:bg-slate-950 rounded-2xl shadow-sm p-4">
              <div className="flex space-x-4 border-b">
                {tabs.map((tab) => (
                  <Button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`flex items-center space-x-2 px-4 py-3 font-medium text-sm transition-colors ${
                      activeTab === tab.id
                        ? "border-b-2 border-blue-500 text-blue-600"
                        : "text-gray-500 hover:text-gray-700"
                    }`}
                  >
                    <tab.icon className="w-4 h-4" />
                    <span>{tab.label}</span>
                  </Button>
                ))}
              </div>

              {/* Tab Content */}
              <div className="mt-6">
                {activeTab === "chart" && <ChartSection />}
                {activeTab === "activity" && <RecentActivity />}
                {activeTab === "comments" && <CommentSection />}
              </div>
            </div>
          </div>

          <div className="lg:col-span-1">
            <div className="bg-white  dark:bg-slate-800 rounded-2xl shadow-sm p-6 sticky top-8">
              <PurchaseSection />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Page;
