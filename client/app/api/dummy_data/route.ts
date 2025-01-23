import { DummyMarketType } from "../../types";

const dummyMarkets: DummyMarketType[] = [
  {
    id: 1001,
    name: "Will Bitcoin surpass $50,000 by March 2025?",
    image: "/vercel.svg",
    options: [
      { name: "Yes", odds: 65 },
      { name: "No", odds: 35 },
    ],
    totalRevenue: "$1,234,567",
    categories: ["Crypto"],
    status: "active",
    startTime: 1704067200000, // Example: Jan 1, 2024
    endTime: 1735689600000, // Example: Jan 1, 2025
    createdBy: "0x123456789abcdef123456789abcdef1234567890",
  },
  {
    id: 1002,
    name: "Will Ethereum reach $3,000 by June 2025?",
    image: "/file.svg",
    options: [
      { name: "Yes", odds: 75 },
      { name: "No", odds: 25 },
      { name: "Maybe", odds: 5 },
    ],
    totalRevenue: "$987,654",
    categories: ["Crypto"],
    status: "inactive",
    startTime: 1706659200000, // Example: Feb 1, 2024
    endTime: 1738281600000, // Example: Feb 1, 2025
    createdBy: "0xabcdef123456789abcdef123456789abcdef1234",
  },
  {
    id: 1016,
    name: "Will Terra Luna Classic return to $1 by May 2025?",
    image: "https://via.placeholder.com/400x200",
    options: [
      { name: "Yes", odds: 10 },
      { name: "No", odds: 90 },
    ],
    totalRevenue: "$987,654",
    categories: ["Crypto"],
    status: "active",
    startTime: 1711929600000, // Example: Mar 1, 2024
    endTime: 1743552000000, // Example: Mar 1, 2025
    createdBy: "0x789abcdef123456789abcdef123456789abcdef12",
  },
  {
    id: 1017,
    name: "Will the incumbent win the 2024 US Presidential Election?",
    image: "/politics.svg",
    options: [
      { name: "Yes", odds: 55 },
      { name: "No", odds: 45 },
    ],
    totalRevenue: "$3,456,789",
    categories: ["Politics"],
    status: "active",
    startTime: 1706707200000, // Example: Feb 2, 2024
    endTime: 1738329600000, // Example: Feb 2, 2025
    createdBy: "0x1abcdef123456789abcdef123456789abcdef123",
  },
  {
    id: 1018,
    name: "Will a new stimulus package be passed by June 2024?",
    image: "/stimulus.svg",
    options: [
      { name: "Yes", odds: 60 },
      { name: "No", odds: 40 },
    ],
    totalRevenue: "$2,100,000",
    categories: ["Politics"],
    status: "inactive",
    startTime: 1707225600000, // Example: Mar 7, 2024
    endTime: 1738857600000, // Example: Mar 7, 2025
    createdBy: "0x2abcdef123456789abcdef123456789abcdef124",
  },
  {
    id: 1019,
    name: "Will Team X win the 2025 Super Bowl?",
    image: "/sports.svg",
    options: [
      { name: "Yes", odds: 40 },
      { name: "No", odds: 60 },
    ],
    totalRevenue: "$1,500,000",
    categories: ["Sports"],
    status: "active",
    startTime: 1709836800000, // Example: Apr 7, 2024
    endTime: 1741459200000, // Example: Apr 7, 2025
    createdBy: "0x3abcdef123456789abcdef123456789abcdef125",
  },
  {
    id: 1020,
    name: "Will Player Y win the 2024 Ballon d'Or?",
    image: "/ballon.svg",
    options: [
      { name: "Yes", odds: 70 },
      { name: "No", odds: 30 },
    ],
    totalRevenue: "$2,000,000",
    categories: ["Sports"],
    status: "active",
    startTime: 1712448000000, // Example: May 7, 2024
    endTime: 1744070400000, // Example: May 7, 2025
    createdBy: "0x4abcdef123456789abcdef123456789abcdef126",
  },
  {
    id: 1021,
    name: "Will Company Z's stock price double by the end of 2024?",
    image: "/business.svg",
    options: [
      { name: "Yes", odds: 45 },
      { name: "No", odds: 55 },
    ],
    totalRevenue: "$1,800,000",
    categories: ["Business"],
    status: "active",
    startTime: 1715068800000, // Example: Jun 7, 2024
    endTime: 1746691200000, // Example: Jun 7, 2025
    createdBy: "0x5abcdef123456789abcdef123456789abcdef127",
  },
  {
    id: 1022,
    name: "Will there be a major merger between two tech giants in 2024?",
    image: "/merger.svg",
    options: [
      { name: "Yes", odds: 50 },
      { name: "No", odds: 50 },
    ],
    totalRevenue: "$1,250,000",
    categories: ["Business"],
    status: "inactive",
    startTime: 1717689600000, // Example: Jul 7, 2024
    endTime: 1749312000000, // Example: Jul 7, 2025
    createdBy: "0x6abcdef123456789abcdef123456789abcdef128",
  },
];

export  function GET() {
 
    return Response.json(dummyMarkets);

}
