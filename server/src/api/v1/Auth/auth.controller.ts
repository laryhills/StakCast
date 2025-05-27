import { Request, Response } from "express";
import { injectable } from "tsyringe";
import AuthService from "./auth.service";

@injectable()
export default class AuthController {
	constructor(private authService: AuthService) {}

	async register(req: Request, res: Response) {
		try {
			const { email, password, firstName, lastName } = req.body;
			const result = await this.authService.register(email, password, firstName, lastName);
			res.status(201).json(result);
		} catch (error) {
			res.status(400).json({ error: (error as Error).message });
		}
	}

	async login(req: Request, res: Response) {
		try {
			const { email, password } = req.body;
			const result = await this.authService.login(email, password);
			res.json(result);
		} catch (error) {
			res.status(401).json({ error: (error as Error).message });
		}
	}

	async logout(req: Request, res: Response) {
		try {
			const userId = req.user?.id;
			if (!userId) {
				return res.status(401).json({ error: "Unauthorized" });
			}
			await this.authService.logout(userId);
			res.json({ message: "Logged out successfully" });
		} catch (error) {
			res.status(400).json({ error: (error as Error).message });
		}
	}

	async refreshToken(req: Request, res: Response) {
		try {
			const { refreshToken } = req.body;
			if (!refreshToken) {
				return res.status(400).json({ error: "Refresh token is required" });
			}
			const result = await this.authService.refreshToken(refreshToken);
			res.json(result);
		} catch (error) {
			res.status(401).json({ error: (error as Error).message });
		}
	}
}
