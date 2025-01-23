import Header from "./components/layout/Header";
import Hero from "./components/sections/Hero";
import FeaturesSection from "./components/sections/Features";
import StatsSection from "./components/sections/Stats";
import HowItWorksSection from "./components/sections/HowItWorks";
import Footer from "./components/layout/Footer";

export default function Home() {
  return (
    <div>
      <Header />
      <Hero />
      <StatsSection />
      <FeaturesSection />
      <HowItWorksSection />
      <Footer />
    </div>
  );
}
