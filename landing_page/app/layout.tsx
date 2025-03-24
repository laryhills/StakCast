import type { Metadata } from "next";
import "./globals.css";
import { Manrope } from "next/font/google";
import { ThemeProvider } from "./contexts/ThemeContext";
// const quicksand = Quicksand({
//   variable: "--font-quicksand",
//   subsets: ["latin"],
// });

const manrope = Manrope({ variable: "--font-manrope", subsets: ["latin"] });
export const metadata: Metadata = {
  title: "Stakcast",
  description:
    "StakCast is a decentralized prediction platform where users can participate in prediction markets.",
  icons: {
    icon: "/logo.svg",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <ThemeProvider>
        <body className={`${manrope.className}  antialiased `}>{children}</body>
      </ThemeProvider>
    </html>
  );
}
