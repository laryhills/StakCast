import React from "react";

const RecentActivity = () => {
  return (
    <div className="mt-8">
      <h2 className="text-xl font-semibold">Recent Activity</h2>
      <div className="bg-gray-50 p-4 rounded-lg shadow-inner">
        <ul>
          <li className="text-gray-700 py-2 border-b">
            User123 bought &quot;Yes&quot; at 65%
          </li>
          <li className="text-gray-700 py-2 border-b">
            User456 sold &quot;No&quot; at 35%
          </li>
          <li className="text-gray-700 py-2">
            User789 bought &quot;Yes&quot; at 60%
          </li>
        </ul>
      </div>
    </div>
  );
};

export default RecentActivity;
