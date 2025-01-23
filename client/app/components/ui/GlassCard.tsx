import { BaseProps } from "@/app/types";

type GlassCardProps = BaseProps & {
  children: React.ReactNode;
};

export const GlassCard: React.FC<GlassCardProps> = ({
  children,
  className = "",
}) => (
  <div
    className={`backdrop-blur-sm bg-white/30 rounded-2xl p-6 shadow-lg border border-white/20 transition-all duration-300 hover:shadow-xl ${className}`}
  >
    {children}
  </div>
);
