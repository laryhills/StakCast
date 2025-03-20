# Getting Started with Stakcast

Welcome to Stakcast! This guide will walk you through setting up the project on your local machine.

---

## 📌 Prerequisites
Ensure you have the following installed:
- [Node.js](https://nodejs.org/) 
- [Git](https://git-scm.com/)
- A code editor (e.g., [VS Code](https://code.visualstudio.com/))
- [Scarb](https://github.com/software-mansion/scarb) (Cairo package manager)


---

## 🔥 Step 1: Clone the Repository
1. **Fork the Repository**  
   Click the "Fork" button at the top right of the repository page.

2. **Clone Your Fork**  
   ```bash
   git clone https://github.com/gear5labs/StakCast.git
   cd stakcast
   ```

---

## 📦 Step 2: Install Dependencies
Run the following command to install all required dependencies:
```bash
pnpm install
```

---

## 🌍 Step 3: Set Up Environment Variables if exists
Create a `.env` file in the root directory and add the necessary environment variables if env.example exists.  
Refer to `.env.example` for guidance if exists.

Example:
```env
NEXT_PUBLIC_API_URL=http://localhost:3000/api
```

---

## 🚀 Step 4: Start the Development Server
Run the following command:
```bash
pnpm dev:landing #for landing page
pnpm dev:client #for client application
```
Then, open `http://localhost:3000` in your browser.

---

## 🔗 Step 5: Setting Up Cairo Smart Contracts
1. **Install Scarb**  
   ```bash
   curl -L https://raw.githubusercontent.com/software-mansion/scarb/master/install.sh | bash
   ```
   Verify installation:
   ```bash
   scarb --version
   ```

2. **Navigate to the Contracts Directory**  
   ```bash
   cd contracts
   ```

3. **Build the Contracts**  
   ```bash
   scarb build
   ```

4. **Run Tests Using snforge**  
   ```bash
   snforge test
   ```


## ✅ Step 7: Running Tests (Optional)
To ensure your setup is working correctly, run:
```bash
pnpm test
```

To test smart contracts, use:
```bash
snforge test
```

---

## 💡 Step 8: Making Changes
1. **Create a New Branch**  
   ```bash
   git checkout -b feature-branch-name
   ```

2. **Make Your Changes**  
   Write your code, add tests if necessary, and update documentation.

3. **Commit Your Changes**  
   ```bash
   git add .
   git commit -m "Describe your changes"
   ```

---

## 🔀 Step 9: Push & Submit a Pull Request
1. **Push Your Changes**  
   ```bash
   git push origin feature-branch-name
   ```

2. **Create a Pull Request**  
   - Go to [Pull Requests](https://github.com/gear5labs/StakCast.git/pulls).
   - Click "New Pull Request."
   - Provide a clear title and description.

---

## ❓ Need Help?
If you have any issues, feel free to  reach out to the maintainers.

Happy coding! 🚀✨

