'use client'
import React from "react";
import Image from "next/image";
import Link from "next/link";
const Header: React.FC = () => {


  return (
    <header className="">
      <div className="container  flex justify-between items-center p-1">
        <div>
          <Image src="/logo.png" alt="logo" width={200} height={200} />
        </div>
        <div className="hidden md:flex space-x-6 text-green-900 font-medium items-center">
          <Link href="/"> Home </Link>
          <Link href="/"> Markets </Link>
          <Link href="/"> How It Works </Link>
          <Link href="/"> Leaderboard </Link>
          <button className="px-4 py-2 bg-yellow-500 text-black rounded-lg hover:bg-yellow-400">
            Coming Soon
          </button>
        </div>
      </div>
    </header>
  );
};

export default Header;
