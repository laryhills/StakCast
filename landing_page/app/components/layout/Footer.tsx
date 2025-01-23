import React from "react";
import Link from "next/link";

const Footer = () => {
  return (
    <footer className="bg-green-900 text-white py-16">
      <div className="container mx-auto px-4">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          <div>
            <h3 className="text-xl font-bold mb-4">StakCast</h3>
            <p className="text-purple-200">
              The leading decentralized prediction platform for the future of events.
            </p>
          </div>
          <div>
            <h4 className="font-semibold mb-4">Quick Links</h4>
            <ul className="space-y-2">
              <li><Link href="/markets" className="text-purple-200 hover:text-white">Markets</Link></li>
              <li><Link href="/how-it-works" className="text-purple-200 hover:text-white">How It Works</Link></li>
              <li><Link href="/leaderboard" className="text-purple-200 hover:text-white">Leaderboard</Link></li>
            </ul>
          </div>
          <div>
            <h4 className="font-semibold mb-4">Resources</h4>
            <ul className="space-y-2">
              <li><Link href="/docs" className="text-purple-200 hover:text-white">Documentation</Link></li>
              <li><Link href="/faq" className="text-purple-200 hover:text-white">FAQ</Link></li>
              <li><Link href="/blog" className="text-purple-200 hover:text-white">Blog</Link></li>
            </ul>
          </div>
          <div>
            <h4 className="font-semibold mb-4">Connect</h4>
            <ul className="space-y-2">
              <li><a href="https://twitter.com" className="text-purple-200 hover:text-white">Twitter</a></li>
              <li><a href="https://discord.com" className="text-purple-200 hover:text-white">Discord</a></li>
              <li><a href="https://telegram.org" className="text-purple-200 hover:text-white">Telegram</a></li>
            </ul>
          </div>
        </div>
        <div className="mt-12 pt-8 border-t border-white text-center text-purple-200">
          <p>&copy; {new Date().getFullYear()} StakCast. All rights reserved.</p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;