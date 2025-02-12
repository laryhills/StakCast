import React from "react";

const StatsSection = () => {
  const stats = [
    { value: "Coming Soon", label: "Trading Volume" },
    { value: "In Beta", label: "Predictions" },
    { value: "Join Now", label: "Community" },
    { value: "Live Soon", label: "Resolution Rate" },
  ];

  return (
    <section className="py-16 bg-gradient-to-r from-green-400 to-blue-500  text-white">
      <div className="container mx-auto px-4">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8 text-center">
          {stats.map((stat, index) => (
            <div key={index} className="p-4">
              <div className="text-4xl font-bold mb-2">{stat.value}</div>
              <div className="text-purple-200">{stat.label}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default StatsSection; 