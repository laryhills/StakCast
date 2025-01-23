import React from "react";

import { MarketOption } from "@/app/types";

interface MarketCardProps {
  name: string;
  image: string;
  options: MarketOption[];
  totalRevenue: string;
  onClick?: () => void;
  [key: string]: unknown;
}

const MarketCard: React.FC<MarketCardProps> = ({
  name = "Untitled Market",
  //image = "/default-image.jpg",
  options = [],
  totalRevenue = "$0",
  ...props
}) => {
  return (
    <div
      className="rounded-lg shadow-md hover:shadow-xl transition-shadow duration-200 border md:w-[30%] w-full mx-auto text-sm gap-3 mt-4"
      style={{ cursor: "pointer" }}
      {...props}
    >
      <div className="relative h-10 border border-gray-200 shadow-sm overflow-hidden rounded-t-lg m-auto">
        {/* <Image
          src={image}
          alt={name}
          className="object-cover w-fit h-fit"
          height={100}
          width={100}
        /> */}
      </div>
      <div className="p-4 h-[14em] flex flex-col justify-between overflow-auto">
        <h3 className="font-bold text-gray-800">{name}</h3>
        <p className="text-sm text-gray-600 mt-2">
          <span className="font-medium">Total Revenue:</span> {totalRevenue}
        </p>
        <div className="mt-2 space-y-2 overflow-auto text-sm">
          {options?.map((option, index) => (
            <div
              key={index}
              className="flex items-center justify-between bg-gray-100 p-2 rounded-md"
            >
              <span className="text-sm font-medium text-gray-800">
                {option.name}
              </span>
              <span className="text-sm font-bold text-blue-600">
                {option.odds}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default MarketCard;
