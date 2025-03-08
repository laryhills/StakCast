import { cn } from "@/app/lib/utils";
import type React from "react";


interface BadgeProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?:
    | "default"
    | "outline"
    | "success"
    | "warning"
    | "danger"
    | "info"
    | "custom";
  size?: "sm" | "md" | "lg";
  icon?: React.ReactNode;
}

export function Badge({
  className,
  variant = "default",
  size = "md",
  icon,
  children,
  ...props
}: BadgeProps) {
  // Variant styles
  const variantStyles = {
    default:
      "bg-slate-100 text-slate-800 dark:bg-slate-700 dark:text-slate-200",
    outline:
      "border border-slate-200 text-slate-800 dark:border-slate-700 dark:text-slate-200",
    success:
      "bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400",
    warning:
      "bg-amber-50 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400",
    danger: "bg-red-50 text-red-700 dark:bg-red-900/30 dark:text-red-400",
    info: "bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400",
    custom: "", // For custom styling via className
  };

  // Size styles
  const sizeStyles = {
    sm: "text-xs px-2 py-0.5",
    md: "text-sm px-2.5 py-0.5",
    lg: "text-base px-3 py-1",
  };

  return (
    <div
      className={cn(
        "inline-flex items-center rounded-full font-medium transition-colors",
        variantStyles[variant],
        sizeStyles[size],
        className
      )}
      {...props}
    >
      {icon && <span className="mr-1">{icon}</span>}
      {children}
    </div>
  );
}
