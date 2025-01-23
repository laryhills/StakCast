// src/components/FeaturesSection.tsx
import React from "react";

const FeaturesSection = () => {
  const features = [
    {
      icon: "🔮",
      title: "Predict & Earn",
      description: "Stake STRK tokens on your predictions and earn rewards when you're right.",
    },
    {
      icon: "🔗",
      title: "Decentralized",
      description: "Fully transparent and decentralized prediction markets powered by blockchain.",
    },
    {
      icon: "🔒",
      title: "Secure Staking",
      description: "Your STRK tokens are securely locked in smart contracts during predictions.",
    },
    {
      icon: "📊",
      title: "Real-Time Markets",
      description: "Access live prediction markets for news, events, and outcomes.",
    },
  ];

  return (
    <section className="py-16 bg-white">
      <div className="container mx-auto px-4">
        <h2 className="text-3xl font-bold text-center text-green-900">Why Choose StakCast</h2>
        <div className="mt-12 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8">
          {features.map((feature, index) => (
            <div key={index} className="bg-gray-50 p-6 rounded-xl hover:shadow-lg transition-shadow">
              <div className="text-4xl mb-4">{feature.icon}</div>
              <h3 className="text-xl font-semibold text-green-900">{feature.title}</h3>
              <p className="mt-2 text-gray-600">{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default FeaturesSection;
