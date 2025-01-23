import { BaseProps } from "@/app/types";
type StatBadgeProps = BaseProps & {
  value: string | number;
  label: string;
};

export const StatBadge: React.FC<StatBadgeProps> = ({ value, label }) => (
  <div className="flex flex-col items-center bg-white/10 backdrop-blur-md rounded-lg p-3 transition-transform hover:scale-105">
    <span className="text-2xl font-light">{value}</span>
    <span className="text-xs text-gray-400 mt-1">{label}</span>
  </div>
);
