import React from "react";

const HeroSection = () => {
  return (
    <section className="text-green-900 text-center py-20 px-4 md:px-8">
      <h1 className="text-3xl md:text-5xl font-bold mb-4 md:mb-6">
        Predict & Earn with StakCast
      </h1>
      <p className="mt-4 text-lg md:text-xl max-w-md md:max-w-2xl mx-auto">
        Stake STRK tokens, predict near future events, and earn rewards. Join
        the decentralized prediction marketplace trusted by thousands.
      </p>
      <div className="mt-6 md:mt-8 space-y-4 md:space-y-0 md:space-x-4 flex flex-col md:flex-row justify-center items-center">
        <button className="px-6 md:px-8 py-3 bg-yellow-500 text-black rounded-lg hover:bg-yellow-400 font-semibold">
          Start Predicting
        </button>
        <button className="px-6 md:px-8 py-3 border-2 border-green-900 text-green-900 rounded-lg hover:bg-green-900 hover:text-white">
          Learn More
        </button>
      </div>
    </section>
  );
};

export default HeroSection;
