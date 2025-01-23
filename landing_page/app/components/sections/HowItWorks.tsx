import React from "react";

const HowItWorksSection = () => {
  const steps = [
    {
      number: "01",
      title: "Connect Wallet",
      description: "Link your wallet and ensure you have STRK tokens ready for staking.",
    },
    {
      number: "02",
      title: "Choose a Market",
      description: "Browse through available prediction markets and select one that interests you.",
    },
    {
      number: "03",
      title: "Make Prediction",
      description: "Stake your STRK tokens on your predicted outcome.",
    },
    {
      number: "04",
      title: "Earn Rewards",
      description: "If your prediction is correct, claim your rewards automatically.",
    },
  ];

  return (
    <section className="py-20 bg-white">
      <div className="container mx-auto px-4">
        <h2 className="text-3xl font-bold text-center mb-16">How StakCast Works</h2>
        <div className="grid md:grid-cols-4 gap-8">
          {steps.map((step, index) => (
            <div key={index} className="relative">
              <div className="text-6xl font-bold text-purple-100 mb-4">{step.number}</div>
              <h3 className="text-xl font-semibold mb-2">{step.title}</h3>
              <p className="text-gray-600">{step.description}</p>
              {index < steps.length - 1 && (
                <div className="hidden md:block absolute top-8 left-full w-full h-0.5 bg-purple-100 -z-10" />
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default HowItWorksSection; 