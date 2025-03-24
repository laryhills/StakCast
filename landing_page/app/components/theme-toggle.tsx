// "use client";

// import * as React from "react";
// import { Moon, Sun } from "lucide-react";
// import { useTheme } from "next-themes";

// import { Button } from "./ui/button";
// import {
//   DropdownMenu,
//   DropdownMenuContent,
//   DropdownMenuItem,
//   DropdownMenuTrigger,
// } from "./ui/dropdown-menu";

// export function ThemeToggle() {
//   const { setTheme, theme, resolvedTheme } = useTheme();
//   const [mounted, setMounted] = React.useState(false);

//   // Ensure component is mounted to avoid hydration mismatch
//   React.useEffect(() => {
//     setMounted(true);
//   }, []);

//   if (!mounted) {
//     return (
//       <Button variant="ghost" size="icon" className="opacity-0">
//         <Sun className="h-[1.2rem] w-[1.2rem]" />
//       </Button>
//     );
//   }

//   const isDark = resolvedTheme === "dark";

//   return (
//     <DropdownMenu>
//       <DropdownMenuTrigger asChild>
//         <Button
//           variant="ghost"
//           size="icon"
//           className="transition-transform duration-300 hover:scale-110"
//         >
//           {isDark ? (
//             <Moon className="h-[1.2rem] w-[1.2rem] transition-all" />
//           ) : (
//             <Sun className="h-[1.2rem] w-[1.2rem] transition-all" />
//           )}
//           <span className="sr-only">Toggle theme</span>
//         </Button>
//       </DropdownMenuTrigger>
//       <DropdownMenuContent align="end" className="animate-fade-in-up">
//         <DropdownMenuItem
//           onClick={() => setTheme("light")}
//           className="cursor-pointer"
//         >
//           Light
//         </DropdownMenuItem>
//         <DropdownMenuItem
//           onClick={() => setTheme("dark")}
//           className="cursor-pointer"
//         >
//           Dark
//         </DropdownMenuItem>
//         <DropdownMenuItem
//           onClick={() => setTheme("system")}
//           className="cursor-pointer"
//         >
//           System
//         </DropdownMenuItem>
//       </DropdownMenuContent>
//     </DropdownMenu>
//   );
// }

import { useState, useEffect } from "react";
import { useTheme } from "../contexts/ThemeContext";
import { Sun, Moon } from "lucide-react";

export default function ThemeToggle() {
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;

  return (
    <button
      onClick={() => setTheme(theme === "light" ? "dark" : "light")}
      className="flex items-center justify-center w-10 h-10 rounded-full border border-gray-300 dark:border-gray-700 bg-transparent focus:outline-none focus:ring-2 focus:ring-primary-light dark:focus:ring-primary-dark"
      aria-label="Toggle theme"
    >
      {theme === "light" ? <Sun size={20} className="text-gray-700" /> : <Moon size={20} className="text-gray-300" />}
    </button>
  );
}
