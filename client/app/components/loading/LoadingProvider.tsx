import React, { createContext, useContext, useState } from "react";
import Spinner from "./Spinner"; 

// Create the context
const LoadingContext = createContext({
  isLoading: false,
  showSpinner: () => {},
  hideSpinner: () => {},
});

// Custom hook to use the context
export const useLoading = () => useContext(LoadingContext);

// Provider component
const LoadingProvider = ({ children }: { children: React.ReactNode }) => {
  const [isLoading, setIsLoading] = useState(false);

  const showSpinner = () => setIsLoading(true);
  const hideSpinner = () => setIsLoading(false);

  return (
    <LoadingContext.Provider value={{ isLoading, showSpinner, hideSpinner }}>
      {children}
      {isLoading && <Spinner />} {/* Render the spinner when isLoading is true */}
    </LoadingContext.Provider>
  );
};

export default LoadingProvider;