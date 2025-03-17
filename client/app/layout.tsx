import type { Metadata } from "next";
import { Manrope } from "next/font/google";
import Header from "./components/layout/Header";
import "./globals.css";
import "primereact/resources/themes/lara-light-cyan/theme.css";
import { Providers } from "./provider";
import { StarknetProvider } from "./components/utils/Provider";
import { AppProvider } from "./context/appContext";
import { Suspense } from "react";

const manrope = Manrope({
  variable: "--font-manrope",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Stakcast",
  description: "Your crypto prediction market",
  icons:{
    icon:'/logo.svg',
    apple:'/logo.svg'
  }
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${manrope.variable} antialiased bg-[#F8F8FF] text-gray-600`}>
        <Suspense>
          <StarknetProvider>
            <AppProvider>
              <Providers>
                <Header />
                {children}
              </Providers>
            </AppProvider>
          </StarknetProvider>
        </Suspense>
      </body>
    </html>
  );
}