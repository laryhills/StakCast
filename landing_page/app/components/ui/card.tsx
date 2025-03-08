import { cn } from "@/app/lib/utils";
import type React from "react";

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: "default" | "outline" | "gradient";
  hover?: boolean;
}

export function Card({
  className,
  variant = "default",
  hover = false,
  ...props
}: CardProps) {
  const variantStyles = {
    default: "bg-white dark:bg-slate-900",
    outline:
      "border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900",
    gradient:
      "bg-gradient-to-r from-emerald-500/5 to-blue-500/5 dark:from-emerald-500/10 dark:to-blue-500/10",
  };

  const hoverStyles = hover
    ? "transition-all duration-300 hover:shadow-lg hover:-translate-y-1"
    : "";

  return (
    <div
      className={cn(
        "rounded-2xl",
        variantStyles[variant],
        hoverStyles,
        className
      )}
      {...props}
    />
  );
}

type CardHeaderProps = React.HTMLAttributes<HTMLDivElement>;

export function CardHeader({ className, ...props }: CardHeaderProps) {
  return <div className={cn("px-6 pt-6", className)} {...props} />;
}

type CardTitleProps = React.HTMLAttributes<HTMLHeadingElement>;

export function CardTitle({ className, ...props }: CardTitleProps) {
  return <h3 className={cn("text-xl font-semibold", className)} {...props} />;
}

type CardDescriptionProps = React.HTMLAttributes<HTMLParagraphElement>;

export function CardDescription({ className, ...props }: CardDescriptionProps) {
  return (
    <p
      className={cn("text-sm text-slate-500 dark:text-slate-400", className)}
      {...props}
    />
  );
}

type CardContentProps = React.HTMLAttributes<HTMLDivElement>;

export function CardContent({ className, ...props }: CardContentProps) {
  return <div className={cn("px-6 py-4", className)} {...props} />;
}

type CardFooterProps = React.HTMLAttributes<HTMLDivElement>;

export function CardFooter({ className, ...props }: CardFooterProps) {
  return <div className={cn("px-6 pb-6 pt-2", className)} {...props} />;
}
