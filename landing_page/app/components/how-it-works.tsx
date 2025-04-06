export function HowItWorks() {
  const steps = [
    {
      number: "01",
      title: "Create Your Account",
      description:
        "Sign up for StakCast in seconds.  and verify your identity to get started.",
      align: "right",
    },
    {
      number: "02",
      title: "Deposit STRK Tokens",
      description:
        "Fund your account with STRK tokens to start participating in prediction markets.",
      align: "left",
    },
    {
      number: "03",
      title: "Browse Prediction Markets",
      description:
        "Explore a wide range of markets across different categories and timeframes.",
      align: "right",
    },
    {
      number: "04",
      title: "Make Your Predictions",
      description:
        "Stake your tokens on outcomes you believe will happen. The more confident you are, the more you can stake.",
      align: "left",
    },
    {
      number: "05",
      title: "Collect Your Rewards",
      description:
        "When your predictions are correct, collect your rewards automatically deposited to your account.",
      align: "right",
    },
  ];

  return (
    <section id="how-it-works" className="container mx-auto px-4 py-20">
      <div className="mb-16 text-center animate-on-scroll">
        <h2 className="mb-4 text-3xl font-bold md:text-4xl">
          How StakCast Works
        </h2>
        <p className="mx-auto max-w-2xl text-slate-600 dark:text-slate-300">
          A simple process to start predicting and earning rewards
        </p>
      </div>

      <div className="relative mx-auto max-w-4xl">
        {/* Connection line */}
        <div className="absolute left-1/2 top-0 h-full w-0.5 -translate-x-1/2 bg-gradient-to-b from-emerald-500/30 via-blue-500/30 to-purple-500/30 md:block hidden dark:from-emerald-500/50 dark:via-blue-500/50 dark:to-purple-500/50"></div>

        <div className="space-y-12 md:space-y-24">
          {steps.map((step, i) => (
            <div
              key={i}
              className={`relative flex flex-col ${
                step.align === "left" ? "md:flex-row" : "md:flex-row-reverse"
              } items-center gap-8 animate-on-scroll`}
              style={{ animationDelay: `${i * 150}ms` }}
            >
              <div className="md:w-1/2">
                <div className="relative rounded-2xl border bg-white dark:bg-slate-900 p-6 transition-all duration-300 hover:shadow-lg">
                  <div className="absolute -right-3 -top-3 flex h-10 w-10 items-center justify-center rounded-full bg-gradient-to-r from-emerald-500 to-blue-500 text-sm font-bold text-white dark:text-white transition-transform duration-300 hover:scale-110">
                    {step.number}
                  </div>
                  <h3 className="mb-2 text-xl font-semibold">{step.title}</h3>
                  <p className="text-slate-600 dark:text-slate-300">
                    {step.description}
                  </p>
                </div>
              </div>

              <div className="hidden h-4 w-4 rounded-full bg-gradient-to-r from-emerald-500 to-blue-500 md:block animate-pulse-slow"></div>

              <div className="md:w-1/2"></div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
